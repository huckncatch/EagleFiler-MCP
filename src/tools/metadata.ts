import { z } from 'zod';
import { run } from '../dispatcher.js';
import { resolveLibrary } from '../libraries.js';

const LibGuid = { library: z.string(), guid: z.string() };

const SetTagsInput = z.object({ ...LibGuid, tags: z.array(z.string()) });
const SetNoteInput = z.object({ ...LibGuid, text: z.string() });
const FlagInput = z.object({ ...LibGuid, flagged: z.boolean() });
const SetLabelInput = z.object({ ...LibGuid, label: z.number().int().min(0).max(7) });
const MarkReadInput = z.object({ ...LibGuid, read: z.boolean() });

export async function handleSetTags(args: unknown) {
  const { library, guid, tags } = SetTagsInput.parse(args);
  return run('set_tags', [resolveLibrary(library), guid, JSON.stringify(tags)]);
}

export async function handleSetNote(args: unknown) {
  const { library, guid, text } = SetNoteInput.parse(args);
  return run('set_note', [resolveLibrary(library), guid, text]);
}

export async function handleFlagRecord(args: unknown) {
  const { library, guid, flagged } = FlagInput.parse(args);
  return run('flag_record', [resolveLibrary(library), guid, String(flagged)]);
}

export async function handleSetLabel(args: unknown) {
  const { library, guid, label } = SetLabelInput.parse(args);
  return run('set_label', [resolveLibrary(library), guid, String(label)]);
}

export async function handleMarkRead(args: unknown) {
  const { library, guid, read } = MarkReadInput.parse(args);
  return run('mark_read', [resolveLibrary(library), guid, String(read)]);
}

export const metadataTools = [
  {
    name: 'set_tags',
    description: 'Replace the tag set on a record. Provide the complete desired tag list.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guid: { type: 'string', description: 'Record GUID' },
        tags: { type: 'array', items: { type: 'string' }, description: 'Complete replacement tag list (empty list clears all tags)' },
      },
      required: ['library', 'guid', 'tags'],
    },
  },
  {
    name: 'set_note',
    description: 'Write plain-text note on a record (stored as RTF by EagleFiler).',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guid: { type: 'string', description: 'Record GUID' },
        text: { type: 'string', description: 'Note text content' },
      },
      required: ['library', 'guid', 'text'],
    },
  },
  {
    name: 'flag_record',
    description: 'Set the flagged state of a record.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guid: { type: 'string', description: 'Record GUID' },
        flagged: { type: 'boolean', description: 'True to flag, false to unflag' },
      },
      required: ['library', 'guid', 'flagged'],
    },
  },
  {
    name: 'set_label',
    description: 'Set the label colour of a record. 0=none 1=grey 2=green 3=purple 4=blue 5=yellow 6=red 7=orange.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guid: { type: 'string', description: 'Record GUID' },
        label: { type: 'integer', minimum: 0, maximum: 7, description: 'Label colour index (0=none, 1=grey, 2=green, 3=purple, 4=blue, 5=yellow, 6=red, 7=orange)' },
      },
      required: ['library', 'guid', 'label'],
    },
  },
  {
    name: 'mark_read',
    description: 'Mark a record as read (read=true) or unread (read=false).',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guid: { type: 'string', description: 'Record GUID' },
        read: { type: 'boolean', description: 'True to mark read, false to mark unread' },
      },
      required: ['library', 'guid', 'read'],
    },
  },
];
