#pragma once
// How one English game line is taken apart before it is translated and put back
// together after: VI Translator's line handling around its translators. Portable C++
// (no Qt, no Windows), so it is testable on its own.
//
// Ported from VI Translator (https://github.com/vi-translator/vi-translator-desktop,
// src-tauri/src/translate.rs, speaker.rs, ocr.rs and translate_spoken in main.rs, v1.2.3),
// MIT License, Copyright (c) 2026 Fouad Almalki. See THIRD_PARTY_NOTICES.md.
//  - sound cues in brackets ("[laughs]") are taken out, written from a word list (Arabic)
//    and put back where they were;
//  - a speaker name in front ("Dobbs: ...") is kept out of the translation and written in
//    Arabic letters (the game's known names, roles, else letter by letter);
//  - "In Spanish: ..." keeps its tag apart;
//  - terms that must stay as written (GTA+, GTA$ amounts, web addresses, TM names) go through
//    as [1], [2] and are put back;
//  - slang machine translators take for a name ("C'mon") is spelt out;
//  - the offline model gets a paragraph sentence by sentence;
//  - harsh words in the result are softened.
// Veyra difference: without the game's name colours, a capitalised "Name:" in front counts as
// a speaker unless it is a word games use for instructions ("Tip:", "Objective:" ...).
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace veyra::ui::viline {

struct Cues {
    std::vector<std::u32string> before, afterName, after;
    bool empty() const { return before.empty() && afterName.empty() && after.empty(); }
};

// The line without its cues and the cues by where they were; nothing when it has none.
std::optional<std::pair<Cues, std::u32string>> takeCues(const std::u32string& line);
// A cue as the target language writes it, from the built-in list (Arabic only).
std::optional<std::u32string> cueIn(const std::u32string& lang, const std::u32string& cue);

// "Dobbs:" -> "Dobbs"; how many words in front make a name; (name, rest of the line).
std::optional<std::u32string> speakerName(const std::u32string& word);
std::optional<std::pair<std::u32string, std::u32string>> splitName(const std::u32string& line);
bool isRole(const std::u32string& name);
std::u32string nameIn(const std::u32string& lang, const std::u32string& name);
std::u32string transliterate(const std::u32string& word);

// "In Spanish: ..." -> ("Spanish", "..."); the tag in Arabic when known.
std::optional<std::pair<std::u32string, std::u32string>> languageTag(const std::u32string& line);
std::optional<std::u32string> languageIn(const std::u32string& lang, const std::u32string& language);

std::pair<std::u32string, std::vector<std::u32string>> protectTerms(const std::u32string& line);
std::u32string restoreTerms(std::u32string text, const std::vector<std::u32string>& terms);
std::u32string expandSlang(std::u32string line);
std::vector<std::u32string> sentences(const std::u32string& text);
std::u32string polite(const std::u32string& lang, std::u32string text);

// A line taken apart. `parts` are what the translator gets, one by one (a paragraph's
// sentences for the offline model; the whole sentence otherwise; and any cue or tag the
// word lists do not know). assemble() puts the translations back together.
struct Plan {
    std::u32string lang;
    Cues cues;
    std::vector<std::optional<std::u32string>> cuesShown; // per cue (before, afterName, after); nullopt: translated
    std::optional<std::u32string> name;                   // as shown (target letters)
    std::optional<std::u32string> tag;                    // "In Spanish" as shown; nullopt with tagEnglish: translated
    std::u32string tagEnglish;
    std::vector<std::u32string> terms;
    std::u32string whole;          // nothing to translate: shown as it is (only kept terms)
    std::vector<std::u32string> parts;
    size_t sentenceParts = 0;      // the first parts are the sentence's; then unknown cues, then the tag
    bool onlyCuesAndName = false;
};
// offline: the offline model (sentence by sentence, unknown cues translated too).
Plan plan(const std::u32string& line, const std::u32string& lang, bool offline);
std::u32string assemble(const Plan& plan, const std::vector<std::u32string>& translated);

} // namespace veyra::ui::viline
