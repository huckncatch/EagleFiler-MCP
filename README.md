# EagleFiler MCP Server

A [Model Context Protocol](https://modelcontextprotocol.io) server that gives AI assistants (Claude, etc.) full read/write access to [EagleFiler](https://c-command.com/eaglefiler/) libraries on macOS.

## Requirements

- macOS (uses AppleScript + `osascript`)
- [EagleFiler](https://c-command.com/eaglefiler/) installed and licensed
- Node.js 18+

## Installation

```bash
npm install
npm run build
```

Register in your MCP client (e.g. `~/.config/claude/settings.json`):

```json
{
  "mcpServers": {
    "eaglefiler": {
      "command": "node",
      "args": ["/path/to/eaglefiler-mcp/dist/index.js"]
    }
  }
}
```

## Configuration

Known libraries are defined in `src/libraries.ts`. Edit `KNOWN_LIBRARIES` to match your library paths:

```ts
export const KNOWN_LIBRARIES: Record<string, string> = {
  main:        '/Users/you/Dropbox/Apps/EagleFiler/main/main.eflibrary',
  development: '/Users/you/Dropbox/Apps/EagleFiler/development/development.eflibrary',
  // ...
};
```

After editing, rebuild: `npm run build`.

All tools accept either a short name (`"main"`) or an absolute path to the `.eflibrary` file.

## Tools

### Libraries

| Tool | Description |
|------|-------------|
| `list_libraries` | List all known libraries and which are currently open |
| `open_library` | Open a library by short name or path |

### Records

| Tool | Description |
|------|-------------|
| `list_records` | List records in a library root or folder, with pagination |
| `get_record` | Get full details of a record by GUID (metadata, tags, note, file path, URL) |
| `search` | Full-text search; supports EagleFiler query syntax including `tag:tagname` |
| `search_by_tags` | Find records matching ALL specified tags (AND semantics) |

### Metadata

| Tool | Description |
|------|-------------|
| `set_tags` | Replace a record's tag set (provide the complete desired list) |
| `set_note` | Write a plain-text note on a record |
| `flag_record` | Flag or unflag a record |
| `set_label` | Set label colour (0=none 1=grey 2=green 3=purple 4=blue 5=yellow 6=red 7=orange) |
| `mark_read` | Mark a record as read or unread |

### Import & Structure

| Tool | Description |
|------|-------------|
| `import_url` | Import a URL as bookmark, HTML, PDF, plain text, or web archive |
| `import_text` | Create a new `.txt` record with provided content |
| `add_folder` | Create a new folder in a library |
| `move_record` | Move a record to a different folder within the same library |
| `trash_record` | Move a record to the library trash (recoverable from EagleFiler) |

### Import formats

`import_url` accepts: `bookmark` | `html` | `pdf` | `pdf_single_page` | `plain_text` | `webarchive` (default: `webarchive`)

## Architecture

```
src/
  index.ts          # MCP server entry point, tool dispatch
  libraries.ts      # KNOWN_LIBRARIES map, resolveLibrary()
  dispatcher.ts     # runs osascript with a named script + argv
  tools/
    libraries.ts    # list_libraries, open_library
    records.ts      # list_records, get_record, search, search_by_tags
    metadata.ts     # set_tags, set_note, flag_record, set_label, mark_read
    import.ts       # import_url, import_text, add_folder, move_record, trash_record
scripts/
  *.applescript     # one script per tool, called by dispatcher via osascript
```

Each tool is implemented as an AppleScript that receives arguments via `argv` and returns a JSON string:

```json
{ "ok": true, "data": { ... } }
{ "ok": false, "error": "description" }
```

### AppleScript / ASObjC notes

All scripts use `use framework "Foundation"` for JSON serialisation via `NSJSONSerialization`. A key implementation detail: inside an `on run argv` handler, `POSIX path of (file of lib)` fails with error -1700 when called inside a `tell application "EagleFiler"` block. The fix used throughout is to collect `file of lib` alias objects inside the tell block, then call `POSIX path of f` and all Foundation methods outside the tell block.

## Development

```bash
npm run build       # compile TypeScript → dist/
npm test            # run Vitest unit tests
npm run test:watch  # watch mode
```

Scripts can be tested directly:

```bash
# List records from the main library
osascript scripts/list_records.applescript \
  '/path/to/main.eflibrary' '' 10 0

# Search
osascript scripts/search.applescript \
  '/path/to/main.eflibrary' 'tag:receipt' 10 0

# List libraries (pass known libraries as JSON)
osascript scripts/list_libraries.applescript \
  '{"main":"/path/to/main.eflibrary"}'
```

## License

MIT
