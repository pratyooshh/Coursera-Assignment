"""Extract Scaffold's content from the Swift sources into JSON for the PWA.

Hand-retyping ~20k characters of prose is where transcription errors live, so
the web build reads from the same source of truth the iOS app does.
"""
import json, re, pathlib

SRC = pathlib.Path("/home/user/Coursera-Assignment/ios/Scaffold")

ESCAPES = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\", "0": "\0", "'": "'"}


def read_string(s, i):
    """Parse a Swift string literal starting at the opening quote."""
    assert s[i] == '"', f"expected quote at {i}: {s[i-20:i+20]!r}"
    i += 1
    out = []
    while i < len(s):
        c = s[i]
        if c == "\\":
            nxt = s[i + 1]
            if nxt == "u" and s[i + 2] == "{":
                j = s.index("}", i)
                out.append(chr(int(s[i + 3 : j], 16)))
                i = j + 1
                continue
            out.append(ESCAPES.get(nxt, nxt))
            i += 2
            continue
        if c == '"':
            return "".join(out), i + 1
        out.append(c)
        i += 1
    raise ValueError("unterminated string")


def skip_ws(s, i):
    while i < len(s) and s[i] in " \t\n\r":
        i += 1
    return i


def match_block(s, i, opener, closer):
    """Return (inner_text, index_after_closer) for a balanced delimiter run."""
    assert s[i] == opener, f"expected {opener} at {i}: {s[i-30:i+30]!r}"
    depth = 0
    start = i
    while i < len(s):
        c = s[i]
        if c == '"':
            _, i = read_string(s, i)
            continue
        if c == "/" and s[i : i + 2] == "//":
            i = s.index("\n", i)
            continue
        if c == opener:
            depth += 1
        elif c == closer:
            depth -= 1
            if depth == 0:
                return s[start + 1 : i], i + 1
        i += 1
    raise ValueError("unbalanced")


def find_calls(src, name):
    """Yield the argument text of every `name(...)` call."""
    for m in re.finditer(r"\b" + re.escape(name) + r"\(", src):
        i = m.end() - 1
        try:
            inner, _ = match_block(src, i, "(", ")")
        except (AssertionError, ValueError):
            continue
        yield inner


def arg_string(args, label):
    """Value of `label: "..."` — or `label = "..."` for a plain declaration."""
    m = re.search(r"\b" + re.escape(label) + r"\s*[:=]\s*", args)
    if not m:
        return None
    i = skip_ws(args, m.end())
    if i >= len(args) or args[i] != '"':
        return None
    return read_string(args, i)[0]


def arg_int(args, label):
    m = re.search(r"\b" + re.escape(label) + r":\s*(-?\d+)", args)
    return int(m.group(1)) if m else None


def arg_enum(args, label):
    m = re.search(r"\b" + re.escape(label) + r":\s*(?:Theme\.)?\.?(\w+)", args)
    return m.group(1) if m else None


def string_list(text):
    """All top-level string literals in a bracketed list."""
    out, i = [], 0
    while i < len(text):
        if text[i] == '"':
            v, i = read_string(text, i)
            out.append(v)
        else:
            i += 1
    return out


def arg_list(args, label):
    m = re.search(r"\b" + re.escape(label) + r"\s*[:=]\s*\[", args)
    if not m:
        return []
    inner, _ = match_block(args, m.end() - 1, "[", "]")
    return string_list(inner)


# ---------------------------------------------------------------- articles

def parse_articles():
    src = (SRC / "Content/Library.swift").read_text()
    articles = []
    for args in find_calls(src, "Article"):
        m = re.search(r"\bbody:\s*\[", args)
        body_src, _ = match_block(args, m.end() - 1, "[", "]")

        blocks = []
        i = 0
        while i < len(body_src):
            bm = re.compile(r"\.(paragraph|heading|callout|bullets|quote)\(").search(body_src, i)
            if not bm:
                break
            j = bm.end() - 1
            inner, after = match_block(body_src, j, "(", ")")
            kind = bm.group(1)
            if kind in ("paragraph", "heading", "callout"):
                blocks.append({"t": kind, "v": read_string(inner, skip_ws(inner, 0))[0]})
            elif kind == "bullets":
                k = skip_ws(inner, 0)
                lst, _ = match_block(inner, k, "[", "]")
                blocks.append({"t": "bullets", "v": string_list(lst)})
            else:
                blocks.append({
                    "t": "quote",
                    "v": arg_string(inner, "text"),
                    "by": arg_string(inner, "attribution"),
                })
            i = after

        articles.append({
            "id": arg_string(args, "id"),
            "title": arg_string(args, "title"),
            "subtitle": arg_string(args, "subtitle"),
            "category": arg_enum(args, "category"),
            "symbol": arg_string(args, "symbol"),
            "readMinutes": arg_int(args, "readMinutes"),
            "body": blocks,
            "sources": arg_list(args, "sources"),
        })
    return articles


