// SPDX-License-Identifier: GPL-3.0-only
#include "veyra/ui/UnigramTokenizer.h"

#include <algorithm>
#include <limits>

namespace veyra::ui {
namespace {
constexpr char32_t metaspace = 0x2581;
bool space(char32_t c) { return c == U' ' || c == U'\t' || c == U'\n' || c == U'\r' || c == 0xA0 || c == 0x3000; }
}

void UnigramTokenizer::load(std::vector<Piece> vocab, int unk, std::vector<int> special, int eos) {
    vocab_ = std::move(vocab);
    index_.clear();
    index_.reserve(vocab_.size());
    maxLen_ = 1;
    double minScore = 0;
    for (size_t i = 0; i < vocab_.size(); ++i) {
        index_.emplace(vocab_[i].text, int(i));
        maxLen_ = std::max(maxLen_, vocab_[i].text.size());
        minScore = std::min(minScore, vocab_[i].score);
    }
    // Hugging Face: an unknown piece scores 10 below the lowest one in the vocabulary.
    unkScore_ = minScore - 10.0;
    unk_ = unk;
    eos_ = eos;
    special_.assign(vocab_.size(), false);
    for (int s : special) if (s >= 0 && size_t(s) < special_.size()) special_[size_t(s)] = true;
}

std::optional<int> UnigramTokenizer::id(const std::u32string& piece) const {
    const auto it = index_.find(piece);
    if (it == index_.end()) return std::nullopt;
    return it->second;
}

void UnigramTokenizer::word(const std::u32string& w, std::vector<int64_t>& out) const {
    const size_t n = w.size();
    constexpr double none = -std::numeric_limits<double>::infinity();
    std::vector<double> best(n + 1, none);
    std::vector<int> from(n + 1, -1), token(n + 1, -1);
    best[0] = 0;
    std::u32string piece;
    for (size_t i = 0; i < n; ++i) {
        if (best[i] == none) continue;
        bool single = false;
        for (size_t len = 1; len <= maxLen_ && i + len <= n; ++len) {
            piece.assign(w, i, len);
            const auto it = index_.find(piece);
            if (it == index_.end()) continue;
            if (len == 1) single = true;
            const double score = best[i] + vocab_[size_t(it->second)].score;
            if (score > best[i + len]) {
                best[i + len] = score;
                from[i + len] = int(i);
                token[i + len] = it->second;
            }
        }
        // A character no piece starts with: <unk> for it alone.
        if (!single) {
            const double score = best[i] + unkScore_;
            if (score > best[i + 1]) {
                best[i + 1] = score;
                from[i + 1] = int(i);
                token[i + 1] = unk_;
            }
        }
    }
    std::vector<int64_t> ids;
    for (size_t at = n; at > 0 && from[at] >= 0; at = size_t(from[at])) ids.push_back(token[at]);
    std::reverse(ids.begin(), ids.end());
    for (const auto id : ids) {
        if (id == unk_ && !out.empty() && out.back() == unk_) continue; // unknowns fused
        out.push_back(id);
    }
}

std::vector<int64_t> UnigramTokenizer::encode(const std::u32string& text) const {
    std::vector<int64_t> out;
    std::u32string w;
    auto flush = [&] {
        if (w.empty()) return;
        word(std::u32string(1, metaspace) + w, out);
        w.clear();
    };
    for (char32_t c : text) {
        if (space(c)) flush();
        else w += c;
    }
    flush();
    if (eos_ >= 0) out.push_back(eos_);
    return out;
}

std::u32string UnigramTokenizer::decode(const std::vector<int64_t>& ids) const {
    std::u32string out;
    for (const auto id : ids) {
        if (id < 0 || size_t(id) >= vocab_.size() || special_[size_t(id)]) continue;
        out += vocab_[size_t(id)].text;
    }
    for (auto& c : out) if (c == metaspace) c = U' ';
    size_t a = 0, b = out.size();
    while (a < b && out[a] == U' ') ++a;
    while (b > a && out[b - 1] == U' ') --b;
    return out.substr(a, b - a);
}

} // namespace veyra::ui
