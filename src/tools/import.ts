import fs from 'fs';
import os from 'os';
import path from 'path';
import { z } from 'zod';
import { run } from '../dispatcher.js';
import { resolveLibrary } from '../libraries.js';

export const VALID_FORMATS = ['bookmark', 'html', 'pdf', 'pdf_single_page', 'plain_text', 'webarchive'] as const;

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

const ImportFileInput = z.object({
  library: z.string(),
  paths: z.array(z.string().min(1)).min(1),
  folder_guid: z.string().optional().default(''),
  tags: z.array(z.string()).optional().default([]),
  note: z.string().optional().default(''),
  delete_source: z.boolean().optional().default(true),
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

const MoveToLibraryInput = z.object({
  library: z.string(),
  guid: z.string(),
  target_library: z.string(),
  target_folder_guid: z.string().optional().default(''),
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

export async function handleImportFile(args: unknown) {
  const { library, paths, folder_guid, tags, note, delete_source } = ImportFileInput.parse(args);
  const libPath = resolveLibrary(library);
  const libRoot = path.dirname(libPath) + path.sep;
  const resolved = paths.map((p) => {
    const abs = p.startsWith('~/') ? path.join(os.homedir(), p.slice(2)) : p;
    if (!path.isAbsolute(abs)) throw new Error(`Path must be absolute or start with ~/: "${p}"`);
    const norm = path.resolve(abs);
    if (!fs.existsSync(norm)) throw new Error(`File not found: "${p}"`);
    if (norm.startsWith(libRoot)) throw new Error(`File is inside the library folder: "${p}"`);
    return norm;
  });
  return run('import_file', [
    libPath, JSON.stringify(resolved), folder_guid, JSON.stringify(tags), note, String(delete_source),
  ]);
}

export async function handleAddFolder(args: unknown) {
  const { library, name, parent_guid } = AddFolderInput.parse(args);
  return run('add_folder', [resolveLibrary(library), name, parent_guid]);
}

export async function handleMoveRecord(args: unknown) {
  const { library, guid, target_folder_guid } = MoveInput.parse(args);
  return run('move_record', [resolveLibrary(library), guid, target_folder_guid]);
}

export async function handleMoveToLibrary(args: unknown) {
  const { library, guid, target_library, target_folder_guid } = MoveToLibraryInput.parse(args);
  const src = resolveLibrary(library);
  const dst = resolveLibrary(target_library);
  if (path.resolve(src) === path.resolve(dst)) throw new Error('Source and target are the same library; use move_record');
  return run('move_to_library', [src, guid, dst, target_folder_guid]);
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
    name: 'import_file',
    description:
      'Import local files into a library. Moves each file into the library by default (delete_source: true). ' +
      'Returns one entry per path: {path, guid, title}, or {path, error} for a file that was not imported. ' +
      'A refused duplicate keeps its source file.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        paths: { type: 'array', items: { type: 'string' }, description: 'Absolute or ~/ paths of the files to import' },
        folder_guid: { type: 'string', description: 'Destination folder GUID (omit for root)' },
        tags: { type: 'array', items: { type: 'string' }, description: 'Tags to set on each new record' },
        note: { type: 'string', description: 'Note to set on each new record' },
        delete_source: {
          type: 'boolean',
          default: true,
          description: 'Delete each source file after a successful import (move). false keeps it (copy).',
        },
      },
      required: ['library', 'paths'],
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
    name: 'move_to_library',
    description:
      'Move a record to another library. EagleFiler has no native move, so this imports a copy with its tags, ' +
      'note, title, source URL, from, label, flag, read state and added date, checks the checksum, then moves ' +
      'the original to the source library trash. The copy gets a new GUID: x-eaglefiler links to the old record ' +
      'stop working, so the result returns old_url and new_url. Refused, with the original kept, if the target ' +
      'already holds the same file (live, not trashed). Folders are refused. Both libraries must be open.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Source library: short name or full path' },
        guid: { type: 'string', description: 'Record GUID to move' },
        target_library: { type: 'string', description: 'Target library: short name or full path' },
        target_folder_guid: { type: 'string', description: 'Destination folder GUID in the target (omit for root)' },
      },
      required: ['library', 'guid', 'target_library'],
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
