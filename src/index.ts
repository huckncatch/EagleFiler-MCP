import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  McpError,
  ErrorCode,
} from '@modelcontextprotocol/sdk/types.js';

import { libraryTools, handleListLibraries, handleOpenLibrary } from './tools/libraries.js';
import { recordTools, handleListRecords, handleGetRecord, handleSearch, handleSearchByTags } from './tools/records.js';
import { metadataTools, handleSetTags, handleSetNote, handleFlagRecord, handleSetLabel, handleMarkRead } from './tools/metadata.js';
import { importTools, handleImportUrl, handleImportText, handleAddFolder, handleMoveRecord, handleTrashRecord } from './tools/import.js';

const allTools = [...libraryTools, ...recordTools, ...metadataTools, ...importTools];

const handlers: Record<string, (args: unknown) => Promise<unknown>> = {
  list_libraries:   handleListLibraries,
  open_library:     handleOpenLibrary,
  list_records:     handleListRecords,
  get_record:       handleGetRecord,
  search:           handleSearch,
  search_by_tags:   handleSearchByTags,
  set_tags:         handleSetTags,
  set_note:         handleSetNote,
  flag_record:      handleFlagRecord,
  set_label:        handleSetLabel,
  mark_read:        handleMarkRead,
  import_url:       handleImportUrl,
  import_text:      handleImportText,
  add_folder:       handleAddFolder,
  move_record:      handleMoveRecord,
  trash_record:     handleTrashRecord,
};

const server = new Server(
  { name: 'eaglefiler', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: allTools }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const handler = handlers[name];
  if (!handler) {
    throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
  }
  const result = await handler(args ?? {});
  return {
    content: [{ type: 'text', text: JSON.stringify(result, null, 2) }],
  };
});

const transport = new StdioServerTransport();
await server.connect(transport);
