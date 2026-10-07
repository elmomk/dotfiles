# What the engine cannot see

The analysis is a regex-driven reference graph, not a compiler or a type checker. It resolves *names*, not bindings. Everything below is a known blind spot — check these by hand before deleting anything.

## Blind spots that cause false "dead" claims

| Pattern | Why it fools the engine | Where it bites |
|---|---|---|
| Dynamic dispatch by name | `getattr(obj, name)`, `handlers[cmd]()`, service registries | Python, TS, shell CLI dispatch |
| Decorator registration | `@register("x")` stores the function in a dict the dispatcher indexes by string — no call site ever names it | Python, TS (`@Injectable`), pytest fixtures |
| Trait / interface obligations | The method is called through a vtable, never by its own name | Rust `impl Trait for T`, Go interfaces, Python base-class overrides |
| Macro- and codegen-generated callers | The call site does not exist in the source tree | Rust proc macros, `build.rs`, protobuf, KCL renderers |
| Cross-repo consumers | A published crate/package/module is used by a repo that isn't being scanned | `pub` items in library crates, exported TS packages, Terraform modules |
| Feature-gated code | The caller is behind a `#[cfg(feature)]` / env branch | Rust features, `if TYPE_CHECKING` |
| Name-built-at-runtime | `"handler_" + verb`, template-composed identifiers | anywhere |

Mitigations already built in: trait-impl blocks and `#[cfg(test)] mod tests` are excluded; **decorated Python defs are capped at low** (multi-line decorator argument lists are tracked by bracket depth); an entrypoint/hook allowlist is suppressed; string-literal and config occurrences downgrade a finding to **low** rather than clearing it; multi-file name collisions suppress `unused-export` because references cannot be attributed to one definition.

## Vendored trees

A vendored dependency is not dead code, and it swamps everything else — in `configs`, `collections/ansible_collections` is 1421 of 1673 Python files and `opt/terraform` is 253 `.tf` files of upstream Google modules. Pass `--exclude collections/ansible_collections --exclude opt/terraform`. Excluded paths are **still indexed for references**, so first-party code that only a vendored file calls is not falsely reported dead.

Never narrow with `--path` when you mean `--exclude`: `--path` and `--exclude` both scope *reporting only*, and both leave the reference index whole. That is deliberate — an earlier version filtered the file list up front, which shrank the reference index too and manufactured findings for anything called from outside the scope.

## Blind spots that cause missed dead code (false negatives)

- **Name collisions.** Two files both defining `render` share one reference count; a reference to either keeps both alive.
- **Short names.** Symbols under 3 characters are skipped — too noisy.
- **Dead clusters — expect these, they are not an edge case.** A dead function calling another dead function keeps it alive, so only the outermost layer is visible. Each removal exposes the next layer, and the scan cannot see past the first.

  This showed up on the very first real cleanup. In `configs`, `render_list` → `render` → `_helm_rootsync` was three layers deep: the scan reported only `render_list` and `render_all`. Deleting those exposed `render`, and deleting `render` exposed `_helm_rootsync` — a 27-line renderer for an entire feature path. **Always re-scan after deleting, and keep re-scanning until a pass adds nothing new.**

  What surfaces at the bottom of a cluster is often not more dead code. `_helm_rootsync` turned out to be an unreachable *feature* — no app could render a helm-sourced RootSync because the live entrypoint only dispatched to `_git_rootsync`. The right fix was to restore the dispatch, not to delete the implementation. Treat each newly exposed layer as a fresh judgment call, not as more of the same deletion.
- **Commented-out and doc-comment references** count as code, keeping symbols alive.
- **Test-only code** is live by default. Use `--ignore-test-refs` to surface production code that only its own tests still exercise.

## Language-specific notes

- **Rust** — trait-impl methods and `#[cfg(test)]` modules are excluded by brace tracking. `pub mod` is never reported as an unused export: `pub mod x; pub use x::{...}` is the normal facade pattern.
- **TypeScript** — only top-level symbols are considered. Class methods are skipped entirely: they may satisfy an interface or be invoked by a framework.
- **Python** — no `export` keyword exists, so nothing is reported as an unused export. Methods are capped at **low** confidence; dunders are skipped.
- **Shell** — backticks and `"$(...)"` are treated as code, not string data. Extensionless files on `PATH` are detected by shebang.
- **HCL** — only `variable`, `output` and `module` names. Resource and data blocks are the deliverable, not candidates.
- **jsonnet / KCL** — top-level `local` / schema / binding names. This is where genuine dead code accumulates fastest, since nothing compiles it.

## Reading the finding kinds

- `dead-symbol` — defined, never referenced. The real target.
- `unused-export` — used inside its own file but exported anyway. **Narrow the visibility; do not delete.** Only emitted for languages with a real visibility declaration (`pub`, `export`, Go capitalisation) and only for files something actually imports.
- `orphan-file` — no other file mentions the module by name. Often a genuinely abandoned script, sometimes an entrypoint invoked from CI or a cron — check the pipeline config before deleting.
- `orphan-dir` — a directory-addressed unit nothing addresses. See below.

## Directory-addressed units

Some ecosystems reference a whole directory, never a file inside it: a Terraform module is `source = ".../modules/<name>"`, a KCL package is its directory. Per-file orphan detection is blind to these — every file inside is `main.tf` / `outputs.tf` / `variables.tf`, so the filename carries no information — which is how 13 unreferenced Terraform module directories sat undetected in `configs` until `orphan-dir` was added.

A directory is only treated as a unit if it declares itself one, via a marker file (`main.tf`, `variables.tf`, `outputs.tf`, `kcl.mod`). Without that gate the check fires on every language package directory (`.../steps`, `.../tools`), which are addressed by dotted import rather than path — 230 findings instead of 13.

**Helm is deliberately excluded.** A subchart is declared by *name* under `dependencies:` in the parent's `Chart.yaml`, never by directory path, so treating `Chart.yaml` as a unit marker reported every vendored chart as orphaned — 56 false positives.

Path references are attributed to the **longest** unit directory they end with. This is what makes duplicated trees work: `modules/x` is a suffix of `catalog/infrastructure/modules/x`, so a `<parent>/<name>` key or a plain substring test lets the live copy mark the stale copy as referenced. Beware the same trap when hand-checking a finding — `rg "modules/aws_irsa"` also matches `modules/aws_irsa_generic`.

Remember that `--exclude` keeps a tree **indexed**. A module referenced only from an excluded `deprecated_infra/` still counts as referenced and will not be reported, which is usually what you want: it is reachable, just from code you are not cleaning up. To find those, compare the excluded and unexcluded runs.
