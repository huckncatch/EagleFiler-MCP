import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/dispatcher.js', () => ({ run: vi.fn() }));

import * as dispatcher from '../../src/dispatcher.js';
import {
  handleListRecords,
  handleGetRecord,
  handleSearch,
  handleSearchByTags,
  recordTools,
} from '../../src/tools/records.js';

const mockRun = vi.mocked(dispatcher.run);
beforeEach(() => vi.clearAllMocks());

const fakeData = { records: [], total: 0 };

describe('handleListRecords', () => {
  it('passes library path, empty folder_guid, default limit/offset', async () => {
    mockRun.mockResolvedValue(fakeData);
    await handleListRecords({ library: 'main' });
    expect(mockRun).toHaveBeenCalledWith('list_records', [
      expect.stringContaining('main.eflibrary'),
      '',
      '100',
      '0',
    ]);
  });

  it('passes folder_guid when provided', async () => {
    mockRun.mockResolvedValue(fakeData);
    await handleListRecords({ library: 'main', folder_guid: 'abc', limit: 10, offset: 20 });
    expect(mockRun).toHaveBeenCalledWith('list_records', [
      expect.any(String),
      'abc',
      '10',
      '20',
    ]);
  });

  it('rejects unknown library', async () => {
    await expect(handleListRecords({ library: 'nope' })).rejects.toThrow('Unknown library');
  });
});

describe('handleGetRecord', () => {
  it('passes library path and guid', async () => {
    mockRun.mockResolvedValue({});
    await handleGetRecord({ library: 'main', guid: 'test-guid' });
    expect(mockRun).toHaveBeenCalledWith('get_record', [
      expect.stringContaining('main.eflibrary'),
      'test-guid',
    ]);
  });
});

describe('handleSearch', () => {
  it('passes query and defaults', async () => {
    mockRun.mockResolvedValue(fakeData);
    await handleSearch({ library: 'main', query: 'taxes' });
    expect(mockRun).toHaveBeenCalledWith('search', [
      expect.any(String),
      'taxes',
      '100',
      '0',
    ]);
  });
});

describe('handleSearchByTags', () => {
  it('passes JSON-encoded tags', async () => {
    mockRun.mockResolvedValue(fakeData);
    await handleSearchByTags({ library: 'main', tags: ['2024', 'receipt'] });
    expect(mockRun).toHaveBeenCalledWith('search_by_tags', [
      expect.any(String),
      '["2024","receipt"]',
      '100',
      '0',
    ]);
  });

  it('rejects empty tags array', async () => {
    await expect(handleSearchByTags({ library: 'main', tags: [] })).rejects.toThrow();
  });
});

describe('recordTools', () => {
  it('exports four tools', () => {
    expect(recordTools).toHaveLength(4);
  });
});
