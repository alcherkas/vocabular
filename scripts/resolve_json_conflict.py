#!/usr/bin/env python3
"""
Resolve git merge conflicts in JSON vocabulary staging files.
Strategy: extract 'ours' and 'theirs' complete JSON arrays, then merge by
keeping the most pipeline-advanced status per term (approved > relations-added > enriched > stub).
"""
import json, re, sys

STATUS_ORDER = {'stub': 0, 'enriched': 1, 'relations-added': 2, 'approved': 3}

def split_conflict(raw):
    """Return (ours_text, theirs_text, has_conflict)."""
    ours, theirs = [], []
    state = 'shared'  # shared | ours | theirs
    has_conflict = False
    for line in raw.split('\n'):
        if line.startswith('<<<<<<<'):
            has_conflict = True
            state = 'ours'
        elif line.startswith('=======') and state == 'ours':
            state = 'theirs'
        elif line.startswith('>>>>>>>') and state == 'theirs':
            state = 'shared'
        elif state == 'shared':
            ours.append(line)
            theirs.append(line)
        elif state == 'ours':
            ours.append(line)
        else:  # theirs
            theirs.append(line)
    return '\n'.join(ours), '\n'.join(theirs), has_conflict

def try_parse(text):
    # Strip trailing commas before ] or } which can appear when conflict splits an array
    text = re.sub(r',\s*([}\]])', r'\1', text)
    return json.loads(text)

def resolve_file(filename):
    with open(filename, encoding='utf-8') as f:
        raw = f.read()

    ours_text, theirs_text, has_conflict = split_conflict(raw)
    if not has_conflict:
        return False

    try:
        ours = try_parse(ours_text)
    except json.JSONDecodeError as e:
        print(f"ERROR parsing ours of {filename}: {e}", file=sys.stderr)
        return False

    try:
        theirs = try_parse(theirs_text)
    except json.JSONDecodeError as e:
        print(f"ERROR parsing theirs of {filename}: {e}", file=sys.stderr)
        return False

    # Merge: index by normalised term, keep most advanced status entry
    merged = {}
    for entry in ours + theirs:
        key = entry.get('term', '').lower().strip()
        cur = merged.get(key)
        if cur is None:
            merged[key] = entry
        else:
            cur_rank = STATUS_ORDER.get(cur.get('status', ''), 0)
            new_rank = STATUS_ORDER.get(entry.get('status', ''), 0)
            if new_rank > cur_rank:
                merged[key] = entry

    result = list(merged.values())
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
        f.write('\n')

    by_s = {}
    for w in result:
        s = w.get('status', '?')
        by_s[s] = by_s.get(s, 0) + 1
    print(f"{filename}: {len(result)} entries — {dict(sorted(by_s.items()))}")
    return True

if __name__ == '__main__':
    for fname in sys.argv[1:]:
        resolve_file(fname)
