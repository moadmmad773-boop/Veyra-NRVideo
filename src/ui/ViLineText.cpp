// SPDX-License-Identifier: GPL-3.0-only
// Ported from VI Translator v1.2.3 (MIT): see ViLineText.h and THIRD_PARTY_NOTICES.md.
#include "veyra/ui/ViLineText.h"

#include <algorithm>
#include <cstddef>
#include <string>

namespace veyra::ui::viline {
namespace {
using S = std::u32string;

bool upperAscii(char32_t c) { return c >= U'A' && c <= U'Z'; }
bool asciiAlpha(char32_t c) { return (c >= U'a' && c <= U'z') || upperAscii(c); }
// Letters of the scripts game text and its translations use (Latin, Greek, Cyrillic,
// Arabic, CJK); enough for "is this a word" decisions.
bool alpha(char32_t c) {
    if (asciiAlpha(c)) return true;
    if (c < 0xC0) return c == 0xAA || c == 0xB5 || c == 0xBA;
    if (c == 0xD7 || c == 0xF7) return false;
    if (c <= 0x24F) return true;                                   // Latin-1, Latin Extended
    if (c >= 0x370 && c <= 0x52F) return c != 0x37E && c != 0x387; // Greek, Cyrillic
    if (c >= 0x620 && c <= 0x64A) return true;                     // Arabic letters
    if (c >= 0x66E && c <= 0x6D3) return true;
    if (c >= 0x3040 && c <= 0x30FF) return true;                   // kana
    if (c >= 0x4E00 && c <= 0x9FFF) return true;                   // CJK
    if (c >= 0xAC00 && c <= 0xD7A3) return true;                   // Hangul
    return false;
}
bool space(char32_t c) { return c == U' ' || c == U'\t' || c == U'\n' || c == U'\r' || c == 0xA0; }
char32_t lower(char32_t c) { return upperAscii(c) ? c + 32 : c; }
S lowerAll(S s) { for (auto& c : s) c = lower(c); return s; }
bool upperFirst(const S& s) { return !s.empty() && upperAscii(s.front()); }
S trim(const S& s) {
    size_t a = 0, b = s.size();
    while (a < b && space(s[a])) ++a;
    while (b > a && space(s[b - 1])) --b;
    return s.substr(a, b - a);
}
std::vector<S> words(const S& s) {
    std::vector<S> out;
    S cur;
    for (char32_t c : s) {
        if (space(c)) { if (!cur.empty()) out.push_back(std::move(cur)), cur.clear(); }
        else cur += c;
    }
    if (!cur.empty()) out.push_back(std::move(cur));
    return out;
}
S join(const std::vector<S>& parts, const S& by) {
    S out;
    for (size_t i = 0; i < parts.size(); ++i) { if (i) out += by; out += parts[i]; }
    return out;
}
size_t letters(const S& s) { return size_t(std::count_if(s.begin(), s.end(), alpha)); }
S replaceAll(S s, const S& from, const S& to) {
    if (from.empty()) return s;
    for (size_t at = 0; (at = s.find(from, at)) != S::npos; at += to.size()) s.replace(at, from.size(), to);
    return s;
}
bool contains(const S& s, const S& part) { return s.find(part) != S::npos; }
bool startsWith(const S& s, const S& p) { return s.size() >= p.size() && s.compare(0, p.size(), p) == 0; }
bool endsWith(const S& s, const S& p) { return s.size() >= p.size() && s.compare(s.size() - p.size(), p.size(), p) == 0; }
bool arabicScript(const S& lang) { return lang == U"ar" || lang == U"fa" || lang == U"ur"; }

// 0..1 likeness of two words (1 - edit distance / longer length), case-insensitive.
double closeness(const S& x, const S& y) {
    const S a = lowerAll(x), b = lowerAll(y);
    std::vector<size_t> prev(b.size() + 1), cur(b.size() + 1);
    for (size_t j = 0; j <= b.size(); ++j) prev[j] = j;
    for (size_t i = 1; i <= a.size(); ++i) {
        cur[0] = i;
        for (size_t j = 1; j <= b.size(); ++j)
            cur[j] = std::min({prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] != b[j - 1] ? 1 : 0)});
        std::swap(prev, cur);
    }
    return 1.0 - double(prev[b.size()]) / double(std::max<size_t>({a.size(), b.size(), 1}));
}

