import { z } from 'zod';
import { run } from '../dispatcher.js';
import { resolveLibrary } from '../libraries.js';

const LibGuid = { library: z.string(), guid: z.string() };

const SetTagsInput = z.object({ ...LibGuid, tags: z.array(z.string()) });
const SetNoteInput = z.object({ ...LibGuid, text: z.string() });
const FlagInput = z.object({ ...LibGuid, flagged: z.boolean() });
const SetLabelInput = z.object({ ...LibGuid, label: z.number().int().min(0).max(7) });
const MarkReadInput = z.object({ ...LibGuid, read: z.boolean() });
const RenameRecordInput = z
  .object({ ...LibGuid, title: z.string().optional(), filename: z.string().min(1).optional() })
  .refine((a) => a.title !== undefined || a.filename !== undefined, { message: 'Provide title, filename, or both' })
  .refine((a) => a.filename === undefined || !a.filename.includes('/'), { message: 'filename must not contain "/"' });
const ListTagsInput = z.object({ library: z.string() });
const TagRecordsInput = z
  .object({
    library: z.string(),
    guids: z.array(z.string().min(1)).min(1).max(500),
    add: z.array(z.string().min(1)).optional().default([]),
    remove: z.array(z.string().min(1)).optional().default([]),
  })
  .refine((a) => a.add.length + a.remove.length > 0, { message: 'Provide add, remove, or both' });
const RenameTagInput = z.object({ library: z.string(), old_name: z.string().min(1), new_name: z.string().min(1) });

// Built-in tags that EagleFiler manages; never merge or rename them
export const SYSTEM_TAGS = ['unread', 'flagged', 'note', '__deleted__'];

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

export async function handleRenameRecord(args: unknown) {
  const { library, guid, title, filename } = RenameRecordInput.parse(args);
  return run('rename_record', [
    resolveLibrary(library), guid,
    filename === undefined ? '0' : '1', filename ?? '',
    title === undefined ? '0' : '1', title ?? '',
  ]);
}

export async function handleListTags(args: unknown) {
  const { library } = ListTagsInput.parse(args);
  const tags = (await run('list_tags', [resolveLibrary(library)])) as { name: string; count: number }[];
  return tags
    .map((t) => ({ ...t, system: SYSTEM_TAGS.includes(t.name) }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
}

export async function handleTagRecords(args: unknown) {
  const { library, guids, add, remove } = TagRecordsInput.parse(args);
  return run('tag_records', [resolveLibrary(library), JSON.stringify(guids), JSON.stringify(add), JSON.stringify(remove)]);
}

export async function handleRenameTag(args: unknown) {
  const { library, old_name, new_name } = RenameTagInput.parse(args);
  if (SYSTEM_TAGS.includes(old_name)) throw new Error(`"${old_name}" is a built-in tag and cannot be renamed`);
  return run('rename_tag', [resolveLibrary(library), old_name, new_name]);
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
  {
    name: 'rename_record',
    description:
      'Set the title and/or the filename of a record. A blank title links the title to the filename, ' +
      'so it follows later renames. Setting a title never renames the file, and any non-blank title ' +
      '(even one equal to the filename) unlinks it.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guid: { type: 'string', description: 'Record GUID' },
        title: { type: 'string', description: 'New title; "" links the title to the filename' },
        filename: { type: 'string', description: 'New filename without extension (the extension is kept)' },
      },
      required: ['library', 'guid'],
    },
  },
  {
    name: 'list_tags',
    description:
      'List the tags of a library with the number of live (not trashed) records on each, most used first. ' +
      'system=true marks built-in tags (unread, flagged, note, __deleted__).',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
      },
      required: ['library'],
    },
  },
  {
    name: 'tag_records',
    description:
      'Add and/or remove tags on many records at once, keeping their other tags. Tag names match existing ' +
      'tags without regard to case and keep the existing spelling. To merge tag A into B: add B, remove A ' +
      '(an empty tag stays listed until deleted in the EagleFiler UI). Returns one entry per GUID: {guid, tags} or {guid, error}.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        guids: { type: 'array', items: { type: 'string' }, description: 'Record GUIDs (1–500)' },
        add: { type: 'array', items: { type: 'string' }, description: 'Tags to add' },
        remove: { type: 'array', items: { type: 'string' }, description: 'Tags to remove' },
      },
      required: ['library', 'guids'],
    },
  },
  {
    name: 'rename_tag',
    description:
      'Rename a tag on every record that has it. Refuses a new name that already exists (use tag_records to merge) ' +
      'and built-in tags. Tags cannot be deleted through AppleScript.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        old_name: { type: 'string', description: 'Current tag name (exact case)' },
        new_name: { type: 'string', description: 'New tag name' },
      },
      required: ['library', 'old_name', 'new_name'],
    },
  },
];
