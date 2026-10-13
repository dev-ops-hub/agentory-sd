---
name: git-workflow
description: Use when resolving a messy git history, recovering lost work, debugging with bisect, isolating work in a worktree, or writing a PR — covers rebase, bisect, worktrees, reflog recovery and safe force-pushing
---

# Git Workflow

## Overview

Reference for the git operations that come up constantly in day-to-day engineering work but are easy to get wrong under pressure: interactive rebase, bisection, worktrees, reflog recovery, and safe force-pushing. Applies to any engineering role — backend, frontend, or platform.

## When to Use

- Cleaning up commit history before a PR (squash, reorder, reword)
- Finding which commit introduced a regression (bisect)
- Working on two things at once without stashing (worktrees)
- Recovering a commit or branch you think you lost (reflog)
- Updating a branch after a force-push without clobbering a collaborator's work

## Interactive Rebase

```bash
git rebase -i HEAD~5          # last 5 commits
git rebase -i main            # everything since diverging from main
```

| Command | Effect |
|---|---|
| `pick` | keep commit as-is |
| `reword` | keep changes, edit message |
| `edit` | pause here to amend |
| `squash` | combine into previous commit, merge messages |
| `fixup` | combine into previous commit, discard this message |
| `drop` | remove commit entirely |

**Rule:** never rebase a branch other people have already pulled from, unless you've agreed on it — rebasing rewrites history and force-pushing it under someone else breaks their local branch.

## Safe Force-Push

```bash
git push --force-with-lease
```

Refuses to push if the remote has commits you haven't seen (i.e., someone else pushed since your last fetch). Plain `--force` has no such check and can silently discard a collaborator's work. Default to `--force-with-lease`; never plain `--force` on a shared branch.

## Bisect

Find the commit that introduced a regression by binary search:

```bash
git bisect start
git bisect bad                 # current commit is broken
git bisect good v1.2.0          # this older tag/commit was fine
# git checks out a midpoint; test it, then:
git bisect good   # or
git bisect bad
# repeat until git identifies the exact commit
git bisect reset   # when done, return to original HEAD
```

Automate the "test it" step when the check is scriptable:

```bash
git bisect start HEAD v1.2.0
git bisect run npm test        # or any command that exits 0 (good) / nonzero (bad)
```

## Worktrees

Work on two branches simultaneously without stashing — each worktree is a separate checkout sharing the same `.git`:

```bash
git worktree add ../myproject-hotfix hotfix-branch
cd ../myproject-hotfix          # independent working directory, own node_modules etc.
git worktree list               # see all worktrees
git worktree remove ../myproject-hotfix   # when done
```

Use when: a hotfix is needed while mid-feature, or when running a long test suite on one branch while continuing to work on another.

## Reflog Recovery

`git reflog` records every HEAD movement — commits, resets, rebases, checkouts — even after a branch is deleted or a reset discards commits:

```bash
git reflog                       # find the lost commit's SHA
git checkout <sha>                # inspect it
git branch recovered-work <sha>   # or recover it as a new branch
```

Reflog entries expire (default 90 days for reachable, 30 for unreachable) but cover almost every "I think I just lost my work" situation before that.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `git push --force` on a shared branch | Use `--force-with-lease` |
| Rebasing a branch others have pulled | Merge instead, or coordinate the rewrite first |
| Panic after `git reset --hard` | Check `git reflog` before assuming work is gone |
| Bisecting manually one commit at a time | Use `git bisect run <script>` when the check is scriptable |
| Stashing to switch branches mid-task | Use a worktree instead — no stash to forget about |

## Quick Reference

| Need | Command |
|---|---|
| Clean up commit history | `git rebase -i HEAD~N` |
| Push after rebase, shared branch | `git push --force-with-lease` |
| Find regression commit | `git bisect start` / `git bisect run <cmd>` |
| Parallel branches, no stash | `git worktree add <path> <branch>` |
| Recover lost commit | `git reflog` → `git branch <name> <sha>` |
