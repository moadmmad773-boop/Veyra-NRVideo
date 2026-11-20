#pragma once
// VI Translator's free offline translator: OPUS-MT English -> Arabic (Helsinki-NLP, the
// ONNX export by Xenova at a fixed commit) run on the CPU with ONNX Runtime, greedy
// decoding without a KV cache (subtitle lines are short). Ported from VI Translator
// (src-tauri/src/translate.rs, LocalMt, v1.2.3), MIT License; see THIRD_PARTY_NOTICES.md.
//
// The runtime (onnxruntime.dll) and the model live in the program's "translation" folder
// (the M$M! package carries them); the DLL is loaded from there by full path, never by name
// (Windows 11 has its own onnxruntime.dll in System32). Everything runs on one worker
// thread; results come back as the done() signal.
#include <QObject>
#include <QStringList>
#include <atomic>
#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>

namespace veyra::ui {

class OpusMtService final : public QObject {
    Q_OBJECT
public:
    explicit OpusMtService(QObject* parent = nullptr);
    ~OpusMtService() override;
    // <program>/translation, or the folder in VEYRA_OPUS_MT_DIR (tests).
    static QString folder();
    // This build can run it and the runtime and model files are in folder().
    static bool installed();
    // Translates the parts one by one (a line's sentences, its unknown cues); done() once.
    quint64 translate(const QStringList& parts);
    // Jobs asked for so far are dropped (their done() never comes).
    void cancel();

signals:
    void done(quint64 job, const QStringList& translations, const QString& error, int ms);
    void loading(bool on);

private:
    struct Job {
        quint64 id = 0;
        QStringList parts;
    };
    void run();
    std::mutex mutex_;
    std::condition_variable wake_;
    std::deque<Job> jobs_;
    bool stop_ = false;
    quint64 next_ = 0;
    std::atomic<quint64> droppedUpTo_{0};
    std::thread worker_;
};

} // namespace veyra::ui
