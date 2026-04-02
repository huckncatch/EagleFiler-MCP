import { z } from 'zod';
import { run } from '../dispatcher.js';
import { resolveLibrary, KNOWN_LIBRARIES } from '../libraries.js';

const OpenLibraryInput = z.object({ name: z.string() });

export async function handleListLibraries(_args: unknown) {
  return run('list_libraries', [JSON.stringify(KNOWN_LIBRARIES)]);
}

export async function handleOpenLibrary(args: unknown) {
  const { name } = OpenLibraryInput.parse(args);
  const resolved = resolveLibrary(name); // throws for unknown names
  return run('open_library', [resolved]);
}

export const libraryTools = [
  {
    name: 'list_libraries',
    description:
      'List all known EagleFiler libraries and which ones are currently open. Returns open[] and known[] arrays each with name, path, is_open.',
    inputSchema: { type: 'object', properties: {}, required: [] },
  },
  {
    name: 'open_library',
    description:
      'Open an EagleFiler library. Accepts a short name (e.g. "main", "development") or full path. No-op if already open.',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Short library name or full .eflibrary path' },
      },
      required: ['name'],
    },
  },
];
