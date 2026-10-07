---
name: dead-code
description: "Find dead code in any repo — unreferenced functions, types, constants, over-wide exports and orphan files — then optionally ship the removal as a GitLab MR. Language-agnostic: works on Rust, TypeScript/JS, Python, Go, shell, Terraform/HCL, KCL and jsonnet in one pass, and layers on cargo/knip/vulture/shellcheck when they happen to be installed. Triggers: 'find dead code', 'what's unused', 'unused functions', 'unreferenced code', 'is this still used', 'dead code MR', 'clean up unused code', 'orphan files', 'unused exports', 'can I delete this'."
argument-hint: "Optional: a path to scan, and/or 'mr' to go straight to a removal MR"
---

# dead-code

Finds code nothing references, ranks it by how sure that claim is, and — on request — ships the removal as an MR.

The engine is a repo-wide reference graph, not a per-language linter, so it works the same on a Rust crate, a jsonnet dashboard tree and a directory of shell scripts. Native tools (`cargo`, `knip`, `vulture`, `shellcheck`) are used as a *second opinion* when present, never as a prerequisite.

## Files

- `scripts/deadcode-scan.sh` — entrypoint. Runs the generic analysis, then whichever native tools exist. Read-only.
- `scripts/deadcode-analyze.py` — the reference-graph engine. Also usable directly; `--json` for machine-readable output.
- `references/limits.md` — what the engine cannot see, and the false-positive classes to check by hand.

## How it decides something is dead

Two passes over every tracked text file (`git ls-files`, so `.gitignore` and hidden dirs are both handled):

1. Extract symbol **definitions** per language.
2. Count **references** to those names everywhere, split three ways:
   - **hard** — in code, outside string literals
   - **soft** — in config/docs, or inside a string literal (how dynamic dispatch looks)
   - **own-file** — inside the defining file

Dead = zero hard refs *and* zero own-file uses. Soft refs do not clear a finding, they downgrade it.

## Confidence tiers — these drive what you're allowed to do

| Tier | Means | Action |
|---|---|---|
| **high** | No reference of any kind, anywhere in the repo. | Safe to propose for deletion. |
| **medium** | Either public API with no in-repo caller (an external consumer would be invisible from here), or an orphan file, or an export used only inside its own file. | Read it and decide. Over-wide exports usually want narrowed visibility, **not** deletion. |
| **low** | The name shows up in strings/config/templates, or it is a method reachable by dynamic dispatch. | Assume live unless you can prove otherwise. |

