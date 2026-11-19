# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Commands

```bash
npm install         # install dependencies
npm run build       # compile src/ to dist/ (tsc)
npm test            # Vitest unit tests
npm run test:watch  # Vitest in watch mode
```

Run one AppleScript directly to test it without the server:

```bash
osascript scripts/search.applescript \
  ~/Dropbox/Apps/EagleFiler/main/main.eflibrary 'tag:receipt' 10 0
```

## Architecture

A TypeScript MCP server (`@modelcontextprotocol/sdk`, stdio) that drives the
EagleFiler app through AppleScript. macOS only.

- **`src/index.ts`**: server entry point. `allTools` collects the tool schemas
  from `src/tools/*.ts`, and the `handlers` map routes each tool name to its
  handler. This file is the list of tools.
- **`src/tools/*.ts`**: one file per tool group. Each exports its tool schemas
  and handlers. Handlers validate arguments with `zod`, resolve the library,
  and call `run()`.
- **`src/dispatcher.ts`**: `run(scriptName, args)` runs
  `scripts/<scriptName>.applescript` with `osascript`, passing arguments as
  `argv`. It parses the script's JSON reply and turns failures into `McpError`.
- **`src/launcher.ts`**: `ensureEagleFilerRunning()` launches EagleFiler before
  each call and waits up to 5 seconds.
- **`src/libraries.ts`**: `KNOWN_LIBRARIES` maps short names to `.eflibrary`
  paths under `~/Dropbox/Apps/EagleFiler`. `resolveLibrary()` also accepts an
  absolute or `~/` path.
- **`scripts/*.applescript`**: one script per tool.

## Key Conventions

**Build and reload**: The server runs `dist/index.js`, which is gitignored. Run
`npm run build` after any change in `src/`, including `KNOWN_LIBRARIES`. The
dispatcher reads the scripts from `scripts/` at runtime, so a script edit needs
no build. A running server keeps the code it loaded at start: reconnect
`eaglefiler` (`/mcp`) or start a new session to load a new build. Claude
Desktop needs a restart.

**Script reply format**: Every script prints one JSON object:
`{"ok": true, "data": ...}` or `{"ok": false, "error": "..."}`. Scripts build
it with `NSJSONSerialization` (`use framework "Foundation"`).

**Tell-block quirk**: Inside `on run argv`, `POSIX path of (file of lib)` fails
with error -1700 within a `tell application "EagleFiler"` block. Collect the
`file of lib` aliases inside the tell block, then call `POSIX path of` and all
Foundation methods outside it.

**AppleScript parser quirks**: `set x to name of every tag of lib` does not
compile (error -2740); write `set x to (get name of every tag of lib)`. `st`
and `after` are reserved words, so they cannot name a handler or a variable.
`count` is a command: call it on an Objective-C object as `x's |count|()`. An
EagleFiler constant (`PDF format`) outside a `tell` block needs `using terms
from application "EagleFiler"`. An AppleScript record reference cannot go into
an `NSMutableArray`; collect references in an AppleScript list. Check a script
with `osacompile -o /dev/null scripts/<name>.applescript`; `npm test` compiles
every script.

**Titles and filenames** (tested through AppleScript): a blank title links the
title to the filename, and a file rename then changes the title. Setting any
non-blank title unlinks it, even a title equal to the filename. Setting a title
never renames the file. No property shows whether a title is linked.

**Tags**: tags are flat. A record count from `every library record of tag`
leaves out trashed records. Adding a tag name in a different case makes a new
tag, so `tag_records` reuses the existing spelling. Renaming a tag onto an
existing name does nothing, without an error. `delete` fails on a tag; tags are
deleted only in the EagleFiler UI. `unread`, `flagged` and `note` are EagleFiler's own
tags: the app keeps `note` on every record with a note, so removing it does
nothing.

**Cross-library moves**: EagleFiler has no move between libraries.
`move_to_library` imports a copy and trashes the original, so the record gets a
new GUID. A live duplicate in the target blocks the import; a trashed one does
not.

**Adding a tool**:

1. Add the schema and handler in the matching `src/tools/*.ts` file.
2. Add the handler to the `handlers` map in `src/index.ts`.
3. Add `scripts/<tool_name>.applescript` with the reply format above.
4. Add tests in `tests/tools/*.test.ts`. The tests mock `run()`, so they do not
   need EagleFiler.
5. Run `npm test` and `npm run build`.

## EagleFiler Reference

EagleFiler ships its own docs in
`/Applications/EagleFiler.app/Contents/Resources/`:

- `EagleFiler.sdef`: the AppleScript dictionary, the authority on what the
  scripts can do. Open it in Script Editor (File ▸ Open Dictionary) or grep it.
- `EagleFiler Help/*.html`: the manual, one page per topic. Read a page with
  `textutil -convert txt -stdout <page>.html`.
- `EagleFiler Manual.pdf`: the same manual as one PDF.

## MCP Registration

Both clients run the server through `~/config/brain/bin/mcp-exec.sh`, which
puts Homebrew's `node` on PATH. The `README.md` registration example is
generic; `~/config/NOTES.md` has the commands for this machine.

```bash
claude mcp add --scope user eaglefiler -- ~/config/brain/bin/mcp-exec.sh \
  node ~/Developer/eaglefiler-mcp/dist/index.js
```

Claude Desktop (`~/Library/Application Support/Claude/claude_desktop_config.json`)
has the same `command` and `args`.

## Cross-repo documentation (Obsidian)

This project's note is the Home vault note whose `repo` field is this
repository's path (`repo: ~/Developer/eaglefiler-mcp`). Find it by searching
the vault for that line (vault location and rules: `~/config/brain/`). Update
it when the tools, the stack, or project status changes.

Decisions, research, and plans worth cross-project visibility go to the vault
through the `vault` skill (log flow).
