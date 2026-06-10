---
description: Generate presenterm slide decks from MRs, features, code walkthroughs, or any topic. Use when asked to create slides, make a presentation, or turn something into a talk.
allowed-tools: Bash, Read, Glob, Grep, Write, Edit, Agent, WebFetch
---

# Presenterm Slide Generator

Generate polished terminal presentation slide decks in presenterm markdown format.

## Input

`$ARGUMENTS` — one of:
- **MR number** (e.g. `647`, `!647`) — fetch diff + context via `gl-mr`, build narrative slides
- **Feature/topic name** (e.g. `kcl-gitlab-runner`) — explore codebase, build explainer slides
- **Free-form description** — build slides from the description directly
- **Existing file path** — rewrite/polish an existing slide deck

## Context Gathering

Depending on input type, gather context before writing:

### For MR-based slides
```bash
gl-mr info <iid>        # Title, description, author, branches
gl-mr diff <iid>        # Full diffs — the core content
gl-mr commits <iid>     # Commit progression
```

### For feature/code walkthroughs
- Read relevant source files
- Understand the architecture and data flow
- Identify the key concepts to explain

## Presenterm Markdown Syntax Reference

### Frontmatter (title slide)
```yaml
---
title: "Slide Title"
sub_title: "One-line subtitle"
author: momoyang
---
```

### Slide separator
```
<!-- end_slide -->
```

### Slide titles (setext headers — rendered centered)
```
My Slide Title
===
```

### Pauses (incremental reveal)
```
<!-- pause -->
```

### Incremental lists
```
<!-- incremental_lists: true -->
- Item 1
- Item 2
<!-- incremental_lists: false -->
```

### Column layouts
```
<!-- column_layout: [1, 10, 1] -->     <!-- centered content with gutters -->
<!-- column_layout: [1, 5, 1, 5, 1] --> <!-- side-by-side comparison -->
<!-- column: 0 -->                      <!-- switch to column index -->
<!-- column: 1 -->
<!-- reset_layout -->                   <!-- back to full width -->
```

### Code blocks with highlighting
````
```hcl {1,3|5-7}          <!-- animated highlight groups -->
```rust +line_numbers       <!-- line numbers -->
```bash +exec_replace       <!-- run and show output -->
````

### Vertical centering (section dividers)
```
<!-- jump_to_middle -->
```

### Text alignment
```
<!-- alignment: center -->
```

### Other commands
```
<!-- new_line -->
<!-- new_lines: 3 -->
<!-- no_footer -->
```

## Slide Design Patterns

Follow these patterns for polished, readable slides:

### 1. Gutter margins on every content slide
Always wrap content in a centered column layout to avoid edge-to-edge text:
```
<!-- column_layout: [1, 12, 1] -->
<!-- column: 1 -->
```

### 2. Side-by-side comparisons (before/after, old/new)
```
<!-- column_layout: [1, 5, 1, 5, 1] -->
<!-- column: 1 -->
**Before**
...code...

<!-- column: 3 -->
<!-- pause -->
**After**
...code...
```

### 3. Section divider slides
```
<!-- jump_to_middle -->

Section Title
===

<!-- end_slide -->
```

### 4. Progressive reveal
Use `<!-- pause -->` between conceptual steps — don't dump everything at once.
Use `<!-- incremental_lists: true -->` for bullet lists that build up.

### 5. Code with narrative
Show code, pause, then explain. Or explain first, pause, then reveal code.

### 6. Focused code highlighting
Use `{line|line}` syntax to walk through code sections:
````
```hcl {1-3|5-8|10-12}
````

## Slide Structure Guidelines

Aim for **7-12 slides** depending on topic complexity:

1. **Title slide** — frontmatter (auto-generated)
2. **Context/Problem** — why does this matter?
3. **The Incident / Motivation** — what went wrong or what need arose?
4. **Section divider** — transition to the solution (`<!-- jump_to_middle -->`)
5. **Core change** — before/after comparison, side-by-side
6. **Implementation details** — 1-3 slides walking through key code
7. **Impact / scope** — what was affected, what changed
8. **Takeaway** — centered, punchy conclusion

### Content principles
- **One idea per slide** — if you need to scroll, split the slide
- **Code over prose** — show the actual code, not bullet points about code
- **Progressive disclosure** — use pauses to build understanding
- **Concrete over abstract** — real file paths, real values, real examples

## Output

Write the slide deck to `slides/<slug>.md` where `<slug>` is derived from the topic (kebab-case).

After writing, tell the user how to present:
```
presenterm slides/<slug>.md
```

## User Request

$ARGUMENTS
