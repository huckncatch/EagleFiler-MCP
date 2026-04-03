import { z } from 'zod';
import { run } from '../dispatcher.js';
import { resolveLibrary } from '../libraries.js';

const ListRecordsInput = z.object({
  library: z.string(),
  folder_guid: z.string().optional().default(''),
  limit: z.number().int().min(1).max(1000).optional().default(100),
  offset: z.number().int().min(0).optional().default(0),
});

const GetRecordInput = z.object({
  library: z.string(),
  guid: z.string(),
});

const SearchInput = z.object({
  library: z.string(),
  query: z.string(),
  limit: z.number().int().min(1).max(1000).optional().default(100),
  offset: z.number().int().min(0).optional().default(0),
});

const SearchByTagsInput = z.object({
  library: z.string(),
  tags: z.array(z.string()).min(1),
  limit: z.number().int().min(1).max(1000).optional().default(100),
  offset: z.number().int().min(0).optional().default(0),
});

export async function handleListRecords(args: unknown) {
  const { library, folder_guid, limit, offset } = ListRecordsInput.parse(args);
  return run('list_records', [resolveLibrary(library), folder_guid, String(limit), String(offset)]);
}

export async function handleGetRecord(args: unknown) {
  const { library, guid } = GetRecordInput.parse(args);
  return run('get_record', [resolveLibrary(library), guid]);
}

export async function handleSearch(args: unknown) {
  const { library, query, limit, offset } = SearchInput.parse(args);
  return run('search', [resolveLibrary(library), query, String(limit), String(offset)]);
}

export async function handleSearchByTags(args: unknown) {
  const { library, tags, limit, offset } = SearchByTagsInput.parse(args);
  return run('search_by_tags', [resolveLibrary(library), JSON.stringify(tags), String(limit), String(offset)]);
}

export const recordTools = [
  {
    name: 'list_records',
    description:
      'List records in the root of a library or in a specific folder. Returns records[] and total count. Use offset to page when total > records.length.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string', description: 'Short library name or full path' },
        folder_guid: { type: 'string', description: 'GUID of folder to list (omit for root)' },
        limit: { type: 'integer', default: 100, description: 'Max records to return (1–1000)' },
        offset: { type: 'integer', default: 0, description: 'Number of records to skip' },
      },
      required: ['library'],
    },
  },
  {
    name: 'get_record',
    description:
      'Get full details of a single record by GUID: metadata, tags, note text, file path, source URL.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string' },
        guid: { type: 'string' },
      },
      required: ['library', 'guid'],
    },
  },
  {
    name: 'search',
    description:
      'Full-text search within a library. Supports EagleFiler query syntax including tag:tagname. Returns records[] and total.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string' },
        query: { type: 'string', description: 'Search query. Supports tag:tagname syntax.' },
        limit: { type: 'integer', default: 100 },
        offset: { type: 'integer', default: 0 },
      },
      required: ['library', 'query'],
    },
  },
  {
    name: 'search_by_tags',
    description:
      'Find records that have ALL of the specified tags (AND semantics). Uses AppleScript tag access directly. Returns records[] and total.',
    inputSchema: {
      type: 'object',
      properties: {
        library: { type: 'string' },
        tags: { type: 'array', items: { type: 'string' }, minItems: 1 },
        limit: { type: 'integer', default: 100 },
        offset: { type: 'integer', default: 0 },
      },
      required: ['library', 'tags'],
    },
  },
];
