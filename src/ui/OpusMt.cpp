// SPDX-License-Identifier: GPL-3.0-only
// VI Translator's offline translator (OPUS-MT via ONNX Runtime): see OpusMt.h.
#include "OpusMt.h"
#include "veyra/Log.h"
#include "veyra/ui/UnigramTokenizer.h"

#include <QCoreApplication>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaObject>
#include <QThread>
#include <algorithm>
#include <format>
#include <limits>
#include <memory>
#include <optional>
#include <string>
#include <vector>
#include <windows.h>

#if VEYRA_HAS_ONNXRUNTIME
#include <onnxruntime_c_api.h>
#endif

namespace veyra::ui {
namespace {
#if VEYRA_HAS_ONNXRUNTIME
QString modelFolder() { return QDir(OpusMtService::folder()).filePath(QStringLiteral("opus-mt-en-ar")); }
const char* const modelFiles[]{"onnx/encoder_model_quantized.onnx", "onnx/decoder_model_quantized.onnx", "tokenizer.json", "config.json"};

// One loaded model. Lives on the worker thread only.
class OpusMtModel {
public:
    ~OpusMtModel() {
        if (!api_) return;
        if (enc_) api_->ReleaseSession(enc_);
        if (dec_) api_->ReleaseSession(dec_);
        if (options_) api_->ReleaseSessionOptions(options_);
        if (memory_) api_->ReleaseMemoryInfo(memory_);
        // The environment and the DLL stay for the process: ONNX Runtime allows one environment,
        // and unloading the DLL under its thread pool is not safe.
    }

    bool load(QString* error) {
        const QString dll = QDir(OpusMtService::folder()).filePath(QStringLiteral("onnxruntime.dll"));
        static HMODULE module = nullptr;
        if (!module) module = LoadLibraryExW(reinterpret_cast<LPCWSTR>(QDir::toNativeSeparators(dll).utf16()), nullptr,
                                             LOAD_WITH_ALTERED_SEARCH_PATH);
        if (!module) { *error = QStringLiteral("onnxruntime.dll could not be loaded (%1)").arg(GetLastError()); return false; }
        using GetApiBase = const OrtApiBase*(ORT_API_CALL*)();
        const auto base = reinterpret_cast<GetApiBase>(reinterpret_cast<void*>(GetProcAddress(module, "OrtGetApiBase")));
        if (!base) { *error = QStringLiteral("onnxruntime.dll has no OrtGetApiBase"); return false; }
        api_ = base()->GetApi(ORT_API_VERSION);
        if (!api_) { *error = QStringLiteral("onnxruntime %1 is older than this build needs").arg(QString::fromLatin1(base()->GetVersionString())); return false; }
        static OrtEnv* env = nullptr;
        if (!env && !ok(api_->CreateEnv(ORT_LOGGING_LEVEL_ERROR, "veyra-opus-mt", &env), error)) return false;
        if (!ok(api_->CreateSessionOptions(&options_), error)) return false;
        // Two threads, and none spinning while idle: the capture and the game come first.
        const int threads = std::clamp(QThread::idealThreadCount() / 4, 1, 2);
        if (!ok(api_->SetIntraOpNumThreads(options_, threads), error)
            || !ok(api_->SetInterOpNumThreads(options_, 1), error)
            || !ok(api_->SetSessionGraphOptimizationLevel(options_, ORT_ENABLE_ALL), error)
            || !ok(api_->AddSessionConfigEntry(options_, "session.intra_op.allow_spinning", "0"), error)
            || !ok(api_->AddSessionConfigEntry(options_, "session.inter_op.allow_spinning", "0"), error))
            return false;
        const QDir dir(modelFolder());
        auto session = [&](const char* file, OrtSession** out) {
            const QString path = QDir::toNativeSeparators(dir.filePath(QString::fromLatin1(file)));
            return ok(api_->CreateSession(env, reinterpret_cast<const ORTCHAR_T*>(path.utf16()), options_, out), error);
        };
        if (!session(modelFiles[0], &enc_) || !session(modelFiles[1], &dec_)) return false;
        if (!ok(api_->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_), error)) return false;
        if (!inputs(enc_, encInputs_, error) || !inputs(dec_, decInputs_, error)) return false;
        for (const auto& name : encInputs_)
            if (name != "input_ids" && name != "attention_mask") { *error = QStringLiteral("encoder input %1").arg(QString::fromStdString(name)); return false; }
        for (const auto& name : decInputs_)
            if (name != "input_ids" && name != "encoder_hidden_states" && name != "encoder_attention_mask") {
                *error = QStringLiteral("decoder input %1").arg(QString::fromStdString(name));
                return false;
            }
        return loadTokenizer(dir, threads, error);
    }

