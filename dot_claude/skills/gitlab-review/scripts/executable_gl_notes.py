#!/usr/bin/env python3
"""Post and check GitLab MR review draft notes with correct diff positions.

Usage:
  gl_notes.py post  <group/project> <mr_iid> <notes.json> [--dry-run]
  gl_notes.py check <group/project> <mr_iid>

notes.json is a list of objects:
  {"file": "src/foo.c", "line": 123, "body": "..."}            one line
  {"file": "src/foo.c", "line": 120, "end_line": 126, ...}      a block
  {"file": "src/foo.c", "old_line": 98, "body": "..."}          a removed line
  {"body": "..."}                                               general note
"line"/"end_line" are new-side (MR head) line numbers. The script finds
each line in the MR diff and builds the position GitLab needs: new_line
for an added line, old_line + new_line for a context line, a line_range
for a block. A line that is not in the diff becomes a general note that
names the file and line. Every inline note is checked for a line_code
after posting.

"check" lists the existing draft notes with the source line each one is
attached to, and flags positions that GitLab can't show inline.

Uses `glab api`, so glab must be logged in to the GitLab host.
"""
import hashlib
import json
import re
import subprocess
import sys
import urllib.parse


def api(method, path, payload=None):
    cmd = ["glab", "api", "--method", method, path]
    if payload is not None:
        cmd += ["-H", "Content-Type: application/json", "--input", "-"]
    r = subprocess.run(cmd, input=json.dumps(payload) if payload is not None else None,
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"{method} {path}: {r.stdout.strip()} {r.stderr.strip()}")
    return json.loads(r.stdout) if r.stdout.strip() else None


def api_all(path):
    out, page = [], 1
    while True:
        sep = "&" if "?" in path else "?"
        chunk = api("GET", f"{path}{sep}per_page=100&page={page}")
        out += chunk
        if len(chunk) < 100:
            return out
        page += 1


