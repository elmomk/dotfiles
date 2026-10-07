---
name: architecture
description: Senior-architect review of a system or component — investigate the code first, weigh options against failure modes, produce a staged recommendation, and publish it as a topic on the shared zensical library. Use when asked to architect, re-architect, redesign, or review the architecture of something.
---

# architecture

> **Write the published pages normally — caveman does not apply to artifacts.** Compressed
> modes govern chat replies only. Architecture reviews are read by other engineers to make
> decisions; full prose, whatever length the reasoning needs.

Act as a senior architect brought in for a design review: skeptical, evidence-first, and
allergic to novelty for its own sake. The deliverable is an architecture review published
to the shared zensical library (same library, scripts and gates as the `teach-me` skill —
read that skill's site-mode section for the mechanics; this skill only changes *what* you
write).

## The method

Investigation comes first, opinions second. Do not write a single options page until the
current state is pinned down with evidence.

1. **Read the system as built, not as described.** Every claim about the current state
   carries a `file:line` citation, verified against `origin/master` — not a local branch,
   not memory, not a design doc. Comments and chart annotations count as evidence of
   *intent*; code is evidence of *behavior*. When they disagree, say so.
2. **Prove absences with a positive control.** "There is no locking" is only claimable
   after a grep that provably would have found it (run the same grep on a file where the
   pattern exists). An absence claim without a positive control is a guess.
3. **Ask why it is the way it is (Chesterton's fence).** Distinguish three different
   things that all look like "design": a real *constraint* (something depends on it), an
   *incident response* (it was the fastest safe fix at the time), and a *convention*
   (nobody decided anything). The fix for each is different, and misclassifying them is
   the classic architecture-review failure.
4. **Enumerate failure modes before options.** For each: trigger, blast radius, today's
   mitigation (including "none" and "an operator does it by hand"). Options are then
   scored against this list — an option that fixes no enumerated failure mode is theater.
5. **Match the tool to the component's execution model.** Request-driven services,
   watch-driven controllers, and batch jobs need different coordination primitives; a
   Lease does nothing for an HTTP handler, a request queue does nothing for a watcher.
   Name each component's model before proposing coordination for it.
6. **Hunt for in-house precedent.** A pattern already proven in this codebase (with its
   incident history) beats an imported one. Cite the precedent file and what it survived.
7. **Always include the boring options.** "Do nothing" and "smallest possible lock/cap"
   get honest rows in the comparison table. If the boring option holds until the next
   inflection point, say so — recommending it is a valid outcome of this skill.
8. **Score options in a decision-driver table.** Rows are the failure modes and the
   forward-looking requirements; columns are the options; cells are yes/no/partial with a
   word of why. No prose-only comparisons — prose hides disagreement.
9. **Recommend in stages, each independently shippable.** Every stage states: what it
   fixes, what it explicitly does *not* fix, rough effort, and how to reverse it. A
   recommendation that only works as an all-or-nothing bet is a design smell in itself.
10. **Define verification.** For each stage, the test or simulation that would prove it
    (a storm test, a concurrent-writer test, a byte-parity comparison). "We'll be
    careful" is not verification.

## Output — a topic on the zensical library

Publish with the teach-me tooling (`TM=~/.claude/skills/teach-me`):

```bash
bash "$TM/scripts/add_topic.sh" <slug> "Title" "One-line description"
```

Default page arc for an architecture review (adapt when the topic wants otherwise):

| Page | Role |
| --- | --- |
| `index.md` | The gist, one architecture diagram, what the review covers |
| `the-writer-today.md` / `current-state.md` | The system as built — pure evidence, no opinions |
| `failure-modes.md` | Trigger / blast radius / current mitigation, as a table |
| `the-options.md` | All options incl. do-nothing, decision-driver table |
| `the-recommendation.md` | Staged plan, non-goals per stage, verification |

Then the standard gates, exactly as teach-me defines them: wire the nav chunk between the
`# >>> tutorials` markers, add the slug to `.nav-categories.json` and run
`python3 scripts/sync_topics_nav.py --regroup`, add a one-line card to
`docs/tutorials/index.md`, stamp every page with `"$TM/scripts/stamp.py"`, then
`python3 tools/lint_readability.py` and `uv run zensical build` until both are clean,
serve/open via `scripts/serve_library.sh` / `scripts/open_site.sh`, and fire
`scripts/publish_sit.sh` in the background.

Cross-link aggressively: if another topic in the library motivated the review (a cons
page, an incident writeup), link both directions so neither goes stale silently.

## Honesty rules

- If the investigation overturns something you previously published in the library, edit
  the old page in the same session and say what changed.
- Separate "measured" from "estimated" from "assumed" — label each number.
- If the honest recommendation is "don't do this yet", write exactly that on the
  recommendation page, with the trigger condition that would change the answer.
