#!/usr/bin/env python3
"""Language-agnostic dead-code candidate finder.

Two passes over the repo:
  1. Extract symbol definitions per file using per-language rules.
  2. Count occurrences of those symbol names across every text file, split into
     hard refs (code, outside string literals), soft refs (config/docs/strings)
     and own-file refs.

A symbol with zero hard refs and zero own-file refs is a dead-code candidate.
Soft refs downgrade confidence instead of clearing the finding, because config
files and string literals are how dynamic dispatch usually looks.

Emits JSON on stdout (--json) or a human table.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict

# --------------------------------------------------------------------------
# File classification
# --------------------------------------------------------------------------

CODE_EXT = {
    ".rs": "rust",
    ".ts": "ts",
    ".tsx": "ts",
    ".mts": "ts",
    ".cts": "ts",
    ".js": "ts",
    ".jsx": "ts",
    ".mjs": "ts",
    ".cjs": "ts",
    ".py": "python",
    ".go": "go",
    ".sh": "shell",
    ".bash": "shell",
    ".zsh": "shell",
    ".tf": "hcl",
    ".hcl": "hcl",
    ".k": "kcl",
    ".jsonnet": "jsonnet",
    ".libsonnet": "jsonnet",
}

# Referenced by name from other files, but never "defining" symbols themselves.
SOFT_EXT = {
    ".yaml", ".yml", ".json", ".toml", ".md", ".txt", ".tpl", ".tmpl",
    ".ini", ".cfg", ".conf", ".env", ".sql", ".html", ".htm", ".csv",
    ".gotmpl", ".j2", ".lock", ".proto", ".graphql", ".css", ".scss",
}

SKIP_DIR_PARTS = {
    "node_modules", "target", "vendor", "dist", "build", ".git", ".venv",
    "venv", "__pycache__", ".terragrunt-cache", ".terraform", ".mypy_cache",
    ".pytest_cache", ".next", ".turbo", "coverage", "site-packages",
    "worktrees",  # nested checkouts duplicate every symbol in the tree
}

SKIP_FILE_RE = re.compile(
    r"(^|/)(zz_generated|generated)[^/]*$"
    r"|\.pb\.go$|_pb2\.py$|\.g\.dart$|\.min\.js$|\.d\.ts$"
    r"|\.generated\.[^/]+$|_generated\.[^/]+$"
)

TEST_PATH_RE = re.compile(
    r"(^|/)(tests?|__tests__|spec|e2e|fixtures?|testdata)(/|$)"
    r"|(^|/)test_[^/]+$|_test\.[^/]+$|\.test\.[^/]+$|\.spec\.[^/]+$|_tests\.rs$"
)

MAX_FILE_BYTES = 2 * 1024 * 1024

IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
STRING_RE = re.compile(r"\"(?:[^\"\\]|\\.)*\"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`")
BACKTICK_RE = re.compile(r"`(?:[^`\\]|\\.)*`")
# Interpolations *inside* a string literal are executable, not data:
# shell `"$(f)"` / `"${v}"` / `"$v"`, JS `` `${f()}` ``, Python f"{f()}",
# and Go/Helm template actions `{{ f }}`.
INTERP_RE = re.compile(
    # `$( ... )` tolerating one level of nested parens: shell substitutions
    # routinely wrap a regex, as in `$(roots_of '(^|/)Cargo\.toml$')`.
    r"\$\((?:[^()]|\([^()]*\))*\)"
    r"|\$\{[^{}]*\}|\$\w+|\{\{[^{}]*\}\}|\{[^{}\s][^{}]*\}"
)


def split_code_and_strings(text: str, lang: str):
    """Return (code_text, string_text).

    Everything outside string literals is code. Interpolated segments inside a
    literal are lifted back into the code side — missing them made shell helpers
    invoked as `"$(helper)"` look unreferenced.

    Scanning is per line: quote pairing across a whole file drifts as soon as one
    apostrophe appears in a comment, which silently swallows the rest of the file
    into a "string". A line that ends mid-literal just leaves the tail on the code
    side, which is the safe direction — it can only add references, never remove
    one, so it cannot invent a dead symbol.
    """
    code, strings = [], []
    for line in text.splitlines():
        if lang == "shell":
            # Backticks are command substitution in shell, not a string delimiter.
            line = BACKTICK_RE.sub(lambda m: " " + m.group(0)[1:-1] + " ", line)
        last = 0
        for m in STRING_RE.finditer(line):
            code.append(line[last:m.start()])
            lit = m.group(0)
            interp = INTERP_RE.findall(lit)
            if interp:
                code.append(" " + " ".join(interp) + " ")
                strings.append(INTERP_RE.sub(" ", lit))
            else:
                strings.append(lit)
            last = m.end()
        code.append(line[last:] + "\n")
        strings.append("\n")
    return "".join(code), "".join(strings)

# Names that are entrypoints, framework hooks or trait/interface obligations.
# Never reported: absence of an explicit caller is the normal case for these.
ALWAYS_LIVE = {
    "main", "new", "default", "init", "setup", "teardown", "run", "handler",
    "Handler", "start", "stop", "drop", "clone", "fmt", "from", "into",
    "try_from", "try_into", "next", "poll", "deref", "eq", "ne", "cmp",
    "partial_cmp", "hash", "serialize", "deserialize", "index", "add", "sub",
    "mul", "div", "neg", "not", "as_ref", "as_mut", "borrow", "borrow_mut",
    "to_string", "len", "is_empty", "iter", "into_iter", "extend",
    "render", "reconcile", "validate", "build", "call", "execute",
    "ServeHTTP", "String", "Error", "Read", "Write", "Close",
    "__init__", "__main__", "__str__", "__repr__", "__enter__", "__exit__",
    "app", "App", "middleware", "provider", "output", "usage", "help",
}


SHEBANG_LANG = (
    ("python", "python"), ("bash", "shell"), ("zsh", "shell"),
    ("/sh", "shell"), ("dash", "shell"), ("node", "ts"),
)


def shebang_lang(path: str):
    """Language of an extensionless file, from its shebang. Scripts on PATH
    (`gl-mr`, `mr-board`, ...) carry no extension and would otherwise be missed."""
    try:
        with open(path, "rb") as fh:
            first = fh.readline(200).decode("utf-8", "ignore")
    except OSError:
        return None
    if not first.startswith("#!"):
        return None
    for needle, lang in SHEBANG_LANG:
        if needle in first:
            return lang
    return None


def classify(rel: str, root: str = ""):
    """Return (lang, kind) where kind is 'code' | 'soft' | None."""
    ext = os.path.splitext(rel)[1].lower()
    base = os.path.basename(rel)
    if ext in CODE_EXT:
        return CODE_EXT[ext], "code"
    if ext in SOFT_EXT:
        return None, "soft"
    if ext == "":
        if base in {"justfile", "Makefile", "Dockerfile", "Jenkinsfile"}:
            return None, "soft"
        if root:
            lang = shebang_lang(os.path.join(root, rel))
            if lang:
                return lang, "code"
    return None, None


def list_files(root: str):
    """Repo files, honouring .gitignore when the tree is a git checkout."""
    try:
        out = subprocess.run(
            ["git", "-C", root, "ls-files", "-z", "--cached", "--others",
             "--exclude-standard"],
            capture_output=True, text=True, check=True, timeout=120,
        ).stdout
        rels = [p for p in out.split("\0") if p]
    except (subprocess.SubprocessError, FileNotFoundError):
        rels = []
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIR_PARTS]
            for fn in filenames:
                rels.append(os.path.relpath(os.path.join(dirpath, fn), root))

    keep = []
    for rel in rels:
        parts = set(rel.split("/"))
        if parts & SKIP_DIR_PARTS or SKIP_FILE_RE.search(rel):
            continue
        keep.append(rel)
    return keep


def read_text(path: str):
    try:
        if os.path.getsize(path) > MAX_FILE_BYTES:
            return None
        with open(path, "r", encoding="utf-8", errors="strict") as fh:
            return fh.read()
    except (OSError, UnicodeDecodeError):
        return None


# --------------------------------------------------------------------------
# Definition extraction
# --------------------------------------------------------------------------

class Definition:
    __slots__ = ("name", "file", "line", "kind", "exported", "lang")

    def __init__(self, name, file, line, kind, exported, lang):
        self.name = name
        self.file = file
        self.line = line
        self.kind = kind
        self.exported = exported
        self.lang = lang


RUST_FN = re.compile(r"^(\s*)(pub(?:\s*\([^)]*\))?\s+)?(?:async\s+)?(?:const\s+)?(?:unsafe\s+)?(?:extern\s+\"[^\"]*\"\s+)?fn\s+([A-Za-z_]\w*)")
RUST_TYPE = re.compile(r"^(\s*)(pub(?:\s*\([^)]*\))?\s+)?(struct|enum|trait|union|type|const|static)\s+([A-Za-z_]\w*)")
RUST_MOD = re.compile(r"^(\s*)(pub(?:\s*\([^)]*\))?\s+)?mod\s+([A-Za-z_]\w*)\s*[;{]")
RUST_MACRO = re.compile(r"^\s*macro_rules!\s+([A-Za-z_]\w*)")
RUST_IMPL = re.compile(r"^\s*(?:unsafe\s+)?impl\b(.*)$")


def defs_rust(rel, lines):
    """Rust defs, with two whole blocks excluded by brace tracking:

    * `impl Trait for T` — the methods are obligations of the trait, reached
      through the vtable, never by a direct call to that name.
    * `#[cfg(test)] mod tests` — Rust keeps unit tests inside the file they test,
      so path-based test detection cannot see them and every test fn would
      otherwise be reported as dead.
    """
    out = []
    depth = 0
    skip_depth = None
    pending_test = False
    pending_cfg_test = False
    for i, line in enumerate(lines, 1):
        code = line.split("//")[0]
        opens = code.count("{") - code.count("}")
        stripped = code.strip()

        if skip_depth is not None:
            depth += opens
            if depth <= skip_depth:
                skip_depth = None
            continue

        if not stripped:            # blank / comment-only: keep pending attrs
            depth += opens
            continue

        if stripped.startswith("#["):
            flat = code.replace(" ", "")
            if "cfg(test" in flat or "cfg(all(test" in flat:
                pending_cfg_test = True
            if re.search(r"\btest\b", code):
                pending_test = True
            depth += opens
            continue

        m = RUST_IMPL.match(code)
        if m and " for " in m.group(1):
            skip_depth = depth
            depth += opens
            pending_test = pending_cfg_test = False
            continue

        m = RUST_MOD.match(code)
        if m:
            if pending_cfg_test or m.group(3) == "tests":
                skip_depth = depth
            else:
                out.append(Definition(m.group(3), rel, i, "mod", bool(m.group(2)), "rust"))
            depth += opens
            pending_test = pending_cfg_test = False
            continue

        if not pending_test:
            m = RUST_MACRO.match(code)
            if m:
                out.append(Definition(m.group(1), rel, i, "macro", True, "rust"))
            elif RUST_FN.match(code):
                m = RUST_FN.match(code)
                out.append(Definition(m.group(3), rel, i, "fn", bool(m.group(2)), "rust"))
            elif RUST_TYPE.match(code):
                m = RUST_TYPE.match(code)
                out.append(Definition(m.group(4), rel, i, m.group(3), bool(m.group(2)), "rust"))

        depth += opens
        pending_test = pending_cfg_test = False
    return out


TS_EXPORT_FN = re.compile(r"^\s*export\s+(?:default\s+)?(?:async\s+)?function\s*\*?\s*([A-Za-z_$][\w$]*)")
TS_EXPORT_CLASS = re.compile(r"^\s*export\s+(?:default\s+)?(?:abstract\s+)?class\s+([A-Za-z_$][\w$]*)")
TS_EXPORT_VAR = re.compile(r"^\s*export\s+(?:declare\s+)?(?:const|let|var)\s+([A-Za-z_$][\w$]*)")
TS_EXPORT_TYPE = re.compile(r"^\s*export\s+(?:declare\s+)?(?:type|interface|enum)\s+([A-Za-z_$][\w$]*)")
TS_LOCAL_FN = re.compile(r"^(?:async\s+)?function\s*\*?\s*([A-Za-z_$][\w$]*)")
TS_LOCAL_CONST_FN = re.compile(r"^(?:const|let)\s+([A-Za-z_$][\w$]*)\s*(?::[^=]+)?=\s*(?:async\s*)?(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>")


def defs_ts(rel, lines):
    """Only top-level TS/JS symbols. Class methods are excluded: they may satisfy
    an interface or be invoked through a framework."""
    out = []
    for i, line in enumerate(lines, 1):
        for rx, kind in (
            (TS_EXPORT_FN, "fn"), (TS_EXPORT_CLASS, "class"),
            (TS_EXPORT_VAR, "const"), (TS_EXPORT_TYPE, "type"),
        ):
            m = rx.match(line)
            if m:
                out.append(Definition(m.group(1), rel, i, kind, True, "ts"))
                break
        else:
            for rx, kind in ((TS_LOCAL_FN, "fn"), (TS_LOCAL_CONST_FN, "const")):
                m = rx.match(line)
                if m:
                    out.append(Definition(m.group(1), rel, i, kind, False, "ts"))
                    break
    return out


PY_DEF = re.compile(r"^(\s*)(?:async\s+)?def\s+([A-Za-z_]\w*)")
PY_CLASS = re.compile(r"^(\s*)class\s+([A-Za-z_]\w*)")
PY_CONST = re.compile(r"^([A-Z][A-Z0-9_]*)\s*(?::[^=]+)?=")


def defs_python(rel, lines):
    """Python defs. A decorated def is treated as `method` (capped at low
    confidence) because decorators are how registries capture a function without
    ever naming it again: `@register("x")` stores `fn` in a dict the dispatcher
    indexes by string, so no call site mentions the function at all."""
    out = []
    decorated = False
    depth = 0

    def balance(s):
        return s.count("(") + s.count("[") - s.count(")") - s.count("]")

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if depth > 0:                 # inside a multi-line decorator argument list
            depth += balance(line)
            continue
        if stripped.startswith("@"):
            decorated = True
            depth = balance(line)     # `@register("x", [` keeps the flag alive
            continue
        if not stripped or stripped.startswith("#"):
            continue          # blank/comment between decorator and def

        m = PY_DEF.match(line)
        if m:
            name = m.group(2)
            if not (name.startswith("__") and name.endswith("__")):
                top = len(m.group(1)) == 0
                kind = "decorated" if decorated else ("fn" if top else "method")
                out.append(Definition(name, rel, i, kind,
                                      not name.startswith("_"), "python"))
            decorated = False
            continue
        m = PY_CLASS.match(line)
        if m and len(m.group(1)) == 0:
            out.append(Definition(m.group(2), rel, i,
                                  "decorated" if decorated else "class", True, "python"))
            decorated = False
            continue
        m = PY_CONST.match(line)
        if m:
            out.append(Definition(m.group(1), rel, i, "const", True, "python"))
        decorated = False
    return out


GO_FUNC = re.compile(r"^func\s+(?:\([^)]*\)\s*)?([A-Za-z_]\w*)")
GO_TYPE = re.compile(r"^type\s+([A-Za-z_]\w*)")
GO_VAR = re.compile(r"^(?:var|const)\s+([A-Za-z_]\w*)")


def defs_go(rel, lines):
    out = []
    for i, line in enumerate(lines, 1):
        for rx, kind in ((GO_FUNC, "fn"), (GO_TYPE, "type"), (GO_VAR, "const")):
            m = rx.match(line)
            if m:
                name = m.group(1)
                out.append(Definition(name, rel, i, kind, name[:1].isupper(), "go"))
                break
    return out


SH_FUNC = re.compile(r"^\s*(?:function\s+)?([A-Za-z_][\w:-]*)\s*\(\s*\)\s*\{")


def defs_shell(rel, lines):
    out = []
    for i, line in enumerate(lines, 1):
        m = SH_FUNC.match(line)
        if m:
            out.append(Definition(m.group(1), rel, i, "fn", True, "shell"))
    return out


# The lookahead is load-bearing: without it the keyword matches the prefix of an
# ordinary attribute name, so `module_depends_on = [...]` parsed as a module named
# `_depends_on` and `output_format = optional(string)` as an output named `_format`.
HCL_BLOCK = re.compile(r"^\s*(variable|output|module|locals)(?=[\s\"])\s*\"?([\w-]*)\"?")


def defs_hcl(rel, lines):
    """Terraform/terragrunt. `variable`/`output`/`module` names only — resources
    and data blocks are the deliverable, not dead-code candidates."""
    out = []
    for i, line in enumerate(lines, 1):
        m = HCL_BLOCK.match(line)
        if m and m.group(1) != "locals" and m.group(2):
            out.append(Definition(m.group(2), rel, i, m.group(1), True, "hcl"))
    return out


KCL_SCHEMA = re.compile(r"^schema\s+([A-Za-z_]\w*)")
KCL_TOP = re.compile(r"^([a-z_]\w*)\s*(?::\s*[^=]+)?=")


def defs_kcl(rel, lines):
    out = []
    for i, line in enumerate(lines, 1):
        m = KCL_SCHEMA.match(line)
        if m:
            out.append(Definition(m.group(1), rel, i, "schema", True, "kcl"))
            continue
        m = KCL_TOP.match(line)
        if m:
            out.append(Definition(m.group(1), rel, i, "const", True, "kcl"))
    return out


JSONNET_LOCAL = re.compile(r"^local\s+([A-Za-z_]\w*)\s*(?:\([^)]*\))?\s*=")


def defs_jsonnet(rel, lines):
    out = []
    for i, line in enumerate(lines, 1):
        m = JSONNET_LOCAL.match(line)
        if m:
            out.append(Definition(m.group(1), rel, i, "local", False, "jsonnet"))
    return out


EXTRACTORS = {
    "rust": defs_rust,
    "ts": defs_ts,
    "python": defs_python,
    "go": defs_go,
    "shell": defs_shell,
    "hcl": defs_hcl,
    "kcl": defs_kcl,
    "jsonnet": defs_jsonnet,
}


# --------------------------------------------------------------------------
# Orphan files and directories
# --------------------------------------------------------------------------

# A multi-segment path reference, captured at full length so it can be attributed
# to the deepest unit it names:
#   source = "${get_repo_root()}/modules/aws_irsa"
#   find_in_parent_folders("modules/gcp_address")
PATH_REF_RE = re.compile(r"[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)+")

# A directory only counts as a unit if it declares itself one. Without this the
# check fires on every language package directory (`.../steps`, `.../tools`),
# which are addressed by dotted import, not by path — 230 findings instead of 9.
# Only ecosystems that address a unit by PATH belong here. Helm deliberately does
# not: a subchart is declared by name under `dependencies:` in the parent's
# Chart.yaml, never by directory, so every vendored chart looks orphaned (56 false
# positives in `configs`).
UNIT_MARKERS = {
    "main.tf": "terraform",
    "variables.tf": "terraform",
    "outputs.tf": "terraform",
    "kcl.mod": "kcl",
}

# Which --lang selects each ecosystem's unit directories.
UNIT_ECOSYSTEM_LANG = {"terraform": "hcl", "kcl": "kcl"}


def orphan_dirs(dir_hits, langs=(), reportable=lambda _rel: True):
    """Directories nothing addresses by path.

    Some ecosystems reference a whole directory rather than a file: a Terraform
    module is `source = ".../modules/<name>"`, never an import of `main.tf`. The
    per-file orphan check cannot see these — every file inside is named `main.tf`
    / `outputs.tf` / `variables.tf`, so its stem tells you nothing — which is how
    13 unreferenced Terraform module directories sat undetected in `configs`.
    """
    found = []
    for d, (key, ecosystem) in sorted(dir_hits.units.items()):
        if not reportable(d) or TEST_PATH_RE.search(d + "/"):
            continue
        if langs and UNIT_ECOSYSTEM_LANG.get(ecosystem) not in langs:
            continue
        outside = {f for f in dir_hits.hits.get(key, ()) if not f.startswith(d + "/")}
        if not outside:
            found.append((d, ecosystem))
    return found


class DirIndex:
    """Directory-addressed units, and which files address each one by path.

    Sources name a unit by a path *suffix* of varying length — `find_in_parent_
    folders("modules/gcp_address")` and `"${get_repo_root()}/catalog/infrastructure/
    modules/gcp_address"` both address a unit, at different depths. So each path
    reference is attributed to the **longest** unit directory it ends with.

    Longest-match is what makes duplicated trees work. `modules/x` is a suffix of
    `catalog/infrastructure/modules/x`, so a plain substring or `<parent>/<name>`
    key lets the live catalog copy mark the stale top-level copy as referenced —
    which hid real orphans in `configs` until this was fixed.
    """

    def __init__(self, rels):
        self.units = {}
        for rel in rels:
            ecosystem = UNIT_MARKERS.get(os.path.basename(rel))
            if ecosystem is None:
                continue
            d = os.path.dirname(rel)
            if not d or "/" not in d:
                continue          # repo root and top-level dirs are not units
            self.units[d] = (d, ecosystem)
        self._depths = sorted({u.count("/") + 1 for u in self.units}, reverse=True)
        self.hits = defaultdict(set)

    def scan(self, rel, text):
        if not self.units:
            return
        for token in PATH_REF_RE.findall(text):
            segs = token.split("/")
            for depth in self._depths:          # longest unit path first
                if depth > len(segs):
                    continue
                cand = "/".join(segs[-depth:])
                if cand in self.units:
                    self.hits[cand].add(rel)
                    break


ENTRY_BASENAMES = {
    "main", "index", "mod", "lib", "__init__", "__main__", "app", "setup",
    "conftest", "values", "Chart", "kustomization", "README", "CHANGELOG",
    "LICENSE", "Dockerfile", "justfile", "Makefile", "kcl", "settings",
}


# Languages whose imports always carry the file extension —
# `import './panels/osd_up.jsonnet'`. For these the bare stem is the wrong signal:
# a generic stem like `monitor` or `pools` collides with ordinary prose and marks
# an unimported file as referenced. Matching the full basename fixes that (it
# recovered 3 orphaned dashboards in `configs` that stem matching declared live).
IMPORTS_WITH_EXTENSION = {"jsonnet"}


def orphan_files(file_class, stem_hits, langs=(), reportable=lambda _rel: True,
                 basename_hits=None):
    """Code files no other file mentions by module name."""
    basename_hits = basename_hits if basename_hits is not None else {}
    found = []
    for rel, (lang, kind) in file_class.items():
        if kind != "code" or TEST_PATH_RE.search(rel):
            continue
        if langs and lang not in langs:
            continue
        if not reportable(rel):
            continue
        base = os.path.basename(rel)
        stem = os.path.splitext(base)[0]
        if stem in ENTRY_BASENAMES or stem.startswith("."):
            continue
        key, hits = ((base, basename_hits) if lang in IMPORTS_WITH_EXTENSION
                     else (stem, stem_hits))
        if not (hits.get(key, set()) - {rel}):
            found.append((rel, stem))
    return found


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Find dead-code candidates.")
    ap.add_argument("root", nargs="?", default=".", help="repo root (default: cwd)")
    ap.add_argument("--json", action="store_true", help="emit JSON")
    ap.add_argument("--lang", action="append", default=[],
                    help="restrict to language(s): " + ", ".join(sorted(EXTRACTORS)))
    ap.add_argument("--path", action="append", default=[],
                    help="only REPORT findings under these path prefix(es). The whole "
                         "tree is still indexed for references.")
    ap.add_argument("--exclude", action="append", default=[],
                    help="never report findings under these path prefix(es) — vendored "
                         "trees, deprecated dirs. Still indexed for references, so code "
                         "they use is not falsely reported dead. Repeatable.")
    ap.add_argument("--min-confidence", choices=["low", "medium", "high"],
                    default="low")
    ap.add_argument("--limit", type=int, default=0, help="cap findings (0 = all)")
    ap.add_argument("--ignore-test-refs", action="store_true",
                    help="treat references from test files as soft (code used only "
                         "by its own tests then shows up as dead)")
    ap.add_argument("--no-orphans", action="store_true",
                    help="skip whole-file orphan detection")
    ap.add_argument("--no-allowlist", action="store_true",
                    help="also consider entrypoint/trait-hook names (main, run, "
                         "render, fmt, ...) that are suppressed by default")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    rels = list_files(root)

    # --path/--exclude scope what is REPORTED, never what is INDEXED. Filtering the
    # file list here instead would shrink the reference index too, so any symbol
    # called from outside the scope would look dead — the scope would manufacture
    # findings rather than narrow them.
    includes = tuple(p.rstrip("/") for p in args.path)
    excludes = tuple(p.rstrip("/") for p in args.exclude)

    def reportable(rel):
        if includes and not any(rel == p or rel.startswith(p + "/") for p in includes):
            return False
        return not any(rel == p or rel.startswith(p + "/") for p in excludes)

    # Pass 1: read every text file once, extract definitions from code files.
    text_index = {}
    file_class = {}
    defs = []
    lang_counts = defaultdict(int)
    for rel in rels:
        lang, kind = classify(rel, root)
        if kind is None:
            continue
        text = read_text(os.path.join(root, rel))
        if text is None:
            continue
        text_index[rel] = text
        file_class[rel] = (lang, kind)
        if kind != "code":
            continue
        lang_counts[lang] += 1
        if args.lang and lang not in args.lang:
            continue
        if TEST_PATH_RE.search(rel) or not reportable(rel):
            continue
        defs.extend(EXTRACTORS[lang](rel, text.splitlines()))

    by_name = defaultdict(list)
    for d in defs:
        if (d.name in ALWAYS_LIVE and not args.no_allowlist) or len(d.name) < 3:
            continue
        by_name[d.name].append(d)
    interesting = set(by_name)

    # Module-name index: which files mention each code file's stem. Drives both
    # orphan detection and the "is this file importable at all" gate below.
    stems = defaultdict(set)
    for rel, (_lang, kind) in file_class.items():
        if kind == "code":
            stems[os.path.splitext(os.path.basename(rel))[0]].add(rel)
    ident_stems = {s for s in stems if IDENT_RE.fullmatch(s)}
    odd_stems = set(stems) - ident_stems  # kebab-case scripts: mr-board, gl-mr

    # Pass 2: count occurrences of candidate names across the whole tree.
    hard = defaultdict(lambda: defaultdict(int))   # name -> file -> count
    soft = defaultdict(int)                        # name -> count
    stem_hits = defaultdict(set)                   # stem -> files mentioning it
    dir_index = DirIndex(rels)

    # Full basenames, for languages whose imports include the extension.
    ext_basenames = {
        os.path.basename(r) for r, (lang, kind) in file_class.items()
        if kind == "code" and lang in IMPORTS_WITH_EXTENSION
    }
    basename_hits = defaultdict(set)
    for rel, text in text_index.items():
        lang, kind = file_class[rel]
        is_test = bool(TEST_PATH_RE.search(rel))
        soft_file = kind != "code" or (args.ignore_test_refs and is_test)

        dir_index.scan(rel, text)

        for b in ext_basenames:
            if b in text:
                basename_hits[b].add(rel)

        for s in odd_stems:
            if s in text:
                stem_hits[s].add(rel)

        if soft_file:
            for tok in IDENT_RE.findall(text):
                if tok in interesting:
                    soft[tok] += 1
                if tok in ident_stems:
                    stem_hits[tok].add(rel)
            continue

        # In code files, identifiers left in string literals are soft: they signal
        # reflection / registry lookup / templated config, not a static call.
        code_text, string_text = split_code_and_strings(text, lang)
        for tok in IDENT_RE.findall(string_text):
            if tok in interesting:
                soft[tok] += 1
            if tok in ident_stems:
                stem_hits[tok].add(rel)
        for tok in IDENT_RE.findall(code_text):
            if tok in interesting:
                hard[tok][rel] += 1
            if tok in ident_stems:
                stem_hits[tok].add(rel)

    def is_imported(rel):
        stem = os.path.splitext(os.path.basename(rel))[0]
        return bool(stem_hits.get(stem, set()) - {rel})

    findings = []
    for name, group in by_name.items():
        per_file = hard[name]
        total_hard = sum(per_file.values())
        def_files = {d.file for d in group}
        own_hard = sum(c for f, c in per_file.items() if f in def_files)
        external = total_hard - own_hard
        # One occurrence per definition line is the definition itself.
        self_uses = own_hard - len(group)

        if external > 0:
            continue
        if self_uses > 0:
            # Live inside its own file. Only interesting if it is also exported —
            # then the visibility is dead, not the symbol. Restricted to languages
            # with a real visibility declaration (`pub`, `export`, capitalisation),
            # and to files something actually imports: in a standalone script every
            # top-level symbol is local by definition, not an over-wide export.
            if len(group) > 1:
                # Same name defined in several files: references cannot be
                # attributed to one definition, so "unused" is unprovable.
                continue
            for d in group:
                if (d.exported and d.lang in ("rust", "ts", "go")
                        and d.kind != "mod" and is_imported(d.file)):
                    findings.append(_finding(d, "unused-export", "medium",
                                             f"used {self_uses}x in its own file, "
                                             "never outside it — narrow the "
                                             "visibility rather than delete",
                                             external, soft[name]))
            continue

        conf = "high"
        why = "no reference anywhere in the repo"
        if any(d.kind == "decorated" for d in group):
            conf = "low"
            why = ("no reference in the repo, but it is decorated — a decorator can "
                   "register it into a dispatch table, so no call site ever names it")
        elif any(d.kind == "method" for d in group):
            # Python methods are reached by dynamic dispatch as often as by name
            # (base-class overrides, `do_GET`-style handler tables, getattr).
            conf = "low"
            why = ("no reference in the repo, but it is a method — base-class "
                   "override or dynamic dispatch cannot be seen statically")
        elif soft[name] > 0:
            conf = "low"
            why = (f"no code reference, but the name appears {soft[name]}x in "
                   "config/docs/string literals — may be resolved dynamically")
        elif group[0].exported:
            conf = "medium"
            why = "no reference in the repo, but it is public API — external "\
                  "consumers cannot be seen from here"
        for d in group:
            findings.append(_finding(d, "dead-symbol", conf, why, external, soft[name]))

    orphans = []
    if not args.no_orphans:
        for rel, stem in orphan_files(file_class, stem_hits, args.lang, reportable,
                                      basename_hits):
            lang = file_class[rel][0]
            # A standalone shell script is an entrypoint: an operator runs
            # `./scripts/gcp-bootstrap.sh` from a terminal, so having no in-repo
            # caller is its design, not a defect. Reporting these at medium
            # produced a deletion list of ~30 live operator tools.
            entrypoint_lang = lang == "shell"
            orphans.append({
                "kind": "orphan-file", "file": rel, "line": 1, "symbol": stem,
                "lang": lang,
                "confidence": "low" if entrypoint_lang else "medium",
                "why": ("no other file mentions it, but a standalone script is "
                        "normally invoked by hand or from CI, not imported — "
                        "check the pipelines and runbooks before believing this")
                       if entrypoint_lang else
                       "filename/module path is not mentioned by any other file",
                "hard_refs": 0, "soft_refs": 0, "exported": True,
            })

        for d, ecosystem in orphan_dirs(dir_index, args.lang, reportable):
            n = sum(1 for r in rels if r.startswith(d + "/"))
            orphans.append({
                "kind": "orphan-dir", "file": d, "line": 1, "symbol": os.path.basename(d),
                "symbol_kind": ecosystem, "lang": ecosystem, "confidence": "medium",
                "why": f"no file addresses this path — a {ecosystem} unit is "
                       f"referenced by directory, so nothing consumes it "
                       f"({n} file(s) inside)",
                "hard_refs": 0, "soft_refs": 0, "exported": True,
            })

    rank = {"high": 0, "medium": 1, "low": 2}
    floor = rank[args.min_confidence]
    all_f = [f for f in findings + orphans if rank[f["confidence"]] <= floor]
    all_f.sort(key=lambda f: (rank[f["confidence"]], f["file"], f["line"]))
    if args.limit:
        all_f = all_f[: args.limit]

    report = {
        "root": root,
        "files_scanned": len(text_index),
        "languages": dict(sorted(lang_counts.items(), key=lambda kv: -kv[1])),
        "definitions_considered": len(by_name),
        "counts": {
            c: sum(1 for f in all_f if f["confidence"] == c)
            for c in ("high", "medium", "low")
        },
        "findings": all_f,
    }

    if args.json:
        json.dump(report, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        _print_human(report)
    return 0


def _finding(d, kind, conf, why, hard_refs, soft_refs):
    return {
        "kind": kind, "file": d.file, "line": d.line, "symbol": d.name,
        "symbol_kind": d.kind, "lang": d.lang, "exported": d.exported,
        "confidence": conf, "why": why,
        "hard_refs": hard_refs, "soft_refs": soft_refs,
    }


def _print_human(rep):
    langs = ", ".join(f"{k}:{v}" for k, v in rep["languages"].items()) or "none"
    print(f"repo      {rep['root']}")
    print(f"scanned   {rep['files_scanned']} files ({langs})")
    print(f"symbols   {rep['definitions_considered']} definitions considered")
    c = rep["counts"]
    print(f"findings  high:{c['high']}  medium:{c['medium']}  low:{c['low']}")
    if not rep["findings"]:
        print("\nno dead-code candidates.")
        return
    print()
    cur = None
    for f in rep["findings"]:
        if f["confidence"] != cur:
            cur = f["confidence"]
            print(f"--- {cur.upper()} ---")
        loc = f"{f['file']}:{f['line']}"
        print(f"  {loc}  {f['symbol']}  [{f['kind']}/{f.get('symbol_kind', 'file')}]")
        print(f"      {f['why']}")


if __name__ == "__main__":
    sys.exit(main())
