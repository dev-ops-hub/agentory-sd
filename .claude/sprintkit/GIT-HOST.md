# Git host: GitHub or GitLab

Sprintkit skills that open, read or merge pull requests (PRs on GitHub, merge requests or MRs on GitLab) never hard-code `gh`. They resolve the host once, then use the command for it from the table below. This file is the single place that knows the difference.

## Resolve the host (once per run, before any PR work)

1. If `agent-config/git.json` exists, read `provider` (`auto`, `github` or `gitlab`) and the optional `host`. Ignore every key that starts with `_` (those are comments).
2. `provider` missing or `auto`: take the host name from `git remote get-url origin`. `github.com` means `github`; `gitlab.com` or a name containing `gitlab` means `gitlab`. Anything else (a self-hosted server with an unrevealing name): stop with one line asking the user to set `provider` in `agent-config/git.json`.
3. `host` set: use it as the server and compare it with the host in `origin`. If they differ, stop and say so. `host` unset: the default (`github.com` or `gitlab.com`).
4. For a non-default host, export `GH_HOST=<host>` (GitHub) or `GITLAB_HOST=<host>` (GitLab) for every command below.
5. Preflight: the CLI is installed (`gh` or `glab`) and logged in (`gh auth status` or `glab auth status`, with `--hostname <host>` for a non-default host). If not, stop before any sprint work with one line naming the missing step.

Jira keys in branch and PR/MR names are added only when `agent-config/git.json` exists. With no file, the host is still auto-detected for the commands below, but nothing Jira-related is added.

## Commands

`N` is the PR number (GitHub) or the MR `iid` (GitLab). `B` is the source branch and `T` the target branch. On GitLab, `glab api` fills `:id` with the current project.

| Action | GitHub (`gh`) | GitLab (`glab`) |
|---|---|---|
| Find the open PR/MR for branch `B` into `T` (prints N, or nothing) | `gh pr list --head B --base T --state open --json number --jq '.[0].number'` | `glab mr list --source-branch B --target-branch T -F json --jq '.[0].iid'` |
| Find open PRs/MRs whose title mentions `Sprint <N>` | `gh pr list --search "Sprint <N>" --state open --json number,title,reviewDecision` | `glab mr list --search "Sprint <N>" -F json --jq '[.[] \| {iid, title}]'` |
| Open a draft PR/MR | `gh pr create --base T --head B --draft --title "<title>" --body "<body>"` | `glab mr create --source-branch B --target-branch T --draft --title "<title>" --description "<body>" --yes` |
| Is it approved? | `gh pr view N --json reviewDecision --jq .reviewDecision` is `APPROVED` | `glab api "projects/:id/merge_requests/N/approvals" --jq .approved` is `true` |
| Author of the PR/MR | `gh pr view N --json author --jq .author.login` | `glab mr view N -F json --jq .author.username` |
| Current user | `gh api user --jq .login` | `glab api user --jq .username` |
| Latest review by the current user (author, state, body) | `gh pr view N --json reviews --jq '.reviews[-1] \| {author: .author.login, state, body}'` | `glab api "projects/:id/merge_requests/N/notes?order_by=created_at&sort=desc&per_page=100" \| jq --arg me "$ME" '[.[] \| select(.author.username==$me)][0] \| {author: .author.username, body}'` (a note has no review state) |
| Wait for CI | `gh pr checks N --watch` (non-zero exit means failed) | Poll `glab api "projects/:id/merge_requests/N" --jq .head_pipeline.status` every 30 s: `success` is green; `failed` or `canceled` is a failure; `null` means no CI configured and counts as green |
| Squash-merge | `gh pr merge N --squash --body "<message>"` | `glab mr merge N --squash --squash-message "<message>" --yes` |

The merge honours the PR/MR's own target branch on both hosts, so no extra flag is needed for epic mode.

### More actions (review, implement, loop, sync)

| Action | GitHub (`gh`) | GitLab (`glab`) |
|---|---|---|
| Open a PR/MR targeting `T` | `gh pr create --base T --title "<title>" --body "<body>"` | `glab mr create --target-branch T --title "<title>" --description "<body>" --yes` |
| Find the PR/MR for the current branch | `gh pr view` | `glab mr view` |
| Read title, description, author | `gh pr view N --json title,body,author` | `glab mr view N -F json --jq '{title, description, author: .author.username}'` |
| Read comments and reviews | `gh pr view N --comments` or `--json comments,reviews` | `glab mr view N --comments` |
| Read commits | `gh pr view N --json commits` | `glab api "projects/:id/merge_requests/N/commits"` |
| Read the diff (against the real target branch) | `gh pr diff N` | `glab mr diff N` |
| Latest review decision and reviews (loop verdict check) | `gh pr view N --json reviewDecision,latestReviews` | `glab api "projects/:id/merge_requests/N/approvals" --jq .approved` plus the notes call above |
| Post a comment | `gh pr comment N --body "<text>"` | `glab mr note create N -m "<text>"` |
| Review: approve | `gh pr review N --approve --body "<body>"` | `glab mr approve N`, then `glab mr note create N -m "<body>"` (approving does not take a body) |
| Review: comments only | `gh pr review N --comment --body "<body>"` | `glab mr note create N -m "<body>"` |
| Review: request changes | `gh pr review N --request-changes --body "<body>"` | `glab mr note create N -m "<body>"`; if the MR was approved, also `glab mr revoke N`. `glab` has no request-changes state, so "not approved" is the signal. |
| Inline comment on a diff line | `gh api repos/:owner/:repo/pulls/N/comments ...` | Post a normal note that names `file:line`; inline positions need diff SHAs and are not worth the risk |
| List merged PRs/MRs | `gh pr list --state merged --limit 10 --json number,title,mergedAt,headRefName` | `glab mr list --merged --per-page 10 -F json` |
| List or read issues | `gh issue list --limit 30 --json number,title,body,labels,state`, `gh issue view N --comments` | `glab issue list -O json --per-page 30`, `glab issue view N --comments` |

## Notes

- Verdict signal: on GitHub it is `reviewDecision`. On GitLab it is the `approved` flag. Anything not approved means another fix cycle; no extra marker is needed for that.
- Approve failing on your own MR (GitLab): if `glab mr approve` exits non-zero with a message about the author or your own merge request, treat it as the self-approval case and post the body as a note ending with the self-approval marker.
- Self-approval: on GitHub an author cannot approve their own PR, so `sprintkit-review` leaves a `COMMENTED` review with the self-approval marker. On GitLab, self-approval depends on the instance's settings; if `approved` is `true`, the normal path applies. If it is `false`, the marker path applies, using the note by the current user that carries the marker.
- GitLab squash: the project must allow squash on merge. If `glab mr merge` refuses, report that and let the user change the project setting; do not retry without `--squash`.
- Wording: say "PR" for GitHub and "MR" for GitLab in user-facing output, and print GitLab IDs as `!N`.