struct Pair { const char32_t* en; const char32_t* ar; };

// The game's people, as their names are usually written in Arabic (VI Translator: GTA).
constexpr Pair known[]{
    {U"lucia", U"لوسيا"}, {U"jason", U"جيسون"}, {U"cal", U"كال"}, {U"boobie", U"بوبي"},
    {U"dre'quan", U"دريكوان"}, {U"drequan", U"دريكوان"}, {U"brian", U"براين"}, {U"raul", U"راؤول"},
    {U"bae-luxe", U"بي-لوكس"}, {U"roxy", U"روكسي"}, {U"real dimez", U"ريال دايمز"}, {U"mike", U"مايك"},
    {U"michael", U"مايكل"}, {U"trevor", U"تريفور"}, {U"franklin", U"فرانكلين"}, {U"lamar", U"لامار"},
};

// Roles games put where a name goes ("Cop:"): translated, never spelt out in Arabic letters.
constexpr Pair roles[]{
    {U"cop", U"الشرطي"}, {U"cops", U"الشرطة"}, {U"police", U"الشرطة"}, {U"police officer", U"ضابط الشرطة"},
    {U"officer", U"الضابط"}, {U"deputy", U"نائب الشريف"}, {U"sheriff", U"الشريف"}, {U"trooper", U"شرطي الولاية"},
    {U"detective", U"المحقق"}, {U"sergeant", U"الرقيب"}, {U"captain", U"النقيب"}, {U"agent", U"العميل"},
    {U"soldier", U"الجندي"}, {U"guard", U"الحارس"}, {U"prison guard", U"حارس السجن"}, {U"security guard", U"حارس الأمن"},
    {U"security", U"الأمن"}, {U"bouncer", U"حارس الملهى"}, {U"dispatch", U"مركز البلاغات"}, {U"dispatcher", U"مركز البلاغات"},
    {U"operator", U"عامل الهاتف"}, {U"pilot", U"الطيار"}, {U"driver", U"السائق"}, {U"cashier", U"أمين الصندوق"},
    {U"clerk", U"الموظف"}, {U"teller", U"الصرّاف"}, {U"bank teller", U"صرّاف البنك"}, {U"bartender", U"النادل"},
    {U"waiter", U"النادل"}, {U"waitress", U"النادلة"}, {U"customer", U"الزبون"}, {U"shopkeeper", U"صاحب المتجر"},
    {U"owner", U"المالك"}, {U"manager", U"المدير"}, {U"boss", U"الزعيم"}, {U"worker", U"العامل"},
    {U"mechanic", U"الميكانيكي"}, {U"attendant", U"العامل"}, {U"salesman", U"البائع"}, {U"dealer", U"التاجر"},
    {U"doctor", U"الطبيب"}, {U"nurse", U"الممرضة"}, {U"paramedic", U"المسعف"}, {U"reporter", U"المراسل"},
    {U"news anchor", U"مذيع الأخبار"}, {U"anchor", U"المذيع"}, {U"announcer", U"المذيع"}, {U"host", U"المقدّم"},
    {U"radio host", U"مذيع الراديو"}, {U"dj", U"منسّق الأغاني"}, {U"caller", U"المتصل"}, {U"voice", U"الصوت"},
    {U"man", U"الرجل"}, {U"woman", U"المرأة"}, {U"guy", U"الرجل"}, {U"girl", U"الفتاة"}, {U"boy", U"الفتى"},
    {U"kid", U"الطفل"}, {U"old man", U"العجوز"}, {U"old woman", U"العجوز"}, {U"homeless man", U"المشرّد"},
    {U"pedestrian", U"أحد المارة"}, {U"passerby", U"أحد المارة"}, {U"local", U"أحد السكان"}, {U"neighbor", U"الجار"},
    {U"neighbour", U"الجار"}, {U"tourist", U"السائح"}, {U"stranger", U"الغريب"}, {U"hostage", U"الرهينة"},
    {U"inmate", U"السجين"}, {U"prisoner", U"السجين"}, {U"thug", U"البلطجي"}, {U"goon", U"البلطجي"},
    {U"gangster", U"رجل العصابة"}, {U"gang member", U"عضو العصابة"}, {U"biker", U"سائق الدراجة"}, {U"crowd", U"الحشد"},
    {U"everyone", U"الجميع"}, {U"all", U"الجميع"},
};

