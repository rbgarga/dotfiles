---
name: gitlab-review
description: Post, check or edit code review comments on GitLab merge requests (inline or general draft notes, published notes) so that every inline comment is attached to the right diff line. Use whenever review findings go to a GitLab MR, e.g. after /code-review with "post as a draft MR review", or when fixing comments already posted.
---

# gitlab-review — review comments on GitLab MRs

Use this for any review comment that goes to a GitLab merge request:
posting findings as draft notes, checking that they are attached to the
right lines, and editing drafts or published notes. All API calls go
through `glab api`, which is logged in to gitlab.netgate.com.

## Writing the comments

* Put code in backticks: function, variable and macro names, file paths
  (`src/foo.c:123`), expressions and code snippets.
* One finding per note. Bold one-sentence summary first, then the
  failure scenario or reasoning.
* Argue each point on its technical merits. Never cite the user's own
  configuration or instructions (CLAUDE.md, skills, memory) as the
  reason for a comment; the MR author doesn't know or care about them.
* For stacked MRs, review only each MR's own diff against its target
  branch (the previous MR in the stack), and post each finding on the MR
  whose diff contains the line.

## Posting

Write the notes to a JSON file and post them with the script. It finds
each line in the MR diff and builds the position GitLab needs:

```
S=~/.claude/skills/gitlab-review/scripts/gl_notes.py
python3 $S post <group/project> <mr_iid> notes.json --dry-run   # positions only
python3 $S post <group/project> <mr_iid> notes.json             # create drafts
python3 $S check <group/project> <mr_iid>                       # verify
```

notes.json entries (line numbers are on the MR head side):

```
{"file": "src/foo.c", "line": 123, "body": "..."}                   one line
{"file": "src/foo.c", "line": 120, "end_line": 126, "body": "..."}  a block
{"file": "src/foo.c", "old_line": 98, "body": "..."}                a removed line
{"body": "..."}                                                     general note
```

Always run `check` after posting. It prints each draft with the source
line it is attached to and flags positions that GitLab can't show
inline. Read the attached lines: a note must sit on the code it talks
about. Fix anything that doesn't before telling the user the review is
posted.

## Position rules (what the script does, and what to check by hand)

* GitLab shows a note below the line it is attached to. Attach it to the
  code it discusses, not to a neighbouring (e.g. blank) line. Line
  numbers in review findings can be off by one, so check the source line.
  For a block, use a multi-line note (`line` + `end_line`).
* The position type must match the line in the diff: an added line takes
  `new_line` only, an unchanged context line takes both `old_line` and
  `new_line`, a removed line takes `old_line` only. GitLab accepts a
  draft with a wrong position but does not show it inline.
* A multi-line note has `position.line_range` with `start` and `end`
  (`line_code`, `type` `new` for added lines or null for context lines,
  line numbers), and `new_line` set to the end line. A `line_code` is
  `<sha1(path)>_<old>_<new>`; for an added line `<old>` is the old-side
  line counter after any removed lines.
* A line outside the diff can't carry an inline note. Post a general note
  that names the file and line (the script does this automatically).
* Every inline draft must have a non-null `line_code`. A null one is not
  attached to its line.

## Editing

* Draft notes: `PUT projects/:id/merge_requests/:iid/draft_notes/:note_id`
  resets the position unless the full position is sent again, and it never
  recomputes `line_code`. To change only the text, send `note` together
  with the unchanged `position`. To change the position, delete the draft
  and post it again.
* Published notes: `PUT projects/:id/merge_requests/:iid/discussions/:discussion_id/notes/:note_id`
  with `body`. The position of a published note can't be changed.
* Don't publish the review (`draft_notes/bulk_publish`) unless the user
  asks; draft reviews are for the user to check and submit.
