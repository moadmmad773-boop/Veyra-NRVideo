#pragma once
// SentencePiece-style Unigram tokenizer, as Hugging Face tokenizers runs the tokenizer.json
// of the OPUS-MT models VI Translator uses offline (Xenova/opus-mt-en-ar): words split on
// whitespace, each with a leading U+2581, cut into vocabulary pieces by the best total
// score (Viterbi); an unknown character is <unk> (consecutive ones fused); </s> appended.
// Decoding joins the pieces, U+2581 back to spaces, special tokens left out.
// Portable C++; reading tokenizer.json is the caller's (OpusMt.cpp).
#include <cstdint>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace veyra::ui {

class UnigramTokenizer {
public:
    struct Piece {
        std::u32string text;
        double score = 0;
    };
    // vocab: by id. special: ids left out of decoded text. eos: appended to every encoding.
    void load(std::vector<Piece> vocab, int unk, std::vector<int> special, int eos);
    bool loaded() const { return !vocab_.empty(); }
    std::vector<int64_t> encode(const std::u32string& text) const;
    std::u32string decode(const std::vector<int64_t>& ids) const;
    std::optional<int> id(const std::u32string& piece) const;
    size_t size() const { return vocab_.size(); }

private:
    void word(const std::u32string& w, std::vector<int64_t>& out) const;
    std::vector<Piece> vocab_;
    std::unordered_map<std::u32string, int> index_;
    std::vector<bool> special_;
    int unk_ = 0, eos_ = -1;
    double unkScore_ = -10;
    size_t maxLen_ = 1;
};

} // namespace veyra::ui