// Veyra: words games put in front of instructions, never a speaker (VI Translator knows the
// speaker by the name's colour; Veyra reads no colours).
constexpr const char32_t* notNames[]{
    U"tip", U"tips", U"note", U"hint", U"objective", U"objectives", U"warning", U"info", U"information",
    U"mission", U"goal", U"task", U"reward", U"rewards", U"bonus", U"help", U"controls", U"control",
    U"tutorial", U"location", U"status", U"chapter", U"level", U"quest", U"new", U"update", U"alert",
    U"notice", U"important", U"reminder", U"caution", U"danger", U"press", U"hold", U"use", U"select",
    U"error", U"success", U"failed", U"complete", U"completed", U"unlocked", U"achievement", U"trophy",
    U"challenge", U"time", U"score", U"total", U"cost", U"price", U"distance", U"speed", U"ammo",
    U"health", U"armor", U"armour", U"money", U"cash", U"wanted", U"area", U"zone", U"region", U"day",
    U"week", U"step", U"part", U"act", U"episode", U"stage", U"round", U"wave", U"lap", U"best",
};

constexpr Pair cuesAr[]{
    {U"laughs", U"يضحك"}, {U"laughing", U"يضحك"}, {U"laughter", U"ضحك"}, {U"chuckles", U"يضحك بخفة"},
    {U"chuckling", U"يضحك بخفة"}, {U"giggles", U"يقهقه"}, {U"sigh", U"يتنهّد"}, {U"sighs", U"يتنهّد"},
    {U"gasp", U"يشهق"}, {U"gasps", U"يشهق"}, {U"groans", U"يتأوّه"}, {U"groaning", U"يتأوّه"},
    {U"grunts", U"يهمهم"}, {U"grunting", U"يهمهم"}, {U"screams", U"يصرخ"}, {U"screaming", U"صراخ"},
    {U"shouts", U"يصيح"}, {U"shouting", U"صياح"}, {U"yells", U"يصيح"}, {U"coughs", U"يسعل"},
    {U"coughing", U"سعال"}, {U"cries", U"يبكي"}, {U"crying", U"بكاء"}, {U"sobbing", U"نحيب"},
    {U"panting", U"يلهث"}, {U"whispers", U"يهمس"}, {U"whispering", U"همس"}, {U"scoffs", U"يسخر"},
    {U"sniffs", U"يستنشق"}, {U"clears throat", U"يتنحنح"}, {U"exhales", U"يزفر"}, {U"inhales", U"يستنشق"},
    {U"mumbles", U"يتمتم"}, {U"mumbling", U"تمتمة"}, {U"whistles", U"يصفّر"}, {U"rattling", U"قعقعة"},
    {U"music playing", U"موسيقى"}, {U"music", U"موسيقى"}, {U"phone ringing", U"رنين الهاتف"},
    {U"phone buzzing", U"اهتزاز الهاتف"}, {U"phone vibrates", U"اهتزاز الهاتف"}, {U"siren wailing", U"صفّارة إنذار"},
    {U"sirens wailing", U"صفّارات إنذار"}, {U"sirens", U"صفّارات إنذار"}, {U"alarm blaring", U"إنذار يدوّي"},
    {U"gunshot", U"إطلاق نار"}, {U"gunshots", U"إطلاق نار"}, {U"gunfire", U"إطلاق نار"}, {U"explosion", U"انفجار"},
    {U"engine revving", U"هدير المحرك"}, {U"tires screeching", U"صرير الإطارات"}, {U"tyres screeching", U"صرير الإطارات"},
    {U"door opens", U"يُفتح الباب"}, {U"door closes", U"يُغلق الباب"}, {U"knocking", U"طرق"}, {U"footsteps", U"خطوات"},
    {U"crowd cheering", U"هتاف الحشد"}, {U"cheering", U"هتاف"}, {U"applause", U"تصفيق"}, {U"dog barking", U"نباح كلب"},
    {U"beeping", U"صفير"}, {U"static", U"تشويش"}, {U"indistinct chatter", U"أحاديث غير واضحة"},
    {U"indistinct", U"غير واضح"}, {U"slap", U"صفعة"}, {U"thud", U"ارتطام"}, {U"crash", U"تحطّم"}, {U"muffled", U"مكتوم"},
};

