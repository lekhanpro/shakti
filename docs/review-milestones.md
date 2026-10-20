# One PR with four review checkpoints

This is one combined pull request with four feature-based checkpoint commits prepared now, with real commit dates.
They are not a backdated history of completed weekly work. Existing baseline
features remain in every checkpoint; demonstrations and review results retain their
actual dates. The academic phases in community-review/README.md remain authoritative.

| Review | Branch | Changes | Review gate |
|---|---|---|---|
| Week 1 | review/week-1-foundation | Accurate README, full plan-to-source/test audit and review/restore instructions | Scope, requirements, explicit unresolved deviations |
| Week 2 | review/week-2-emergency | Escort async/PIN lifecycle fix, settings-failure SOS fallback, completed cancellation, honest SMS handoff UI and regressions | Flutter analysis/tests/coverage; controlled device checks |
| Week 3 | review/week-3-experience | Original sections retained, globe/local textures, modern landing interactions, Realtime refresh migration/hook/tests | Web tests/build, SQL checks, interaction/accessibility review |
| Week 4 | review/week-4-release | Reusable full verification, Android debug/native builds, database checks, browser smoke, gated testing prerelease and signed APK/AAB delivery workflow | Every automated gate, then separate hardware/signing evidence |

## Review and merge

The single PR targets main from review/week-4-release. Review the four checkpoint
commits separately, then review the combined diff and the checks at the final head.
Use a merge commit when merging the PR; do not squash away the checkpoint identities.
Additional integration or CI-fix commits may follow the four checkpoints.

| State | Exact commit |
|---|---|
| Before all changes | 03b76190708bc21259c737ac24325603435095eb |
| After Week 1 checkpoint | 4336d57e486688e189d771cf1c8a2f69cc33093d |
| After Week 2 checkpoint | fb5e7c42e765c87ab76265892caee35a17906416 |
| After Week 3 checkpoint | 9e75b0fcf2681e73bf8cdfb612a0625839c9623d |
| After Week 4 checkpoint | 6ca0f030042865d25d83f8d9089a54904db8d51c |

The saved week branches are convenient references. Exact commit SHAs remain the
authoritative snapshots if a branch later moves. The final PR head runs the
combined verification suite; historic checkpoint commits have only the tests
available at that stage. No main-branch reset or force-push is needed.

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

Closing the unmerged PR leaves main unchanged. After merge, create a new
revert PR. To undo the entire PR merged with a merge commit, use GitHub's Revert
action or `git revert -m 1 ACTUAL_MERGE_SHA` in a new branch. To undo only later
checkpoints, revert their commits in reverse order, including any later integration
fixes, then run verification. To demonstrate an earlier week without undoing the
current app, prefer an isolated worktree at the exact SHA. Git reverts do not automatically
roll back deployed databases or uninstall distributed APKs; review those operations
separately and preserve incident/evidence data.

## Evidence to bring to each review

Record planned/demoed/tested features, failing and not-run checks, actual test logs,
device/OS/network state, reviewer comments, individual contributions and the commit
being demonstrated. Do not mark a scheduled review, Play publication or real SMS
receipt complete from a passing automated check.
