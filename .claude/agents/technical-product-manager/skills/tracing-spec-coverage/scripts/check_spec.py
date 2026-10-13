#!/usr/bin/env python3
"""Check a sprint spec's structure and traceability (see ../SKILL.md).

Usage:
    python3 check_spec.py SPEC.md [--plan SPRINT_FILE --sprint N]
    python3 check_spec.py - < spec.md          # spec on stdin

Exit 0 and print "OK" when clean; otherwise print one finding per line and exit 1.
"""
import argparse
import re
import sys

SECTIONS = [
    "User scenarios", "Functional requirements", "Interfaces and data",
    "Acceptance criteria", "Edge cases", "Test cases",
    "Constitution and non-functional checks", "Out of scope", "Open items", "Coverage",
]
ID_RE = re.compile(r"\b(FR|AC|EC|TC)-\d+\.\d+\b")


def table_rows(text, prefix):
    """Rows of markdown tables whose first cell starts with PREFIX-, as lists of cells."""
    rows = []
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("|") and re.match(rf"\|\s*{prefix}-\d+\.\d+\s*\|", s):
            rows.append([c.strip() for c in s.strip("|").split("|")])
    return rows


def ids_in(cell):
    return {m.group(0) for m in ID_RE.finditer(cell)}


def plan_acs(plan_text, sprint):
    """Return {'S3-1/1', ...} for every acceptance bullet of each story in sprint N."""
    head = re.compile(rf"^##\s+Sprint\s+{sprint}\b")
    lines, inside = [], False
    for line in plan_text.splitlines():
        if head.match(line):
            inside = True
            continue
        if inside and re.match(r"^##\s+Sprint\s+\d+", line):
            break
        if inside:
            lines.append(line)
    found, story, k = set(), None, 0
    story_re = re.compile(rf"\b(S{sprint}-\d+)\b")
    for line in lines:
        m = story_re.search(line)
        is_story = m and (line.lstrip().startswith(("###", "- **")) or line.startswith("**"))
        if is_story:
            story, k = m.group(1), 0
            continue
        if story and re.match(r"^\s*-\s+(\[ \]\s+)?\S", line) and (line.startswith("  ") or "[ ]" in line):
            k += 1
            found.add(f"{story}/{k}")
    return found


def check(text, plan_text=None, sprint=None):
    out = []
    for i, name in enumerate(SECTIONS, 1):
        if not re.search(rf"^##\s+{i}\.\s+{re.escape(name)}", text, re.M):
            out.append(f"missing section: ## {i}. {name}")

    if not re.search(r"\*\*Sources:\*\*.*constitution (v\d+\.\d+\.\d+|none)", text, re.I):
        out.append("Sources line must name the constitution version read (or 'none')")

    frs, acs, ecs, tcs = (table_rows(text, p) for p in ("FR", "AC", "EC", "TC"))
    defined = {r[0] for r in frs + acs + ecs + tcs}
    if not frs:
        out.append("no FR rows in section 2")
    if not tcs:
        out.append("no TC rows in section 6")

    for r in frs:
        if len(r) < 3 or not r[2] or r[2] in ("-", "—"):
            out.append(f"{r[0]}: no Source")
        if len(r) > 1 and not re.search(r"\b(MUST|SHOULD)\b", r[1]):
            out.append(f"{r[0]}: requirement has no MUST/SHOULD")

    ac_covers = {}
    for r in acs:
        cov = ids_in(r[-1])
        ac_covers[r[0]] = cov
        if not any(c.startswith("FR-") for c in cov):
            out.append(f"{r[0]}: Covers names no FR")
        if len(r) > 2 and not re.search(r"\bGiven\b.*\bwhen\b.*\bthen\b", r[2], re.I):
            out.append(f"{r[0]}: not in Given/When/Then form")

    tested = set()
    for r in tcs:
        cov = ids_in(r[-1])
        if not cov:
            out.append(f"{r[0]}: Covers is empty")
        for c in cov - defined:
            out.append(f"{r[0]}: covers undefined {c}")
        tested |= cov
        if len(r) > 2 and not r[2]:
            out.append(f"{r[0]}: no test file")

    tested_via_ac = set().union(*(ac_covers[a] for a in tested if a in ac_covers)) if tested else set()
    for r in frs:
        if r[0] not in tested and r[0] not in tested_via_ac:
            out.append(f"{r[0]}: no test case covers it (directly or through an AC)")
    for r in acs + ecs:
        if r[0] not in tested:
            out.append(f"{r[0]}: no test case covers it")

    qs = set(re.findall(r"\*\*(Q\d+)\*\*", text))
    if len(qs) > 3:
        out.append(f"{len(qs)} clarification questions; the limit is 3 (turn the rest into assumptions)")
    cs = set(re.findall(r"\*\*(C\d+)\*\*", text))
    if re.search(r"\*\*Status:\*\*\s*ready", text) and (qs or cs):
        out.append("Status is 'ready' but open Q/C items remain")

    if re.search(r"product decision", text, re.I):
        out.append("'Product decision' found: product gaps go in section 9 as Q or A, not decided in the spec")
    if re.search(r"(?i:mark|set)\w*\b[^.\n]{0,40}\b(DONE|\[DONE\])", text):
        out.append("spec tells someone to mark a sprint DONE; sprintkit-sync owns status markers")

    if plan_text is not None:
        refined = set(re.findall(r"\bS\d+-\d+/\d+\b", "\n".join(" ".join(r) for r in acs)))
        for ac in sorted(plan_acs(plan_text, sprint) - refined):
            out.append(f"sprint plan criterion {ac} is not refined by any AC row")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("--plan")
    ap.add_argument("--sprint", type=int)
    a = ap.parse_args()
    text = sys.stdin.read() if a.spec == "-" else open(a.spec, encoding="utf-8").read()
    plan = open(a.plan, encoding="utf-8").read() if a.plan else None
    if plan is not None and a.sprint is None:
        ap.error("--plan needs --sprint")
    findings = check(text, plan, a.sprint)
    print("\n".join(findings) if findings else "OK")
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