constexpr Pair languages[]{
    {U"Spanish", U"بالإسبانية"}, {U"Italian", U"بالإيطالية"}, {U"French", U"بالفرنسية"}, {U"Portuguese", U"بالبرتغالية"},
    {U"Russian", U"بالروسية"}, {U"Chinese", U"بالصينية"}, {U"Mandarin", U"بالماندرين"}, {U"Cantonese", U"بالكانتونية"},
    {U"Japanese", U"باليابانية"}, {U"Korean", U"بالكورية"}, {U"German", U"بالألمانية"}, {U"Creole", U"بالكريولية"},
    {U"Haitian Creole", U"بالكريولية الهايتية"}, {U"Arabic", U"بالعربية"}, {U"Hindi", U"بالهندية"},
    {U"Vietnamese", U"بالفيتنامية"}, {U"Tagalog", U"بالتاغالوغية"}, {U"Polish", U"بالبولندية"}, {U"Greek", U"باليونانية"},
    {U"Hebrew", U"بالعبرية"}, {U"Dutch", U"بالهولندية"}, {U"Turkish", U"بالتركية"}, {U"Persian", U"بالفارسية"},
    {U"Farsi", U"بالفارسية"}, {U"Ukrainian", U"بالأوكرانية"}, {U"Armenian", U"بالأرمنية"}, {U"Patois", U"بالباتوا"},
    {U"Jamaican Patois", U"بالباتوا الجامايكية"}, {U"Swahili", U"بالسواحيلية"},
};

template <size_t N>
const char32_t* find(const Pair (&table)[N], const S& key) {
    for (const auto& p : table) if (key == p.en) return p.ar;
    return nullptr;
}

std::optional<size_t> nameLen(const std::vector<S>& tokens) {
    if (tokens.empty()) return std::nullopt;
    const S& first = tokens.front();
    if (speakerName(first)) return 1;
    const bool capital = upperFirst(first) && first.size() >= 2
        && std::all_of(first.begin(), first.end(), [](char32_t c) { return alpha(c) || c == U'\'' || c == U'-' || c == U'.'; });
    if (capital && tokens.size() > 1 && speakerName(tokens[1])) return 2;
    return std::nullopt;
}

S bareName(S tagged) {
    while (!tagged.empty() && tagged.back() == U':') tagged.pop_back();
    while (!tagged.empty() && (tagged.back() == U'.' || tagged.back() == 0x2026 || tagged.back() == U',' || tagged.back() == U';'))
        tagged.pop_back();
    return trim(tagged);
}

bool isKnown(const S& name) { return find(known, lowerAll(name)) != nullptr; }

bool notAName(const S& name) {
    const auto low = lowerAll(name);
    const auto first = words(low).empty() ? low : words(low).front();
    for (const auto* w : notNames) if (low == w || first == w) return true;
    return false;
}

std::optional<S> roleAr(const S& name) {
    const S low = lowerAll(name);
    if (const auto* ar = find(roles, low)) return S(ar);
    const auto space = low.find(U' ');
    if (space == S::npos) return std::nullopt;
    const auto* title = find(roles, low.substr(0, space));
    if (!title) return std::nullopt;
    const S rest = low.substr(space + 1);
    S person;
    if (const auto* k = find(known, rest)) person = k;
    else {
        std::vector<S> parts;
        S cur;
        for (char32_t c : rest) { if (c == U'-') parts.push_back(transliterate(cur)), cur.clear(); else cur += c; }
        parts.push_back(transliterate(cur));
        person = join(parts, U"-");
    }
    return S(title) + U" " + person;
}

// A speaker in front: (name, rest). Veyra: any capitalised "Name:" that is not an instruction word.
std::optional<std::pair<S, S>> speaker(const S& line) {
    if (languageTag(line)) return std::nullopt;
    auto split = splitName(line);
    if (!split || letters(split->second) < 2) return std::nullopt;
    S name = bareName(split->first);
    if (!isKnown(name) && !isRole(name) && notAName(name)) return std::nullopt;
    return std::make_pair(std::move(name), std::move(split->second));
}