    QString translate(const QString& text, QString* error) {
        std::vector<int64_t> ids;
        if (prefix_) ids.push_back(*prefix_);
        auto encoded = tokenizer_.encode(text.toStdU32String());
        // Very long input (a menu's page): cut, keeping </s> at the end.
        if (encoded.size() > 250) { encoded.resize(249); encoded.push_back(eos_); }
        ids.insert(ids.end(), encoded.begin(), encoded.end());
        const int64_t n = int64_t(ids.size());
        std::vector<int64_t> mask(size_t(n), 1);
        const int64_t shape[2]{1, n};
        Values values(api_);
        OrtValue* idsValue = values.tensor(memory_, ids.data(), shape, error);
        OrtValue* maskValue = values.tensor(memory_, mask.data(), shape, error);
        if (!idsValue || !maskValue) return {};
        std::vector<const char*> names;
        std::vector<const OrtValue*> in;
        for (const auto& name : encInputs_) {
            names.push_back(name.c_str());
            in.push_back(name == "input_ids" ? idsValue : maskValue);
        }
        const char* hiddenName = "last_hidden_state";
        OrtValue* hidden = nullptr;
        if (!ok(api_->Run(enc_, nullptr, names.data(), in.data(), in.size(), &hiddenName, 1, &hidden), error)) return {};
        values.own(hidden);

        // Greedy decoding (no KV cache; subtitle lines are short), <pad> never chosen.
        std::vector<int64_t> out{pad_};
        const int64_t steps = std::min<int64_t>(std::max<int64_t>(n * 3, 32), 200);
        for (int64_t step = 0; step < steps; ++step) {
            const int64_t m = int64_t(out.size());
            const int64_t outShape[2]{1, m};
            Values stepValues(api_);
            OrtValue* outIds = stepValues.tensor(memory_, out.data(), outShape, error);
            if (!outIds) return {};
            names.clear();
            in.clear();
            for (const auto& name : decInputs_) {
                names.push_back(name.c_str());
                in.push_back(name == "input_ids" ? outIds : name == "encoder_hidden_states" ? hidden : maskValue);
            }
            const char* logitsName = "logits";
            OrtValue* logits = nullptr;
            if (!ok(api_->Run(dec_, nullptr, names.data(), in.data(), in.size(), &logitsName, 1, &logits), error)) return {};
            stepValues.own(logits);
            OrtTensorTypeAndShapeInfo* info = nullptr;
            if (!ok(api_->GetTensorTypeAndShape(logits, &info), error)) return {};
            size_t dims = 0;
            int64_t d[3]{};
            const bool shaped = ok(api_->GetDimensionsCount(info, &dims), error) && dims == 3
                && ok(api_->GetDimensions(info, d, 3), error);
            api_->ReleaseTensorTypeAndShapeInfo(info);
            if (!shaped) { if (error->isEmpty()) *error = QStringLiteral("unexpected logits shape"); return {}; }
            float* data = nullptr;
            if (!ok(api_->GetTensorMutableData(logits, reinterpret_cast<void**>(&data)), error)) return {};
            const int64_t vocab = d[2];
            const float* last = data + (d[1] - 1) * vocab;
            int64_t best = -1;
            float bestScore = -std::numeric_limits<float>::infinity();
            for (int64_t i = 0; i < vocab; ++i)
                if (i != pad_ && last[i] > bestScore) { bestScore = last[i]; best = i; }
            if (best < 0 || best == eos_) break;
            out.push_back(best);
        }
        out.erase(out.begin());
        return QString::fromStdU32String(tokenizer_.decode(out)).trimmed();
    }

private:
    // OrtValues released together.
    struct Values {
        explicit Values(const OrtApi* api) : api(api) {}
        ~Values() { for (auto* v : owned) api->ReleaseValue(v); }
        OrtValue* tensor(OrtMemoryInfo* memory, int64_t* data, const int64_t* shape, QString* error) {
            OrtValue* value = nullptr;
            OrtStatus* status = api->CreateTensorWithDataAsOrtValue(memory, data, size_t(shape[0] * shape[1]) * sizeof(int64_t),
                                                                     shape, 2, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &value);
            if (status) {
                *error = QString::fromUtf8(api->GetErrorMessage(status));
                api->ReleaseStatus(status);
                return nullptr;
            }
            owned.push_back(value);
            return value;
        }
        void own(OrtValue* value) { if (value) owned.push_back(value); }
        const OrtApi* api;
        std::vector<OrtValue*> owned;
    };

