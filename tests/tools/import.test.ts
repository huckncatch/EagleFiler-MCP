import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/dispatcher.js', () => ({ run: vi.fn() }));

import * as dispatcher from '../../src/dispatcher.js';
import {
  handleImportUrl, handleImportText, handleAddFolder,
  handleMoveRecord, handleTrashRecord, importTools,
} from '../../src/tools/import.js';

const mockRun = vi.mocked(dispatcher.run);
beforeEach(() => vi.clearAllMocks());

describe('handleImportUrl', () => {
  it('defaults format to webarchive', async () => {
    mockRun.mockResolvedValue({ guid: 'g', title: 't' });
    await handleImportUrl({ library: 'main', url: 'https://example.com' });
    expect(mockRun.mock.calls[0][1][2]).toBe('webarchive');
  });

  it('rejects invalid format', async () => {
    await expect(
      handleImportUrl({ library: 'main', url: 'https://x.com', format: 'gif' })
    ).rejects.toThrow();
  });

  it('passes empty string for missing folder_guid', async () => {
    mockRun.mockResolvedValue({ guid: 'g', title: 't' });
    await handleImportUrl({ library: 'main', url: 'https://x.com' });
    expect(mockRun.mock.calls[0][1][3]).toBe('');
  });
});

describe('handleImportText', () => {
  it('passes text, title and empty folder_guid', async () => {
    mockRun.mockResolvedValue({ guid: 'g', title: 'My Note' });
    await handleImportText({ library: 'main', text: 'Hello', title: 'My Note' });
    const args = mockRun.mock.calls[0][1];
    expect(args[1]).toBe('Hello');
    expect(args[2]).toBe('My Note');
    expect(args[3]).toBe('');
  });
});

describe('handleAddFolder', () => {
  it('passes empty parent_guid when not provided', async () => {
    mockRun.mockResolvedValue({ guid: 'g', name: 'New' });
    await handleAddFolder({ library: 'main', name: 'New' });
    expect(mockRun.mock.calls[0][1][2]).toBe('');
  });
});

describe('handleMoveRecord', () => {
  it('requires target_folder_guid', async () => {
    await expect(handleMoveRecord({ library: 'main', guid: 'g' })).rejects.toThrow();
  });
});

describe('importTools', () => {
  it('exports 5 tools', () => expect(importTools).toHaveLength(5));
});
