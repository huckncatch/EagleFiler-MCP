import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/dispatcher.js', () => ({ run: vi.fn() }));

import * as dispatcher from '../../src/dispatcher.js';
import {
  handleSetTags, handleSetNote, handleFlagRecord,
  handleSetLabel, handleMarkRead, metadataTools,
  handleRenameRecord, handleListTags, handleTagRecords, handleRenameTag,
} from '../../src/tools/metadata.js';

const mockRun = vi.mocked(dispatcher.run);
beforeEach(() => vi.clearAllMocks());

describe('handleSetTags', () => {
  it('passes JSON-encoded tags', async () => {
    mockRun.mockResolvedValue({ guid: 'g', tags: ['a'] });
    await handleSetTags({ library: 'main', guid: 'g', tags: ['a', 'b'] });
    const args = mockRun.mock.calls[0][1];
    expect(JSON.parse(args[2])).toEqual(['a', 'b']);
  });
});

describe('handleSetNote', () => {
  it('passes library path, guid, and text in correct order', async () => {
    mockRun.mockResolvedValue({ guid: 'g' });
    await handleSetNote({ library: 'main', guid: 'g', text: 'My note' });
    const args = mockRun.mock.calls[0][1];
    expect(args[0]).toContain('main.eflibrary');
    expect(args[1]).toBe('g');
    expect(args[2]).toBe('My note');
  });
});

describe('handleFlagRecord', () => {
  it('passes "true" string for flagged=true', async () => {
    mockRun.mockResolvedValue({});
    await handleFlagRecord({ library: 'main', guid: 'g', flagged: true });
    expect(mockRun.mock.calls[0][1][2]).toBe('true');
  });

  it('passes "false" string for flagged=false', async () => {
    mockRun.mockResolvedValue({});
    await handleFlagRecord({ library: 'main', guid: 'g', flagged: false });
    expect(mockRun.mock.calls[0][1][2]).toBe('false');
  });
});

describe('handleSetLabel', () => {
  it('rejects label out of range', async () => {
    await expect(handleSetLabel({ library: 'main', guid: 'g', label: 8 })).rejects.toThrow();
    await expect(handleSetLabel({ library: 'main', guid: 'g', label: -1 })).rejects.toThrow();
  });

  it('passes label as string', async () => {
    mockRun.mockResolvedValue({});
    await handleSetLabel({ library: 'main', guid: 'g', label: 3 });
    expect(mockRun.mock.calls[0][1][2]).toBe('3');
  });
});

describe('handleMarkRead', () => {
  it('passes "true" when read=true', async () => {
    mockRun.mockResolvedValue({});
    await handleMarkRead({ library: 'main', guid: 'g', read: true });
    expect(mockRun.mock.calls[0][1][2]).toBe('true');
  });
});

describe('metadataTools', () => {
  it('exports 9 tools', () => expect(metadataTools).toHaveLength(9));
});

describe('handleRenameRecord', () => {
  it('passes set flags and values for title only', async () => {
    mockRun.mockResolvedValue({});
    await handleRenameRecord({ library: 'main', guid: 'g', title: 'New' });
    expect(mockRun.mock.calls[0][1].slice(1)).toEqual(['g', '0', '', '1', 'New']);
  });

  it('passes a blank title to relink it', async () => {
    mockRun.mockResolvedValue({});
    await handleRenameRecord({ library: 'main', guid: 'g', filename: 'f', title: '' });
    expect(mockRun.mock.calls[0][1].slice(1)).toEqual(['g', '1', 'f', '1', '']);
  });

  it('rejects a call with neither title nor filename', async () => {
    await expect(handleRenameRecord({ library: 'main', guid: 'g' })).rejects.toThrow();
  });

  it('rejects an empty filename or one with a slash', async () => {
    await expect(handleRenameRecord({ library: 'main', guid: 'g', filename: '' })).rejects.toThrow();
    await expect(handleRenameRecord({ library: 'main', guid: 'g', filename: 'a/b' })).rejects.toThrow();
  });
});

describe('handleListTags', () => {
  it('sorts by count and marks system tags', async () => {
    mockRun.mockResolvedValue([
      { name: 'b', count: 1 }, { name: 'unread', count: 9 }, { name: 'a', count: 1 },
    ]);
    const result = await handleListTags({ library: 'main' });
    expect(result).toEqual([
      { name: 'unread', count: 9, system: true },
      { name: 'a', count: 1, system: false },
      { name: 'b', count: 1, system: false },
    ]);
  });
});

describe('handleTagRecords', () => {
  it('passes JSON-encoded guids, add and remove', async () => {
    mockRun.mockResolvedValue([]);
    await handleTagRecords({ library: 'main', guids: ['g1', 'g2'], add: ['x'] });
    const args = mockRun.mock.calls[0][1];
    expect(JSON.parse(args[1])).toEqual(['g1', 'g2']);
    expect(JSON.parse(args[2])).toEqual(['x']);
    expect(JSON.parse(args[3])).toEqual([]);
  });

  it('rejects a call with nothing to add or remove', async () => {
    await expect(handleTagRecords({ library: 'main', guids: ['g'] })).rejects.toThrow();
  });

  it('rejects an empty guid list', async () => {
    await expect(handleTagRecords({ library: 'main', guids: [], add: ['x'] })).rejects.toThrow();
  });
});

describe('handleRenameTag', () => {
  it('passes old and new names', async () => {
    mockRun.mockResolvedValue({});
    await handleRenameTag({ library: 'main', old_name: 'geneology', new_name: 'genealogy' });
    expect(mockRun.mock.calls[0][1].slice(1)).toEqual(['geneology', 'genealogy']);
  });

  it('refuses built-in tags', async () => {
    await expect(handleRenameTag({ library: 'main', old_name: 'unread', new_name: 'x' })).rejects.toThrow();
    expect(mockRun).not.toHaveBeenCalled();
  });
});