# ------------------------------------------------------------- interventions

def parse_interventions():
    src = (SRC / "Content/Toolbox.swift").read_text()
    # Skip the struct declarations at the top of the file.
    src = src[src.index("enum Toolbox"):]
    tools = []
    for args in find_calls(src, "Intervention"):
        m = re.search(r"\bsteps:\s*\[", args)
        steps_src, _ = match_block(args, m.end() - 1, "[", "]")
        steps = []
        for s_args in find_calls(steps_src, "ToolStep"):
            steps.append({
                "title": arg_string(s_args, "title"),
                "detail": arg_string(s_args, "detail"),
                "seconds": arg_int(s_args, "seconds"),
                "prompt": arg_string(s_args, "prompt"),
            })
        tools.append({
            "id": arg_string(args, "id"),
            "trigger": arg_string(args, "trigger"),
            "subtitle": arg_string(args, "subtitle"),
            "symbol": arg_string(args, "symbol"),
            "tint": arg_enum(args, "tint"),
            "steps": steps,
            "closingNote": arg_string(args, "closingNote"),
        })
    return tools


# ---------------------------------------------------------------- ASRS

def parse_asrs():
    src = (SRC / "Content/ASRS.swift").read_text()

    def items(label):
        m = re.search(r"static let " + label + r": \[Item\] = \[", src)
        inner, _ = match_block(src, m.end() - 1, "[", "]")
        return [
            {"text": arg_string(a, "text"), "threshold": arg_int(a, "positiveThreshold")}
            for a in find_calls(inner, "Item")
        ]

    def prompts(label):
        m = re.search(r"static let " + label + r": \[Prompt\] = \[", src)
        inner, _ = match_block(src, m.end() - 1, "[", "]")
        return [
            {"q": arg_string(a, "question"), "why": arg_string(a, "why")}
            for a in find_calls(inner, "Prompt")
        ]

    return {
        "partA": items("partA"),
        "partB": items("partB"),
        "responseLabels": arg_list(src, "responseLabels") or
            ["Never", "Rarely", "Sometimes", "Often", "Very Often"],
        "inattentiveIndices": [int(x) for x in re.search(
            r"inattentiveIndices = \[([\d, ]+)\]", src).group(1).split(",")],
        "hyperactiveIndices": [int(x) for x in re.search(
            r"hyperactiveIndices = \[([\d, ]+)\]", src).group(1).split(",")],
        "threshold": 4,
        "context": {
            "childhood": prompts("childhood"),
            "impairment": prompts("impairment"),
            "differential": prompts("differential"),
        },
    }


# ---------------------------------------------------------------- seeds