    bool ok(OrtStatus* status, QString* error) {
        if (!status) return true;
        *error = QString::fromUtf8(api_->GetErrorMessage(status));
        api_->ReleaseStatus(status);
        return false;
    }

    bool inputs(OrtSession* session, std::vector<std::string>& names, QString* error) {
        OrtAllocator* allocator = nullptr;
        if (!ok(api_->GetAllocatorWithDefaultOptions(&allocator), error)) return false;
        size_t count = 0;
        if (!ok(api_->SessionGetInputCount(session, &count), error)) return false;
        for (size_t i = 0; i < count; ++i) {
            char* name = nullptr;
            if (!ok(api_->SessionGetInputName(session, i, allocator, &name), error)) return false;
            names.emplace_back(name);
            api_->AllocatorFree(allocator, name);
        }
        return true;
    }

    bool loadTokenizer(const QDir& dir, int threads, QString* error) {
        QFile file(dir.filePath(QStringLiteral("tokenizer.json")));
        if (!file.open(QIODevice::ReadOnly) || file.size() > 64 * 1024 * 1024) { *error = QStringLiteral("tokenizer.json unreadable"); return false; }
        const auto root = QJsonDocument::fromJson(file.readAll()).object();
        const auto model = root.value(QStringLiteral("model")).toObject();
        const QString type = model.value(QStringLiteral("type")).toString();
        if (type != QLatin1String("Unigram")) { *error = QStringLiteral("tokenizer model %1 (Unigram expected)").arg(type); return false; }
        const auto vocab = model.value(QStringLiteral("vocab")).toArray();
        std::vector<UnigramTokenizer::Piece> pieces;
        pieces.reserve(size_t(vocab.size()));
        for (const auto& entry : vocab) {
            const auto pair = entry.toArray();
            pieces.push_back({pair.at(0).toString().toStdU32String(), pair.at(1).toDouble()});
        }
        std::vector<int> special;
        for (const auto& token : root.value(QStringLiteral("added_tokens")).toArray()) {
            const auto t = token.toObject();
            if (t.value(QStringLiteral("special")).toBool()) special.push_back(t.value(QStringLiteral("id")).toInt(-1));
        }
        QFile configFile(dir.filePath(QStringLiteral("config.json")));
        if (!configFile.open(QIODevice::ReadOnly)) { *error = QStringLiteral("config.json unreadable"); return false; }
        const auto config = QJsonDocument::fromJson(configFile.readAll()).object();
        const auto start = config.value(QStringLiteral("decoder_start_token_id"));
        pad_ = start.isDouble() ? start.toInteger() : config.value(QStringLiteral("pad_token_id")).toInteger(-1);
        eos_ = config.value(QStringLiteral("eos_token_id")).toInteger(0);
        if (pad_ < 0) { *error = QStringLiteral("config.json: no start token"); return false; }
        const int unk = model.value(QStringLiteral("unk_id")).toInt(1);
        tokenizer_.load(std::move(pieces), unk, special, int(eos_));
        // Multi-target models need the target first (en -> ar: ">>ara<<"), by id so it is not split.
        prefix_ = tokenizer_.id(U">>ara<<");
        log::info("opus-mt", std::format("model loaded vocab={} unk={} pad={} eos={} prefix={} specials={} threads={} enc_inputs={} dec_inputs={}",
            tokenizer_.size(), unk, pad_, eos_, prefix_ ? *prefix_ : -1, special.size(), threads, encInputs_.size(), decInputs_.size()));
        return true;
    }

