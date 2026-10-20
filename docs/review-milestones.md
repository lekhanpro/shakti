# Four review milestones

These are four feature-based pull requests prepared now, with real commit dates.
They are not a backdated history of completed weekly work. Existing baseline
features remain in every checkpoint; demonstrations and review results retain their
actual dates. The academic phases in community-review/README.md remain authoritative.

| Review | Branch | Changes | Review gate |
|---|---|---|---|
| Week 1 | review/week-1-foundation | Accurate README, full plan-to-source/test audit and review/restore instructions | Scope, requirements, explicit unresolved deviations |
| Week 2 | review/week-2-emergency | Escort async/PIN lifecycle fix, settings-failure SOS fallback, completed cancellation, honest SMS handoff UI and regressions | Flutter analysis/tests/coverage; controlled device checks |
| Week 3 | review/week-3-experience | Original sections retained, globe/local textures, modern landing interactions, Realtime refresh migration/hook/tests | Web tests/build, SQL checks, interaction/accessibility review |
| Week 4 | review/week-4-release | Reusable full verification, Android debug/native builds, database checks, browser smoke, gated testing prerelease and signed APK/AAB delivery workflow | Every automated gate, then separate hardware/signing evidence |

## Dependencies and merge order

The PRs are stacked: Week 1 targets main; each later PR targets the preceding
review branch. The Week 4 head contains the combined project and runs the expanded
verification workflow. Earlier PR checks only establish their own checkpoint.

Review and merge in order. Prefer merge commits so the original commit identities
remain available. After each merge, retarget the next PR to main if necessary and
run its checks again. Do not reset or force-push main.

## Inspect an older weekly state

From an existing clone, fetch the branches and use an isolated worktree:

```bash
git fetch origin
git worktree add --detach ../shakti-week-1 origin/review/week-1-foundation
git worktree add --detach ../shakti-week-2 origin/review/week-2-emergency
git worktree add --detach ../shakti-week-3 origin/review/week-3-experience
git worktree add --detach ../shakti-week-4 origin/review/week-4-release
```

Each worktree needs fresh dependency installation and separately supplied local
configuration. Never include signing credentials or identifiable test data in
review snapshots. Record the exact commit SHA in each actual review.

For source snapshot ZIPs, the existing scripts/review-checkpoint.ps1 remains
available; see community-review/README.md for its limits and usage.

## Undo reviewed changes

Unmerged PRs can be closed without changing main. After merge, create a new
revert PR. With merge commits, use GitHub's Revert action or
`git revert -m 1 ACTUAL_MERGE_SHA` in a new branch. Revert dependent milestones
in reverse order (4, 3, 2, 1), then run verification. Git reverts do not automatically
roll back deployed databases or uninstall distributed APKs; review those operations
separately and preserve incident/evidence data.

## Evidence to bring to each review

Record planned/demoed/tested features, failing and not-run checks, actual test logs,
device/OS/network state, reviewer comments, individual contributions and the commit
being demonstrated. Do not mark a scheduled review, Play publication or real SMS
receipt complete from a passing automated check.
