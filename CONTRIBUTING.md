# Contributing

Start a branch and open a pull request against `main`. Direct pushes, force
pushes, and deleting `main` are disabled, including for administrators.

Every PR must pass **Repository checks**, **tvOS build and tests**, and
**Owner approval**. PRs by `yssf-c` automatically satisfy the approval check.
Other authors need an approval from `yssf-c` on the current head commit; pushing
another commit, dismissing the approval, or requesting changes invalidates it.
Comments by themselves do not invalidate a review. Resolve review conversations
before merging and keep the branch up to date with `main`.

The approval workflow executes only trusted default-branch code and reads review
state from GitHub. A separate, unprivileged review event wakes it up. It also
reconciles twice an hour and can be rerun with Actions → Owner approval policy →
Run workflow. It never checks out a contributor's code with a write token.
CODEOWNERS requests Youssef's review but is not used as a native required review,
which would also require a second person to approve his own PRs.

## Local validation

```sh
python3 Tools/Release/validate.py
node --test .github/scripts/owner-approval.test.cjs
node --test Tools/Anatomy/model.test.mjs
xcodebuild test -project 'Gallery Glow.xcodeproj' -scheme 'Gallery Glow' \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-
```

Use a current Xcode with the tvOS simulator installed. CI also compiles Release
for Apple TV hardware so debug-only fixtures cannot hide release compilation
errors. Purchase and appearance tests exercise the real remote-driven UI;
StoreKit integration tests cover purchases, Ask to Buy, historical ownership,
relaunch, and refunds. Live App Store sandbox verification remains a release step.

CI pins Xcode and tvOS 26.2. The runner's 26.5 StoreKit daemon rejected test
configuration with `SKInternalErrorDomain Code=3` and `notEntitled`, matching the
[Apple-tracked simulator issue](https://developer.apple.com/forums/thread/826971).
The full StoreKit suite stays enabled. Revalidate it before updating the runtime
pin; local release validation also runs on tvOS 27. CI opens Simulator explicitly
so remote focus and accessibility have an active display.

No CI suite can guarantee that changes never break behavior. Include screenshots
for visual work and reproduce the affected flow on Apple TV before release.