    const OrtApi* api_ = nullptr;
    OrtSessionOptions* options_ = nullptr;
    OrtSession* enc_ = nullptr;
    OrtSession* dec_ = nullptr;
    OrtMemoryInfo* memory_ = nullptr;
    std::vector<std::string> encInputs_, decInputs_;
    UnigramTokenizer tokenizer_;
    std::optional<int> prefix_;
    int64_t pad_ = -1, eos_ = 0;
};
#endif
} // namespace

OpusMtService::OpusMtService(QObject* parent) : QObject(parent), worker_([this] { run(); }) {}

OpusMtService::~OpusMtService() {
    {
        std::lock_guard lock(mutex_);
        stop_ = true;
        jobs_.clear();
    }
    wake_.notify_all();
    if (worker_.joinable()) worker_.join();
}

QString OpusMtService::folder() {
    const QString overridden = qEnvironmentVariable("VEYRA_OPUS_MT_DIR");
    if (!overridden.isEmpty()) return overridden;
    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("translation"));
}

bool OpusMtService::installed() {
#if VEYRA_HAS_ONNXRUNTIME
    if (!QFileInfo::exists(QDir(folder()).filePath(QStringLiteral("onnxruntime.dll")))) return false;
    const QDir dir(modelFolder());
    return std::all_of(std::begin(modelFiles), std::end(modelFiles),
                       [&](const char* f) { return QFileInfo(dir.filePath(QString::fromLatin1(f))).size() > 0; });
#else
    return false;
#endif
}

quint64 OpusMtService::translate(const QStringList& parts) {
    std::lock_guard lock(mutex_);
    jobs_.push_back({++next_, parts});
    wake_.notify_one();
    return next_;
}

void OpusMtService::cancel() {
    std::lock_guard lock(mutex_);
    droppedUpTo_ = next_;
    jobs_.clear();
}

void OpusMtService::run() {
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_BELOW_NORMAL);
#if VEYRA_HAS_ONNXRUNTIME
    std::unique_ptr<OpusMtModel> model;
    QString loadError;
    qint64 failedAt = -1;
    QElapsedTimer clock;
    clock.start();
#endif
    for (;;) {
        Job job;
        {
            std::unique_lock lock(mutex_);
            wake_.wait(lock, [this] { return stop_ || !jobs_.empty(); });
            if (stop_) return;
            job = std::move(jobs_.front());
            jobs_.pop_front();
        }
        QElapsedTimer took;
        took.start();
        QStringList out;
        QString error;
#if VEYRA_HAS_ONNXRUNTIME
        // A model that failed to load is tried again after a minute, not on every line.
        if (!model && (failedAt < 0 || clock.elapsed() - failedAt > 60000)) {
            QMetaObject::invokeMethod(this, [this] { emit loading(true); }, Qt::QueuedConnection);
            auto loaded = std::make_unique<OpusMtModel>();
            loadError.clear();
            if (loaded->load(&loadError)) model = std::move(loaded);
            else {
                failedAt = clock.elapsed();
                log::error("opus-mt", "load failed: " + loadError.toStdString());
            }
            QMetaObject::invokeMethod(this, [this] { emit loading(false); }, Qt::QueuedConnection);
        }
        if (!model) error = loadError.isEmpty() ? QStringLiteral("model not loaded") : loadError;
        for (const auto& part : job.parts) {
            if (!model || !error.isEmpty()) break;
            out << model->translate(part, &error);
        }
#else
        error = QStringLiteral("this build has no ONNX Runtime");
#endif
        const int ms = int(took.elapsed());
        if (job.id <= droppedUpTo_) continue;
        QMetaObject::invokeMethod(this, [this, id = job.id, out, error, ms] {
            if (id > droppedUpTo_) emit done(id, out, error, ms);
        }, Qt::QueuedConnection);
    }
}

} // namespace veyra::ui
