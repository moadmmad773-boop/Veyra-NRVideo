// The Unigram tokenizer of the offline translator (UnigramTokenizer.h) on a small vocabulary.
#include "veyra/ui/UnigramTokenizer.h"

#include <cstdio>

using veyra::ui::UnigramTokenizer;

namespace {
int failures = 0;
void check(bool passed, const char* name) {
    std::printf("%s %s\n", passed ? "PASS" : "FAIL", name);
    if (!passed) ++failures;
}
}

int main() {
    UnigramTokenizer t;
    // 0 </s>, 1 <unk>, 2 <pad>, then pieces with scores
    t.load({{U"</s>", 0}, {U"<unk>", 0}, {U"<pad>", 0}, {U"▁the", -2}, {U"▁", -3}, {U"t", -5}, {U"h", -5},
            {U"e", -5}, {U"▁go", -3}, {U"ing", -3}, {U"▁going", -4}, {U"o", -5}, {U"g", -5}, {U"▁g", -4},
            {U"in", -4}, {U"n", -5}, {U"i", -5}, {U".", -2}, {U">>ara<<", 0}, {U"▁مرحبا", -3}},
           1, {0, 1, 2}, 0);
    check(t.encode(U"the") == std::vector<int64_t>{3, 0}, "a word as one piece, then </s>");
    check(t.encode(U"going") == std::vector<int64_t>{10, 0}, "the best-scoring cut (one piece beats go+ing)");
    check(t.encode(U"  the   going. ") == std::vector<int64_t>{3, 10, 17, 0}, "whitespace collapsed, punctuation its own piece");
    check(t.encode(U"thez") == std::vector<int64_t>{3, 1, 0}, "an unknown character is <unk>");
    check(t.encode(U"thezz") == std::vector<int64_t>{3, 1, 0}, "consecutive unknowns are fused");
    check(t.id(U">>ara<<") == 18, "a language token found by its text");
    check(t.decode({2, 19, 3, 10, 0}) == U"مرحبا the going", "decoded: specials left out, U+2581 to spaces");
    std::printf("%s (%d failed)\n", failures ? "FAILED" : "ALL PASSED", failures);
    return failures ? 1 : 0;
}
