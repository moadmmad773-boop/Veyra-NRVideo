// A game line taken apart and put back around its translation (ViLineText.h): VI Translator's
// own tests (speaker.rs, translate.rs), plus the whole plan/assemble round trip.
#include "veyra/ui/ViLineText.h"

#include <cstdio>
#include <string>

using namespace veyra::ui::viline;

namespace {
int failures = 0;
void check(bool passed, const char* name) {
    std::printf("%s %s\n", passed ? "PASS" : "FAIL", name);
    if (!passed) ++failures;
}

void cues() {
    auto c = takeCues(U"[rattling] Donnie: Hell nah, she's good We're good!");
    check(c && c->first.before == std::vector<std::u32string>{U"rattling"} && c->second == U"Donnie: Hell nah, she's good We're good!",
          "a cue in front");
    c = takeCues(U"Donnie: [sigh] Fuck.");
    check(c && c->first.afterName == std::vector<std::u32string>{U"sigh"} && c->second == U"Donnie: Fuck.", "a cue after the name");
    c = takeCues(U"Donnie: [laughs]");
    check(c && c->first.afterName == std::vector<std::u32string>{U"laughs"} && c->second == U"Donnie:", "a cue alone after the name");
    c = takeCues(U"We're good! [laughs]");
    check(c && c->first.after == std::vector<std::u32string>{U"laughs"} && c->second == U"We're good!", "a cue at the end");
    check(!takeCues(U"Hold [1] to aim"), "brackets without letters are not a cue");
    check(!takeCues(U"No cues here."), "no cues");
    check(cueIn(U"ar", U"Laughs") == std::u32string(U"يضحك") && !cueIn(U"hi", U"laughs"), "cues from the Arabic list");
}

void names() {
    auto n = splitName(U"Dobbs: Not to be annoying, can you fix my leg?");
    check(n && n->first == U"Dobbs:" && n->second == U"Not to be annoying, can you fix my leg?", "a name split off");
    n = splitName(U"Real Dimez: Yo, what's up?");
    check(n && n->first == U"Real Dimez:" && n->second == U"Yo, what's up?", "a two-word name");
    check(!splitName(U"Listen up: we go now.") && !splitName(U"Hey Jason, come: now"), "a colon later is not a name");
    check(nameIn(U"ar", U"Real Dimez") == U"ريال دايمز" && nameIn(U"ar", U"Officer Jason") == U"الضابط جيسون", "known names and titles");
    check(nameIn(U"ar", U"Cop") == U"الشرطي" && nameIn(U"ar", U"Prison Guard") == U"حارس السجن"
          && nameIn(U"ar", U"Officer Smith") == U"الضابط سميث", "roles are translated");
    check(isRole(U"Cop") && isRole(U"Officer Smith") && !isRole(U"Dobbs"), "roles");
    check(nameIn(U"ar", U"Dobbs") == U"دوبس" && nameIn(U"ar", U"Lucia") == U"لوسيا" && nameIn(U"hi", U"Dobbs") == U"Dobbs",
          "names in Arabic letters");
    check(transliterate(U"dennis") == U"دينيس" && transliterate(U"bobby") == U"بوبي" && transliterate(U"kyle") == U"كايل"
          && transliterate(U"kenton") == U"كينتون" && transliterate(U"shirley") == U"شيرلي" && transliterate(U"peggy") == U"بيغي",
          "letter by letter");
}

void tags() {
    auto t = languageTag(U"In Italian: Go, go, go.");
    check(t && t->first == U"Italian" && t->second == U"Go, go, go.", "a language tag");
    t = languageTag(U"In Spahiyh: One coffee, please.");
    check(t && t->first == U"Spanish", "a misread language matched");
    t = languageTag(U"In Haitian Creole: Let's go.");
    check(t && t->first == U"Haitian Creole", "a two-word language");
    check(languageIn(U"ar", U"Italian") == std::u32string(U"بالإيطالية:"), "the tag in Arabic");
    check(!languageTag(U"In time: we go") && !languageTag(U"In the end, it's fine."), "not a tag");
}

void terms() {
    auto [t, kept] = protectTerms(U"In addition to the monthly GTA$500,000 deposited, GTA+ Members who've signed up get GTA Online cars. Visit rsg.ms/gtaplus for more.");
    check(t == U"In addition to the monthly [1] deposited, [2] Members who've signed up get [3] cars. Visit [4] for more.", "terms kept");
    check(kept == std::vector<std::u32string>{U"GTA$500,000", U"GTA+", U"GTA Online", U"rsg.ms/gtaplus"}, "the kept terms");
    check(protectTerms(U"Go to the guard.").second.empty(), "a line without terms");
    check(restoreTerms(U"ادفع [١] الآن", {U"GTA$5"}) == U"ادفع \u2066GTA$5\u2069 الآن", "a term put back (Arabic digits)");
    check(sentences(U"Pay attention to your surroundings. Investigating strange noises may lead to new opportunities. Tip: Hold e.g. 3.5 mi away.")
              == std::vector<std::u32string>{U"Pay attention to your surroundings.", U"Investigating strange noises may lead to new opportunities.",
                                             U"Tip: Hold e.g. 3.5 mi away."}, "a paragraph sentence by sentence");
    check(sentences(U"Take cover.") == std::vector<std::u32string>{U"Take cover."}, "one sentence");
    check(polite(U"ar", U"لكنه يقود كالعاهرة، لذا...") == U"لكنه يقود كالساقطة، لذا..." && polite(U"fr", U"عاهر") == U"عاهر", "harsh words softened");
    check(expandSlang(U"C'mon, man.") == U"Come on, man.", "slang spelt out");
}

void roundTrip() {
    auto p = plan(U"[rattling] Donnie: [sigh] C'mon, we go now. Move it!", U"ar", true);
    check(p.name == std::u32string(U"دوني") && p.parts == std::vector<std::u32string>{U"Come on, we go now.", U"Move it!"},
          "offline: name and cues out, sentence by sentence");
    check(assemble(p, {U"هيا، سنذهب الآن.", U"تحرك!"}) == U"[قعقعة] دوني: [يتنهّد] هيا، سنذهب الآن. تحرك!", "put back together");
    p = plan(U"Tip: Hold L2 to aim.", U"ar", false);
    check(!p.name && p.parts == std::vector<std::u32string>{U"Tip: Hold L2 to aim."}, "an instruction label is not a speaker");
    p = plan(U"Donnie: [laughs]", U"ar", false);
    check(p.parts.empty() && assemble(p, {}) == U"دوني: [يضحك]", "a cue-only line needs no translator");
    p = plan(U"In Spanish: One coffee, please.", U"ar", false);
    check(assemble(p, {U"قهوة واحدة من فضلك."}) == U"بالإسبانية: قهوة واحدة من فضلك.", "a language tag in front");
    p = plan(U"GTA+", U"ar", false);
    check(p.parts.empty() && assemble(p, {}) == U"\u2066GTA+\u2069", "only kept terms: nothing to translate");
    p = plan(U"We need to go. Now.", U"ar", false);
    check(p.parts.size() == 1, "network engines get the whole line");
    p = plan(U"Kyle: [mumbling softly] What?", U"ar", true);
    check(p.parts == std::vector<std::u32string>{U"What?", U"mumbling softly"}, "offline: an unknown cue is translated too");
    check(assemble(p, {U"ماذا؟", U"يتمتم بهدوء"}) == U"كايل: [يتمتم بهدوء] ماذا؟", "and put back");
}
}

int main() {
    cues();
    names();
    tags();
    terms();
    roundTrip();
    std::printf("%s (%d failed)\n", failures ? "FAILED" : "ALL PASSED", failures);
    return failures ? 1 : 0;
}
