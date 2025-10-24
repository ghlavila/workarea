cd ~/data/git/data_processing
git worktree remove ../tickets/OPS-364-CR           # remove local worktree folder
git branch -d OPS-364-CR                            # remove local branch (safe if merged)
git push origin --delete OPS-364-CR                 # remove branch from GitHub (optional)
git fetch origin --prune                            # clean up stale remote refs