S cueShown(const S& shown) { return U"[" + trim(shown) + U"]"; }
S number(size_t n) {
    S out;
    for (char c : std::to_string(n)) out += char32_t(c);
    return out;
}
} // namespace

std::optional<std::pair<Cues, std::u32string>> takeCues(const std::u32string& line) {
    Cues cues;
    S text, rest = line;
    for (;;) {
        const auto open = rest.find(U'[');
        if (open == S::npos) break;
        const auto close = rest.find(U']', open);
        if (close == S::npos) break;
        const S inner = trim(rest.substr(open + 1, close - open - 1));
        const bool isCue = !inner.empty() && inner.size() <= 40 && std::any_of(inner.begin(), inner.end(), alpha)
            && std::all_of(inner.begin(), inner.end(), [](char32_t c) {
                   return alpha(c) || c == U' ' || c == U'-' || c == U'\'' || c == U',';
               });
        if (!isCue) {
            text += rest.substr(0, close + 1);
            rest = rest.substr(close + 1);
            continue;
        }
        text += rest.substr(0, open);
        const S before = trim(text);
        const auto tokens = words(before);
        if (before.empty()) cues.before.push_back(inner);
        else if (nameLen(tokens) == tokens.size()) cues.afterName.push_back(inner);
        else cues.after.push_back(inner);
        text += U' ';
        rest = rest.substr(close + 1);
    }
    text += rest;
    if (cues.empty()) return std::nullopt;
    return std::make_pair(std::move(cues), join(words(text), U" "));
}

std::optional<std::u32string> cueIn(const std::u32string& lang, const std::u32string& cue) {
    if (lang != U"ar") return std::nullopt;
    S low = lowerAll(trim(cue));
    while (!low.empty() && (low.back() == U'.' || low.back() == U',' || low.back() == U'!' || low.back() == U'?')) low.pop_back();
    if (const auto* ar = find(cuesAr, low)) return S(ar);
    return std::nullopt;
}

std::optional<std::u32string> speakerName(const std::u32string& word) {
    if (!endsWith(word, U":")) return std::nullopt;
    const S n = word.substr(0, word.size() - 1);
    const bool ok = upperFirst(n) && n.size() >= 2
        && std::all_of(n.begin(), n.end(), [](char32_t c) { return alpha(c) || c == U'\'' || c == U'-' || c == U'.'; });
    if (!ok) return std::nullopt;
    return n;
}

std::optional<std::pair<std::u32string, std::u32string>> splitName(const std::u32string& line) {
    const auto tokens = words(line);
    const auto n = nameLen(tokens);
    if (!n) return std::nullopt;
    // the end of the n-th word in the line
    size_t at = 0;
    for (size_t i = 0; i < *n; ++i) {
        while (at < line.size() && space(line[at])) ++at;
        at += tokens[i].size();
    }
    S rest = line.substr(at);
    size_t lead = 0;
    while (lead < rest.size() && space(rest[lead])) ++lead;
    return std::make_pair(join(std::vector<S>(tokens.begin(), tokens.begin() + long(*n)), U" "), rest.substr(lead));
}

bool isRole(const std::u32string& name) {
    const S low = lowerAll(name);
    const auto w = words(low);
    const S first = w.empty() ? S() : w.front();
    for (const auto& r : roles) if (low == r.en || first == r.en) return true;
    return false;
}

std::u32string nameIn(const std::u32string& lang, const std::u32string& name) {
    if (!arabicScript(lang)) return name;
    const S low = lowerAll(name);
    if (const auto* ar = find(known, low)) return ar;
    if (lang == U"ar") if (auto r = roleAr(name)) return *r;
    std::vector<S> out;
    for (const auto& word : words(low)) {
        if (const auto* ar = find(known, word)) { out.push_back(ar); continue; }
        std::vector<S> parts;
        S cur;
        for (char32_t c : word) { if (c == U'-') parts.push_back(transliterate(cur)), cur.clear(); else cur += c; }
        parts.push_back(transliterate(cur));
        out.push_back(join(parts, U"-"));
    }
    return join(out, U" ");
}

