import { z } from 'zod';
import { run } from '../dispatcher.js';
import { resolveLibrary } from '../libraries.js';

const VALID_FORMATS = ['bookmark', 'html', 'pdf', 'pdf_single_page', 'plain_text', 'webarchive'] as const;

const ImportUrlInput = z.object({
  library: z.string(),
  url: z.string().url(),
  format: z.enum(VALID_FORMATS).optional().default('webarchive'),
  folder_guid: z.string().optional().default(''),
});

const ImportTextInput = z.object({
  library: z.string(),
  text: z.string(),
  title: z.string(),
  folder_guid: z.string().optional().default(''),
});

const AddFolderInput = z.object({
  library: z.string(),
  name: z.string().min(1),
  parent_guid: z.string().optional().default(''),
});

const MoveInput = z.object({
  library: z.string(),
  guid: z.string(),
  target_folder_guid: z.string(),
});

const TrashInput = z.object({
  library: z.string(),
  guid: z.string(),
});

export async function handleImportUrl(args: unknown) {
  const { library, url, format, folder_guid } = ImportUrlInput.parse(args);
  return run('import_url', [resolveLibrary(library), url, format, folder_guid]);
}

export async function handleImportText(args: unknown) {
  const { library, text, title, folder_guid } = ImportTextInput.parse(args);
  return run('import_text', [resolveLibrary(library), text, title, folder_guid]);
}

export async function handleAddFolder(args: unknown) {
  const { library, name, parent_guid } = AddFolderInput.parse(args);
  return run('add_folder', [resolveLibrary(library), name, parent_guid]);
}

export async function handleMoveRecord(args: unknown) {
  const { library, guid, target_folder_guid } = MoveInput.parse(args);
  return run('move_record', [resolveLibrary(library), guid, target_folder_guid]);
}

export async function handleTrashRecord(args: unknown) {
  const { library, guid } = TrashInput.parse(args);
  return run('trash_record', [resolveLibrary(library), guid]);
}

export const importTools = [
  {
    name: 'import_url',
    description: 'Import a URL into a library. Returns guid and title of the new record.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        url: { type: 'string', format: 'uri', description: 'URL to import' },
        format: {
          type: 'string',
          enum: VALID_FORMATS,
          default: 'webarchive',
          description: 'Format: bookmark | html | pdf | pdf_single_page | plain_text | webarchive',
        },
        folder_guid: { type: 'string', description: 'Destination folder GUID (omit for root)' },
      },
      required: ['library', 'url'],
    },
  },
  {
    name: 'import_text',
    description: 'Create a new .txt plain-text record in a library.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        text: { type: 'string', description: 'Text content for the new record' },
        title: { type: 'string', description: 'Title (filename without extension)' },
        folder_guid: { type: 'string', description: 'Destination folder GUID (omit for root)' },
      },
      required: ['library', 'text', 'title'],
    },
  },
  {
    name: 'add_folder',
    description: 'Create a new folder in a library. Returns guid and name of the new folder.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        name: { type: 'string', description: 'Folder name' },
        parent_guid: { type: 'string', description: 'Parent folder GUID (omit for root)' },
      },
      required: ['library', 'name'],
    },
  },
  {
    name: 'move_record',
    description: 'Move a record to a different folder within the same library.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guid: { type: 'string', description: 'Record GUID to move' },
        target_folder_guid: { type: 'string', description: 'GUID of the destination folder' },
      },
      required: ['library', 'guid', 'target_folder_guid'],
    },
  },
  {
    name: 'trash_record',
    description: "Move a record to the library trash. Not permanently deleted — recoverable from EagleFiler's trash.",
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guid: { type: 'string', description: 'Record GUID to trash' },
      },
      required: ['library', 'guid'],
    },
  },
];