def diff_maps(changes):
    """Per file: new_line -> (kind, old_line, text) and old_line -> new counter.

    kind is "add" or "ctx". For an added line old_line is the old-side
    counter at that point (what GitLab puts in the line_code).
    """
    new_map, old_map = {}, {}
    for c in changes:
        nm, om = {}, {}
        old = new = 0
        for line in c["diff"].split("\n"):
            h = re.match(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
            if h:
                old, new = int(h.group(1)), int(h.group(2))
                continue
            if line.startswith("\\"):
                continue
            if line.startswith("+"):
                nm[new] = ("add", old, line[1:])
                new += 1
            elif line.startswith("-"):
                om[old] = (new, line[1:])
                old += 1
            elif old or new:
                nm[new] = ("ctx", old, line[1:])
                old += 1
                new += 1
        new_map[c["new_path"]], old_map[c["new_path"]] = nm, om
    return new_map, old_map


def line_code(path, old, new):
    return f"{hashlib.sha1(path.encode()).hexdigest()}_{old}_{new}"


def build_position(note, refs, new_map, old_map):
    """Return a position dict, or None if the line is not in the diff."""
    f = note["file"]
    base = {"position_type": "text", "old_path": f, "new_path": f,
            "base_sha": refs["base_sha"], "start_sha": refs["start_sha"],
            "head_sha": refs["head_sha"]}
    if "old_line" in note and "line" not in note:
        hit = old_map.get(f, {}).get(note["old_line"])
        if not hit:
            return None
        return {**base, "old_line": note["old_line"]}
    nm = new_map.get(f, {})
    start = nm.get(note["line"])
    end_line = note.get("end_line", note["line"])
    end = nm.get(end_line)
    if not start or not end:
        return None
    if end_line == note["line"]:
        pos = {**base, "new_line": note["line"]}
        if start[0] == "ctx":
            pos["old_line"] = start[1]
        return pos

    def endpoint(n, hit):
        e = {"line_code": line_code(f, hit[1], n), "new_line": n}
        if hit[0] == "add":
            e["type"] = "new"
        else:
            e["type"] = None
            e["old_line"] = hit[1]
        return e

    pos = {**base, "new_line": end_line,
           "line_range": {"start": endpoint(note["line"], start), "end": endpoint(end_line, end)}}
    if end[0] == "ctx":
        pos["old_line"] = end[1]
    return pos


def load(project, iid):
    p = f"projects/{urllib.parse.quote(project, safe='')}/merge_requests/{iid}"
    mr = api("GET", p)
    # Without access_raw_diffs, GitLab returns an empty diff for large
    # files, and every note on such a file would become a general note.
    changes = api("GET", f"{p}/changes?access_raw_diffs=true")["changes"]
    for c in changes:
        if not c["diff"] and not c.get("renamed_file") and c.get("a_mode") == c.get("b_mode"):
            print(f"WARNING: empty diff for {c['new_path']}, notes on it can't be inline",
                  file=sys.stderr)
    return p, mr["diff_refs"], diff_maps(changes)


def cmd_post(project, iid, notes_file, dry_run):
    p, refs, (new_map, old_map) = load(project, iid)
    for note in json.load(open(notes_file)):
        body = note["body"]
        pos = build_position(note, refs, new_map, old_map) if "file" in note else None
        if "file" in note and pos is None:
            where = note.get("line", note.get("old_line"))
            body = f"`{note['file']}:{where}` (outside this MR's diff): {body}"
        where = (f"{note['file']}:{note.get('line', note.get('old_line'))}"
                 + (f"-{note['end_line']}" if note.get("end_line") else "")) if pos else "general"
        if dry_run:
            print(f"[dry-run] {where}: {json.dumps(pos)}")
            continue
        r = api("POST", f"{p}/draft_notes", {"note": body, **({"position": pos} if pos else {})})
        ok = "" if not pos or r.get("line_code") else "  WARNING: no line_code, not attached"
        print(f"draft {r['id']} {where}{ok}")


def cmd_check(project, iid):
    p, refs, (new_map, old_map) = load(project, iid)
    for d in api_all(f"{p}/draft_notes"):
        title = re.sub(r"\*\*", "", d["note"].split("\n")[0])[:90]
        pos = d.get("position") or {}
        f = pos.get("new_path")
        if not f:
            print(f"draft {d['id']} general\n    note: {title}")
            continue
        nl, ol = pos.get("new_line"), pos.get("old_line")
        problems = []
        if not d.get("line_code"):
            problems.append("no line_code")
        if nl is not None:
            hit = new_map.get(f, {}).get(nl)
            if not hit:
                problems.append("line not in diff")
            elif hit[0] == "ctx" and ol != hit[1]:
                problems.append(f"context line needs old_line={hit[1]}")
            elif hit[0] == "add" and ol is not None and not pos.get("line_range"):
                problems.append("added line must not have old_line")
            text = hit[2].strip() if hit else "?"
        else:
            hit = old_map.get(f, {}).get(ol)
            text = hit[1].strip() if hit else "?"
            if not hit:
                problems.append("removed line not in diff")
        lr = pos.get("line_range") or {}
        if lr and lr["start"].get("new_line") in new_map.get(f, {}):
            text = new_map[f][lr["start"]["new_line"]][2].strip()
        span =f"{lr['start'].get('new_line')}-{lr['end'].get('new_line')}" if lr else str(nl if nl is not None else f"old {ol}")
        flag = f"  PROBLEM: {', '.join(problems)}" if problems else ""
        print(f"draft {d['id']} {f}:{span}{flag}\n    line: {text[:80]!r}\n    note: {title}")


def main():
    a = sys.argv[1:]
    if len(a) >= 4 and a[0] == "post":
        cmd_post(a[1], a[2], a[3], "--dry-run" in a)
    elif len(a) == 3 and a[0] == "check":
        cmd_check(a[1], a[2])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