std::u32string transliterate(const std::u32string& word) {
    S w;
    for (char32_t c : word) if (asciiAlpha(c)) w += lower(c);
    const size_t n = w.size();
    auto vowel = [](char32_t c) { return c == U'a' || c == U'e' || c == U'i' || c == U'o' || c == U'u' || c == U'y'; };
    auto soft = [&](size_t i) { return i < n && (w[i] == U'e' || w[i] == U'i' || w[i] == U'y'); };
    // a "magic e" ("Kyle", "Mike"): the vowel before the last consonant is long
    const bool magic = n >= 4 && w[n - 1] == U'e' && !vowel(w[n - 2]) && vowel(w[n - 3]) && !vowel(w[n - 4]);
    S out;
    for (size_t i = 0; i < n;) {
        const char32_t c = w[i];
        const char32_t next = i + 1 < n ? w[i + 1] : U' ';
        if (i > 0 && c == w[i - 1] && !(c == U'a' || c == U'e' || c == U'i' || c == U'o' || c == U'u')) { ++i; continue; }
        const S two{c, next};
        const char32_t* digraph = nullptr;
        if (two == U"sh") digraph = U"ش";
        else if (two == U"ch") digraph = U"تش";
        else if (two == U"th") digraph = U"ث";
        else if (two == U"ph") digraph = U"ف";
        else if (two == U"kh") digraph = U"خ";
        else if (two == U"gh") digraph = U"غ";
        else if (two == U"ck") digraph = U"ك";
        else if (two == U"qu") digraph = U"كو";
        else if (two == U"oo" || two == U"ou") digraph = U"و";
        else if (two == U"ee" || two == U"ea" || two == U"ie") digraph = i == 0 ? U"إي" : U"ي";
        else if (two == U"ai" || two == U"ay") digraph = U"اي";
        if (digraph) { out += digraph; i += 2; continue; }
        const bool last = i + 1 == n;
        if (magic && i == n - 3) {
            out += (c == U'i' || c == U'y' || c == U'a') ? U"اي" : U"و";
            ++i;
            continue;
        }
        const char32_t* s = U"";
        switch (c) {
        case U'a': s = U"ا"; break;
        case U'e': s = i == 0 ? U"إ" : last ? U"" : U"ي"; break;
        case U'i': s = i == 0 ? U"إي" : U"ي"; break;
        case U'o': case U'u': s = i == 0 ? U"أو" : U"و"; break;
        case U'y': s = U"ي"; break;
        case U'b': s = U"ب"; break;
        case U'c': s = soft(i + 1) ? U"س" : U"ك"; break;
        case U'd': s = U"د"; break;
        case U'f': s = U"ف"; break;
        case U'g': s = soft(i + 1) ? U"ج" : U"غ"; break;
        case U'h': s = U"ه"; break;
        case U'j': s = U"ج"; break;
        case U'k': s = U"ك"; break;
        case U'l': s = U"ل"; break;
        case U'm': s = U"م"; break;
        case U'n': s = U"ن"; break;
        case U'p': s = U"ب"; break;
        case U'q': s = U"ك"; break;
        case U'r': s = U"ر"; break;
        case U's': s = U"س"; break;
        case U't': s = U"ت"; break;
        case U'v': s = U"ف"; break;
        case U'w': s = U"و"; break;
        case U'x': s = U"كس"; break;
        case U'z': s = U"ز"; break;
        default: break;
        }
        out += s;
        ++i;
    }
    return replaceAll(out, U"يي", U"ي");
}

std::optional<std::pair<std::u32string, std::u32string>> languageTag(const std::u32string& line) {
    if (!startsWith(line, U"In ")) return std::nullopt;
    const S rest = line.substr(3);
    const auto colon = rest.find(U':');
    if (colon == S::npos) return std::nullopt;
    const S lang = rest.substr(0, colon);
    const auto w = words(lang);
    if (w.empty() || w.size() > 2) return std::nullopt;
    for (const auto& x : w)
        if (!upperFirst(x) || !std::all_of(x.begin(), x.end(), alpha)) return std::nullopt;
    S sentence = rest.substr(colon + 1);
    size_t lead = 0;
    while (lead < sentence.size() && space(sentence[lead])) ++lead;
    sentence = sentence.substr(lead);
    if (letters(sentence) < 2) return std::nullopt;
    S best = lang;
    double bestScore = 0;
    for (const auto& l : languages) {
        if (lowerAll(l.en) == lowerAll(lang)) { best = l.en; bestScore = 2; break; }
        const double c = closeness(l.en, lang);
        if (c >= 0.7 && c > bestScore) { best = l.en; bestScore = c; }
    }
    return std::make_pair(best, sentence);
}

