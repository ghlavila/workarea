
# Git Worktrees: Recommended Workflow with Jira-Created Branches

This guide shows a **clean, repeatable workflow** for working on multiple Jira tickets in parallel using `git worktree`. It assumes Jira (or your automation) **already creates remote branches** for tickets. A final section covers creating a **brand-new worktree/branch** when there is no Jira ticket yet.

---

## Prerequisites

- Git 2.38+ recommended (worktrees exist earlier, but newer Git has better UX).
- A clone of your repository, e.g. `~/projects/app`.
- Jira automation that creates branches (e.g. `origin/feature/JIRA-1234-summary`).

---

## Why worktrees? (30-second refresher)

Worktrees let you keep **multiple branches checked out simultaneously**, each in its **own folder**, while sharing a single `.git` object store. That means:
- No constant `git switch` / stashing.
- You can keep **4–5 tickets open** at once.
- Open each ticket in its own editor window / terminal and **pause/resume** freely.

Example layout:
```
~/projects/
├── app/               # main clone (main branch or whatever)
├── app-JIRA-1234/     # worktree for feature/JIRA-1234
├── app-JIRA-1357/     # worktree for bug/JIRA-1357
└── app-JIRA-2468/     # worktree for feature/JIRA-2468
```

---

## Golden Rules (TL;DR)

1. **Always `git fetch origin` first** so your local has the Jira-created branches.
2. When adding a worktree to a **remote branch**, use **`-b <local-branch>`** to set up **tracking** and avoid a detached HEAD.
3. Remove finished worktrees with `git worktree remove <path>` (and occasionally `git worktree prune`).

---

## Standard Workflow: Jira-Created Ticket Branch

> Example ticket: `feature/JIRA-1234-improve-logging`

### 1) Fetch remote branches
```bash
cd ~/projects/app
git fetch origin --prune
```

### 2) Create a worktree **with a tracking local branch**
> This checks out the **remote** branch into a new directory and creates a **tracking local branch** with the same name.
```bash
git worktree add -b feature/JIRA-1234-improve-logging   ../app-JIRA-1234   origin/feature/JIRA-1234-improve-logging
```

### 3) Do the work in the worktree
```bash
cd ../app-JIRA-1234
# ...edit files...
git add -A
git commit -m "JIRA-1234: implement structured logging"
```

### 4) Push like normal (tracking is set)
```bash
git push           # pushes to origin/feature/JIRA-1234-improve-logging
git pull --rebase  # keeps your branch current
```

>Rule of thumb:
>Only use --rebase on commits you haven’t shared yet.

```
git log origin/feature/JIRA-1234..HEAD
```
>If it shows only your own unpushed commits, you’re safe.


### 5) Open / update PR your usual way
- Use your code host UI or `gh pr create`, etc.

### 6) When merged or abandoned, clean up
```bash
cd ~/projects/app
git worktree remove ../app-JIRA-1234
# (Optional) remove remote branch if merged:
git push origin --delete feature/JIRA-1234-improve-logging
# (Optional) clean stale metadata:
git worktree prune
```

---

## Working on Multiple Tickets in Parallel

Create one worktree per ticket:
```bash
# JIRA-1234
git worktree add -b feature/JIRA-1234-improve-logging   ../app-JIRA-1234   origin/feature/JIRA-1234-improve-logging

# JIRA-1357
git worktree add -b bug/JIRA-1357-fix-timeout   ../app-JIRA-1357   origin/bug/JIRA-1357-fix-timeout

# JIRA-2468
git worktree add -b feature/JIRA-2468-authz   ../app-JIRA-2468   origin/feature/JIRA-2468-authz
```

Now you can independently `cd` into any folder and work there without stashing or switching.

---

## Common Checks & Troubleshooting

### Am I tracking the remote?
```bash
git branch -vv
# * feature/JIRA-1234-improve-logging  abc123 [origin/feature/JIRA-1234-improve-logging] Commit msg
```
If you **don’t** see the `[origin/...]` part, set tracking manually:
```bash
git branch --set-upstream-to=origin/feature/JIRA-1234-improve-logging
```

### Oops, I ended up on a detached HEAD
You probably ran `git worktree add ../path origin/branch` **without** `-b` *and* your Git placed you in a detached state. Two options:
- Keep going and push explicitly:
  ```bash
  git push origin HEAD:feature/JIRA-1234-improve-logging
  ```
- Or create a tracking local branch now:
  ```bash
  git switch -c feature/JIRA-1234-improve-logging --track origin/feature/JIRA-1234-improve-logging
  ```

### Clean up stale entries
If a worktree directory was deleted manually:
```bash
git worktree prune
```

---

## Optional Quality-of-Life Aliases

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
# Create a worktree for a Jira ticket branch that already exists remotely.
# Usage: jw <JIRA-ID> [slug]
# Example: jw 1234 improve-logging
jw() {
  local id="$1"; shift
  local slug="${1:-work}"; shift || true
  local remote_branch="feature/JIRA-${id}-${slug}"
  local dir="../app-JIRA-${id}"
  git fetch origin --prune &&
  git worktree add -b "${remote_branch}" "${dir}" "origin/${remote_branch}" &&
  cd "${dir}" || return
}

# List and remove helpers
alias jwls='git worktree list'
jwrm() { git worktree remove "$1"; }  # usage: jwrm ../app-JIRA-1234
```

Adjust the `feature/` or `bug/` prefixes to match your team’s naming.

---

## Creating a **Brand-New** Worktree & Branch (No Jira Ticket Yet)

Sometimes you need a sandbox or spike before a Jira ticket exists.

### Option A: Base off `origin/main` (or your default branch)
```bash
cd ~/projects/app
git fetch origin --prune

git worktree add -b sandbox/spike-feature-x   ../app-spike-feature-x   origin/main

cd ../app-spike-feature-x
# ...experiment...
git add -A
git commit -m "Spike: prototype for feature X"
git push -u origin sandbox/spike-feature-x   # create remote branch & set upstream
```

### Option B: Start from a specific commit or tag
```bash
git worktree add -b sandbox/try-old-commit   ../app-try-old-commit   1a2b3c4d
```

> Later, when a Jira ticket is created, you can **rename** the branch or **merge** into the official ticket branch, e.g.:
```bash
# From within the worktree
git branch -m feature/JIRA-9999-feature-x
git push -u origin feature/JIRA-9999-feature-x
# (Optionally delete the old remote if you pushed it)
git push origin --delete sandbox/spike-feature-x
```

---

## Quick Reference (Cheat Sheet)

```bash
# Create Jira worktree (remote exists) with tracking:
git fetch origin --prune
git worktree add -b feature/JIRA-1234 ../app-JIRA-1234 origin/feature/JIRA-1234

# Normal work:
cd ../app-JIRA-1234
git add -A && git commit -m "JIRA-1234: ..."
git pull --rebase
git push

# Remove when done:
cd ~/projects/app
git worktree remove ../app-JIRA-1234
git worktree prune   # optional
```

---

## FAQ

**Q: Can two worktrees use the *same* branch?**  
A: Not simultaneously. Git prevents checking out the same branch in two places at once. Use `--detach` if you truly need a second view.

**Q: Is disk use heavy with many worktrees?**  
A: No—each worktree stores only the **working files**. All Git history/objects are shared.

**Q: Can I use worktrees with monorepos and big builds?**  
A: Yes. Many teams keep dedicated worktrees for long-running feature branches to avoid expensive switches and rebuilds.

---