Findings come in four kinds: `dead-symbol`, `unused-export` (narrow the visibility, don't delete), `orphan-file`, and `orphan-dir` — a directory-addressed unit such as a Terraform module or KCL package that nothing sources. `orphan-dir` exists because per-file detection cannot see these: every file inside is `main.tf`/`outputs.tf`, so the filename says nothing.

**Only `high` findings may go into an automatic removal MR.** Medium and low need a human read.

## Workflow

### 0. Check the tree is current — do this first

"Nothing references X" is a claim about the checkout in front of you, and worktree
containers go stale silently. The scan prints HEAD, its date, the behind-count and
the dirty-file count to stderr, and warns when either is non-zero. **Read that line
before reading the findings.** `--fetch` refreshes remote refs first.

If the tree is behind, scan a detached worktree at the remote instead of pulling —
the shared checkout is usually dirty and on someone's branch:

```bash
git worktree add --detach /tmp/scan origin/master
```

Sibling repos matter too: a "no cross-repo consumer" check run against a stale
sibling proves nothing. `git fetch` + `git grep <name> origin/master` checks a
sibling without touching its checkout.

### 1. Scan

```bash
scripts/deadcode-scan.sh [PATH] --min-confidence high
```

Useful flags: `--lang rust`, `--limit N`, `--json`, `--ignore-test-refs` (surface
code only its own tests use), `--no-allowlist` (also consider suppressed entrypoint
names like `main`/`run`/`render`).

`--path PREFIX` and `--exclude PREFIX` (both repeatable) scope **what is reported**;
the whole tree is always indexed for references, so scoping can only narrow the
findings, never invent them. Always `--exclude` vendored trees — they are not your
code and they swamp the output. In `configs`:

```bash
scripts/deadcode-scan.sh . --lang python \
  --exclude collections/ansible_collections --exclude opt/terraform
```

Report the tiers with counts, then the findings as `file:line — symbol — why`. Say plainly when a tier is empty.

### 2. Triage — required before any deletion

Every finding is a claim to verify, not a fact. For each candidate you intend to remove:

- **Read the definition and its file.** A three-line function and a 300-line subsystem are not the same decision.
- **Re-grep the name yourself** including hidden dirs: `rg --hidden -n '\bNAME\b'`. The engine is regex-based; confirm it.
- **Check the dynamic-usage surfaces the engine flags as soft**: CI YAML, Helm/jsonnet templates, `getattr`/reflection, CLI dispatch tables, feature-gated code (`#[cfg(...)]`, `if TYPE_CHECKING`).
- **Ask whether it is a published interface.** A `pub fn` in a library crate, an exported symbol in a package others import, a Terraform `variable` consumed by a downstream module — no in-repo caller proves nothing.

Drop anything you cannot confirm. A wrong deletion costs far more than a missed one.

### 3. Removal MR — only when asked

Follow the user's standing rules: **work in a worktree, never the shared checkout** (`/worktree`), and use conventional commits.

1. `/worktree` to get an isolated branch — e.g. `chore/dead-code-<scope>`.
2. Delete only verified **high**-confidence findings. Remove imports/uses that *your* deletion orphaned, and nothing else — no adjacent cleanup, no reformatting.
3. **Check that the gate actually executes the code you changed — before trusting it.**
   A passing pipeline is not coverage. In `configs`, the KCL gate is `kcl lint` plus
   a contract-test file; the lint only resolves imports, and every test in that file
   ran single-app mode, so *nothing* executed `render_all_from_fleet` — the live
   entry in the very file being edited. The deletion was safe, but the gate would
   not have caught it if it hadn't been.

   When the gate doesn't reach your change, do one of these before pushing:
   - **Render/execute before and after and diff the output.** Strongest check for a
     pure deletion — byte-identical output over real inputs proves behaviour is
     unchanged. (6 fleets, 5169 lines of YAML, identical.)
   - **Add the missing test**, then *mutate the code to confirm the test fails*. A
     test that passes against a broken implementation is worse than no test.
   - Note that CI comments go stale: that repo's CI file documented `kcl run` as
     broken on master, but it had since been fixed. Re-check, don't inherit.

4. **Verify the build in the affected crate/package before pushing.** Non-negotiable, per language:
   - Rust: `cargo fmt --check && cargo check --tests && cargo test` — `check`/`test` do **not** cover formatting, and CI fails the whole pipeline on an fmt diff.
   - TS: the project's typecheck + test scripts.
   - Python: the test suite; import the touched modules.
   - Shell/HCL/KCL/jsonnet: whatever renders or lints it in CI.
5. **Re-scan the branch, and expect it to surface something new.** Deleting the
   outermost layer of a dead cluster exposes the next one — `render_list` → `render`
   → `_helm_rootsync` was three deep, and only the first was visible initially.
   Keep re-scanning until a pass adds nothing.

   Treat each newly exposed layer as its own decision, not as more of the same
   deletion. `_helm_rootsync` turned out to be an unreachable *feature* — no app
   could render a helm-sourced RootSync because the live entry only dispatched to
   `_git_rootsync`. Restoring the dispatch was the right fix; deleting it would
   have cemented the defect. Ask when a layer looks like a capability.
6. **Ask before creating the MR.** Show the deletion list and the verification output first, then `/create-mr`.
   - One MR per coherent scope. A 40-file dead-code sweep is unreviewable — split it.
   - Body should state, per deletion, why it was dead and how that was verified.
   - On `configs`, merging needs `squash: true` or GitLab reports "Branch cannot be merged".

## Notes

- A large repo takes ~20s for 8k files; it is pure Python with no index to warm.
- The engine suppresses entrypoint and trait-hook names by default (`main`, `run`, `fmt`, `render`, `do_GET`, …) because "no caller" is their normal state. `--no-allowlist` turns that off when you are hunting specifically.
- Rust `#[cfg(test)] mod tests` blocks and `impl Trait for T` methods are excluded by design — see `references/limits.md`.