std::optional<std::u32string> languageIn(const std::u32string& lang, const std::u32string& language) {
    if (lang != U"ar") return std::nullopt;
    if (const auto* ar = find(languages, language)) return S(ar) + U":";
    return std::nullopt;
}

std::pair<std::u32string, std::vector<std::u32string>> protectTerms(const std::u32string& line) {
    std::vector<S> terms, out;
    std::vector<S> parts;
    {
        S cur;
        for (char32_t c : line) { if (c == U' ') parts.push_back(cur), cur.clear(); else cur += c; }
        parts.push_back(cur);
    }
    auto coreOf = [](const S& w, const S& strip) {
        size_t end = w.size();
        while (end > 0 && strip.find(w[end - 1]) != S::npos) --end;
        return w.substr(0, end);
    };
    for (size_t i = 0; i < parts.size();) {
        const S& w = parts[i];
        const S core = coreOf(w, U",.;:!?)");
        const S tail = w.substr(core.size());
        S up = core;
        for (auto& c : up) if (c >= U'a' && c <= U'z') c -= 32;
        const bool term = startsWith(up, U"GTA+") || startsWith(up, U"GTA$") || up == U"GTAV" || contains(core, U"™")
            || (contains(core, U".") && contains(core, U"/")) || endsWith(core, U".com");
        if (up == U"GTA" && i + 1 < parts.size()) {
            const S ncore = coreOf(parts[i + 1], U",.;:!?");
            if (ncore == U"Online" || ncore == U"V") {
                terms.push_back(core + U" " + ncore);
                out.push_back(U"[" + number(terms.size()) + U"]" + parts[i + 1].substr(ncore.size()));
                i += 2;
                continue;
            }
        }
        if (term) {
            S kept = core;
            // OCR reads the zeros of "GTA$500,000" as the letter O
            if (startsWith(up, U"GTA$"))
                for (size_t k = 4; k < kept.size(); ++k) if (kept[k] == U'O' || kept[k] == U'o') kept[k] = U'0';
            terms.push_back(kept);
            out.push_back(U"[" + number(terms.size()) + U"]" + tail);
        } else {
            out.push_back(w);
        }
        ++i;
    }
    return {join(out, U" "), terms};
}

std::u32string restoreTerms(std::u32string text, const std::vector<std::u32string>& terms) {
    static constexpr char32_t arabicDigits[] = U"٠١٢٣٤٥٦٧٨٩";
    for (size_t i = 0; i < terms.size(); ++i) {
        S n, an;
        for (char c : std::to_string(i + 1)) { n += char32_t(c); an += arabicDigits[c - '0']; }
        // the model may answer in Arabic digits, and right-to-left text can flip the brackets;
        // the term goes in a left-to-right isolate so "GTA+" cannot turn into "+GTA"
        const S kept = U"\u2066" + terms[i] + U"\u2069";
        for (const S& form : {U"[" + n + U"]", U"]" + n + U"[", U"[" + an + U"]", U"]" + an + U"["})
            text = replaceAll(text, form, kept);
    }
    return text;
}

std::u32string expandSlang(std::u32string line) {
    line = replaceAll(line, U"C'mon", U"Come on");
    line = replaceAll(line, U"c'mon", U"come on");
    line = replaceAll(line, U"C’mon", U"Come on");
    return replaceAll(line, U"c’mon", U"come on");
}

std::vector<std::u32string> sentences(const std::u32string& text) {
    std::vector<S> out;
    size_t start = 0;
    for (size_t i = 0; i < text.size(); ++i) {
        const char32_t c = text[i];
        const bool end = c == U'.' || c == U'!' || c == U'?' || c == 0x2026;
        if (end && i + 2 < text.size() && text[i + 1] == U' ' && upperAscii(text[i + 2])) {
            const S s = trim(text.substr(start, i + 1 - start));
            if (!s.empty()) out.push_back(s);
            start = i + 2;
        }
    }
    if (start < text.size()) {
        const S s = trim(text.substr(start));
        if (!s.empty()) out.push_back(s);
    }
    return out;
}

