---
name: jira-ticket
description: "Draft and create a Jira ticket for the current sprint, after user confirmation. Triggers: jira ticket, file ticket, write this as a jira ticket, ticket in sprint, log this in jira."
argument-hint: "[brief topic, e.g. 'comprehensive parity test sv → idp-mo']"
---

# Jira Ticket

Draft a well-structured Jira ticket from in-context discussion, confirm with the user, then create it in the current open sprint. Use this whenever the user says "write this as a jira ticket", "file a ticket for X", "log this in our current sprint", etc.

## Workflow

1. **Load Atlassian tools** (deferred):
   ```
   ToolSearch select:mcp__claude_ai_Atlassian__getAccessibleAtlassianResources,mcp__claude_ai_Atlassian__getVisibleJiraProjects,mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql,mcp__claude_ai_Atlassian__createJiraIssue,AskUserQuestion
   ```

2. **Discover cloudId + project** (skip if already known in this session):
   - `getAccessibleAtlassianResources` → take the entry with `read:jira-work,write:jira-work` scopes.
   - `getVisibleJiraProjects(action: "create", expandIssueTypes: true)` → pick project. If only one project is visible, use it without prompting.

3. **Find the current sprint + naming conventions** with one JQL query:
   ```
   searchJiraIssuesUsingJql(
     jql: "project = <KEY> AND sprint in openSprints() ORDER BY created DESC",
     fields: ["summary","status","issuetype","customfield_10020"],
     maxResults: 15
   )
   ```
   - `customfield_10020` holds sprint objects: `[{id, name, state, ...}]`. Extract the active sprint's `id` — this is what you pass when creating.
   - Skim the recent summaries to match the project's title style (e.g., `feat(scope):`, `fix(scope):`, `test(scope):`, `chore(scope):` — conventional-commits prefix is common in PE).
   - **JQL output is large — it can blow the context budget.** If the result is dumped to a file, parse with `jq` (Bash) instead of reading the whole thing:
     ```bash
     jq -r '.issues.nodes[] | "\(.key) | \(.fields.issuetype.name) | \(.fields.status.name) | \(.fields.summary)"' <file>
     jq '.issues.nodes[0].fields.customfield_10020' <file>   # sprint id lives here
     ```

4. **Draft the ticket** inline in chat. Use this skeleton — adapt sections to the task:

   ```markdown
   **Title:** `<type>(<scope>): <imperative summary>`
   **Type:** Task (default) | Story | Bug — **Sprint:** <name>

   ## Goal
   One-paragraph "what + why".

   ## Scope
   - Bullet the in-scope surface area.

   ## Approach
   1. Numbered steps the assignee can follow.

   ## Acceptance criteria
   - [ ] Verifiable outcome 1
   - [ ] Verifiable outcome 2

   ## Out of scope
   - Things that look related but aren't this ticket.

   ## References
   - Related tickets (PE-XXXX), repos, docs.
   ```

5. **Confirm before creating.** Use `AskUserQuestion` for the tight choices, not free-form back-and-forth:
   - Q1 "Create as drafted, switch type, or tweak first?" — options: `Create as Task`, `Create as Story`, `Tweak first`.
   - Q2 "Add any labels?" — multi-select from likely labels for the project (e.g., `idp`, `selfservice`, component name) plus `No labels`.
   - Skip the question if the user already specified type/labels in their prompt.

6. **Create the issue:**
   ```
   createJiraIssue(
     cloudId: "<id>",
     projectKey: "<KEY>",
     issueTypeName: "Task",
     summary: "<title>",
     contentFormat: "markdown",
     description: "<body>",
     additional_fields: {
       "labels": ["idp"],
       "customfield_10020": <sprint_id>          // integer, not string
     }
   )
   ```
   - Sprint **must** go in `additional_fields.customfield_10020` — there is no top-level `sprint` field.
   - `contentFormat: "markdown"` — Jira renders headings, bullets, and `[ ]` checkboxes correctly. (ADF works too but is more verbose.)
   - Don't set `priority` or `assignee` unless the user asked.

7. **Report the URL.** The response includes `webUrl` — give it back as a clickable link with key + status (`PE-1789` / To Do).

## Conventions worth remembering

- **Title prefix:** match what's already in the sprint. PE uses conventional-commits style (`feat(...)`, `fix(...)`, `test(...)`, `chore(...)`, `refactor(...)`, `docs(...)`).
- **Description sections:** Goal / Scope / Approach / Acceptance criteria / Out of scope / References — adjust for Bug (Repro / Expected / Actual) or Spike (Question / Deliverable).
- **Acceptance criteria:** must be verifiable, not aspirational. "X is documented", "MR merged", "diff reviewed", not "X is good".
- **Labels:** PE often uses single component labels (`idp`, `selfservice`, `devportal`, `kcl`, `configsync`). Don't invent new label taxonomies — match what's already on similar tickets.

## Cached facts

These are stable across sessions but verify on first use of a new session:

- **cloudId:** `REDACTED-ATLASSIAN-CLOUDID` (REDACTED-ATLASSIAN-SITE)
- **Default project:** `PE` (Platform Engineering) — only project the user has Jira access to
- **Sprint custom field:** `customfield_10020`
- **Available issue types (PE):** Epic, Story, Task, Bug, Subtask — Task is the workhorse default

## Anti-patterns

- Don't create the ticket without showing a draft first. The user almost always tweaks the title or scope.
- Don't dump the full JQL search response into context — parse with `jq` against the saved file.
- Don't hardcode sprint IDs (they change every cycle). Always look up `openSprints()` fresh.
- Don't paste the full URL list of related tickets if the user didn't reference them — link only PRs/issues clearly tied to the work.
- Don't use ADF JSON when markdown will do.
