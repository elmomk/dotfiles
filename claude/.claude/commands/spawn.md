Spawn one crew session in the background: a worker for one merge request, or a scout for a question.

Usage: `/spawn [scout|ship] <what to do>`

The default is `scout`. The session runs in the background under `crew tick`; nothing here waits for it.

1. The first word is the shape if it is `scout` or `ship`; otherwise the shape is `scout` and all of `$ARGUMENTS` is the task.
2. The repository is `git rev-parse --show-toplevel` here, unless the task names another.
3. Write a self-contained brief: the files, the change or the question, how to check it, and what done means. The session sees nothing of this conversation.
4. Pick a short name (lowercase letters, digits, dashes) and the effort from `crew spawn --help`.
5. Run it once:

   ```bash
   crew spawn --kind <ship|scout> -n <name> --repo <repo> --effort <level> "<brief>"
   ```

6. Tell the user the name and that `crew status <name>` shows it. Do not wait or poll.

A ship ends with a merge request the crew opens for it. A scout's report lands in `~/.local/state/crew/findings/<name>.md`.