std::u32string polite(const std::u32string& lang, std::u32string text) {
    if (lang == U"ar") text = replaceAll(text, U"عاهر", U"ساقط");
    return text;
}

Plan plan(const std::u32string& lineIn, const std::u32string& lang, bool offline) {
    Plan p;
    p.lang = lang;
    S line = trim(lineIn);
    // "[laughs]": the cues off first, each from the word list (or translated: offline model)
    if (auto taken = takeCues(line)) {
        p.cues = std::move(taken->first);
        line = std::move(taken->second);
    }
    std::vector<S> unknownCues;
    for (const auto* list : {&p.cues.before, &p.cues.afterName, &p.cues.after})
        for (const auto& cue : *list) {
            auto shown = cueIn(lang, cue);
            if (!shown && !offline) shown = cue;  // network engines: the cue stays as the game wrote it
            if (!shown) unknownCues.push_back(cue);
            p.cuesShown.push_back(shown);
        }
    // a cue-only line ("Donnie: [laughs]", "[rattling]"): the name (if any) and the cues
    const S probe = line + U" xx";
    const auto probeName = speaker(probe);
    if (!p.cues.empty() && (letters(line) < 2 || (probeName && probeName->second == U"xx"))) {
        if (probeName && probeName->second == U"xx") p.name = nameIn(lang, probeName->first);
        p.onlyCuesAndName = true;
        p.parts = unknownCues;
        return p;
    }
    if (auto named = speaker(line)) {
        p.name = nameIn(lang, named->first);
        line = named->second;
    }
    if (auto tagged = languageTag(line)) {
        p.tag = languageIn(lang, tagged->first);
        p.tagEnglish = U"In " + tagged->first + U":";
        line = tagged->second;
    }
    auto [protectedLine, terms] = protectTerms(line);
    p.terms = std::move(terms);
    if (!p.terms.empty() && letters(protectedLine) == 0) {
        p.whole = U"\u2066" + line + U"\u2069";
    } else {
        const S plain = expandSlang(protectedLine);
        // the offline model translates one sentence well and a paragraph badly: one by one
        auto parts = offline ? sentences(plain) : std::vector<S>{};
        if (parts.size() <= 1) parts = {plain};
        p.parts = std::move(parts);
    }
    p.sentenceParts = p.parts.size();
    for (auto& cue : unknownCues) p.parts.push_back(cue);
    if (!p.tag && !p.tagEnglish.empty()) {
        if (offline) p.parts.push_back(p.tagEnglish);
        else p.tag = p.tagEnglish;
    }
    return p;
}

std::u32string assemble(const Plan& p, const std::vector<std::u32string>& translated) {
    auto at = [&](size_t i) { return i < translated.size() ? trim(translated[i]) : S(); };
    size_t next = p.sentenceParts;
    // the cues as shown, in the order before, after the name, after
    std::vector<S> cues;
    for (const auto& shown : p.cuesShown) {
        if (shown) { cues.push_back(*shown); continue; }
        const S t = next < translated.size() ? at(next) : S();
        ++next;
        cues.push_back(t.empty() ? S(U"…") : t);
    }
    S sentence;
    if (!p.whole.empty()) sentence = p.whole;
    else if (!p.onlyCuesAndName) {
        std::vector<S> pieces;
        for (size_t i = 0; i < p.sentenceParts; ++i) if (auto t = at(i); !t.empty()) pieces.push_back(t);
        sentence = polite(p.lang, restoreTerms(join(pieces, U" "), p.terms));
    }
    if (!sentence.empty()) {
        if (p.tag) sentence = trim(*p.tag) + U" " + sentence;
        else if (!p.tagEnglish.empty()) {
            const S t = at(next);
            if (!t.empty()) sentence = t + U" " + sentence;
        }
    }
    const size_t b = p.cues.before.size(), n = p.cues.afterName.size();
    S out;
    for (size_t i = 0; i < b; ++i) out += cueShown(cues[i]) + U" ";
    if (p.name) out += *p.name + U": ";
    for (size_t i = b; i < b + n; ++i) out += cueShown(cues[i]) + U" ";
    out += sentence;
    for (size_t i = b + n; i < cues.size(); ++i) out += U" " + cueShown(cues[i]);
    return trim(out);
}

} // namespace veyra::ui::viline