def parse_seeds():
    src = (SRC / "Content/Seeds.swift").read_text()

    routines = []
    m = re.search(r"static var seeds: \[Routine\] \{", src)
    seeds_src, _ = match_block(src, m.end() - 1, "{", "}")
    for args in find_calls(seeds_src, "Routine"):
        sm = re.search(r"\bsteps:\s*\[", args)
        steps_src, _ = match_block(args, sm.end() - 1, "[", "]")
        routines.append({
            "name": arg_string(args, "name"),
            "symbol": arg_string(args, "symbol"),
            "steps": [
                {"text": arg_string(a, "text"), "minutes": arg_int(a, "minutes") or 2}
                for a in find_calls(steps_src, "RoutineStep")
            ],
            "reminder": None,
        })

    # Breakdown patterns: ("label", ["step", ...])
    pm = re.search(r"static let patterns: \[\(String, \[String\]\)\] = \[", src)
    pat_src, _ = match_block(src, pm.end() - 1, "[", "]")
    patterns, i = [], 0
    while i < len(pat_src):
        if pat_src[i] == "(":
            inner, after = match_block(pat_src, i, "(", ")")
            k = skip_ws(inner, 0)
            label, k = read_string(inner, k)
            lb = inner.index("[", k)
            lst, _ = match_block(inner, lb, "[", "]")
            patterns.append({"label": label, "steps": string_list(lst)})
            i = after
        else:
            i += 1

    crisis = [
        {
            "region": arg_string(a, "region"),
            "name": arg_string(a, "name"),
            "contact": arg_string(a, "contact"),
            "detail": arg_string(a, "detail"),
        }
        for a in find_calls(src, "CrisisResource")
    ]

    def block_list(pattern):
        mm = re.search(pattern, src)
        inner, _ = match_block(src, mm.end() - 1, "[", "]")
        return string_list(inner)

    return {
        "routines": routines,
        "dopamineMenu": block_list(r"static let defaults: \[String\] = \["),
        "breakdownQuestions": block_list(r"static let questions: \[String\] = \["),
        "breakdownPatterns": patterns,
        "crisis": crisis,
        "crisisMessage": arg_string(src, "message") or "",
        "feelings": block_list(r"static let options: \[String\] = \["),
    }


# ---------------------------------------------------------------- emit

content = {
    "articles": parse_articles(),
    "interventions": parse_interventions(),
    "asrs": parse_asrs(),
    **parse_seeds(),
}

# Categories, in the order the Swift enum declares them.
cat_src = (SRC / "Content/Library.swift").read_text()
cm = re.search(r"enum ArticleCategory: String, CaseIterable, Identifiable \{", cat_src)
cat_inner, _ = match_block(cat_src, cm.end() - 1, "{", "}")
content["categories"] = [
    {"key": k, "label": v}
    for k, v in re.findall(r'case (\w+) = "([^"]+)"', cat_inner)
]

out = pathlib.Path("/home/user/Coursera-Assignment/docs/scaffold/content.js")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(
    "// GENERATED from ios/Scaffold/Content/*.swift — do not edit by hand.\n"
    "window.CONTENT = " + json.dumps(content, ensure_ascii=False, indent=1) + ";\n"
)

# ---------------------------------------------------------------- validate
a, t, s = content["articles"], content["interventions"], content["asrs"]
print(f"articles      {len(a)}")
print(f"interventions {len(t)}")
print(f"asrs items    {len(s['partA'])} + {len(s['partB'])}")
print(f"routines      {len(content['routines'])}")
print(f"crisis        {len(content['crisis'])}")
print(f"categories    {len(content['categories'])}")
print(f"patterns      {len(content['breakdownPatterns'])}")

errs = []
if len(a) != 18: errs.append(f"expected 18 articles, got {len(a)}")
if len(t) != 14: errs.append(f"expected 14 interventions, got {len(t)}")
if len(s["partA"]) != 6 or len(s["partB"]) != 12: errs.append("ASRS item count wrong")
for x in a:
    for f in ("id", "title", "subtitle", "category", "readMinutes"):
        if not x.get(f): errs.append(f"article {x.get('id')}: missing {f}")
    if not x["body"]: errs.append(f"article {x['id']}: empty body")
    if not x["sources"]: errs.append(f"article {x['id']}: no sources")
    for b in x["body"]:
        if b["t"] == "bullets":
            if not b["v"]: errs.append(f"article {x['id']}: empty bullets")
        elif not b.get("v"): errs.append(f"article {x['id']}: empty {b['t']}")
for x in t:
    if not x["steps"]: errs.append(f"tool {x['id']}: no steps")
    for st in x["steps"]:
        if not st["title"] or not st["detail"]:
            errs.append(f"tool {x['id']}: incomplete step")
for it in s["partA"] + s["partB"]:
    if not it["text"] or it["threshold"] is None: errs.append("bad ASRS item")

print("\n" + ("VALIDATION FAILED:\n  " + "\n  ".join(errs) if errs else "validation: OK"))
print(f"\nwrote {out} ({out.stat().st_size:,} bytes)")
print(f"total prose: {sum(len(json.dumps(x)) for x in a + t):,} chars")
