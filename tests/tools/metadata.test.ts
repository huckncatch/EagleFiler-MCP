import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/dispatcher.js', () => ({ run: vi.fn() }));

import * as dispatcher from '../../src/dispatcher.js';
import {
  handleSetTags, handleSetNote, handleFlagRecord,
  handleSetLabel, handleMarkRead, metadataTools,
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
  it('exports 5 tools', () => expect(metadataTools).toHaveLength(5));
});
