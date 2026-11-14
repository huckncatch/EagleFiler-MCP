import fs from 'fs';
import os from 'os';
import path from 'path';
import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/dispatcher.js', () => ({ run: vi.fn() }));

import * as dispatcher from '../../src/dispatcher.js';
import {
  handleImportUrl, handleImportText, handleImportFile, handleAddFolder,
  handleMoveRecord, handleMoveToLibrary, handleTrashRecord, importTools,
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

describe('handleImportFile', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'ef-import-'));
  const file = path.join(tmp, 'a.pdf');
  fs.writeFileSync(file, 'x');

  it('moves by default and passes empty metadata', async () => {
    mockRun.mockResolvedValue([{ path: file, guid: 'g', title: 'a' }]);
    await handleImportFile({ library: 'main', paths: [file] });
    expect(mockRun.mock.calls[0][0]).toBe('import_file');
    const args = mockRun.mock.calls[0][1];
    expect(args[1]).toBe(JSON.stringify([file]));
    expect(args.slice(2)).toEqual(['', '[]', '', 'true']);
  });

  it('passes tags, note and delete_source false', async () => {
    mockRun.mockResolvedValue([]);
    await handleImportFile({ library: 'main', paths: [file], tags: ['receipt'], note: 'n', delete_source: false });
    expect(mockRun.mock.calls[0][1].slice(3)).toEqual(['["receipt"]', 'n', 'false']);
  });

  it('expands ~/ paths', async () => {
    const home = path.join(os.homedir(), '.ef-import-test');
    fs.writeFileSync(home, 'x');
    try {
      mockRun.mockResolvedValue([]);
      await handleImportFile({ library: 'main', paths: ['~/.ef-import-test'] });
      expect(mockRun.mock.calls[0][1][1]).toBe(JSON.stringify([home]));
    } finally {
      fs.unlinkSync(home);
    }
  });

  it('rejects a missing file before calling run', async () => {
    await expect(handleImportFile({ library: 'main', paths: [path.join(tmp, 'nope.pdf')] })).rejects.toThrow(/not found/);
    expect(mockRun).not.toHaveBeenCalled();
  });

  it('rejects a relative path', async () => {
    await expect(handleImportFile({ library: 'main', paths: ['a.pdf'] })).rejects.toThrow(/absolute/);
  });

  it('rejects an empty path list', async () => {
    await expect(handleImportFile({ library: 'main', paths: [] })).rejects.toThrow();
  });

  it('rejects a file inside the library folder', async () => {
    const libDir = fs.mkdtempSync(path.join(os.tmpdir(), 'ef-lib-'));
    const inner = path.join(libDir, 'Files', 'b.pdf');
    fs.mkdirSync(path.dirname(inner));
    fs.writeFileSync(inner, 'x');
    await expect(
      handleImportFile({ library: path.join(libDir, 'x.eflibrary'), paths: [inner] })
    ).rejects.toThrow(/inside the library/);
    expect(mockRun).not.toHaveBeenCalled();
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
  it('exports 7 tools', () => expect(importTools).toHaveLength(7));
});

describe('handleMoveToLibrary', () => {
  it('passes both library paths and an empty folder guid', async () => {
    mockRun.mockResolvedValue({});
    await handleMoveToLibrary({ library: 'main', guid: 'g', target_library: 'rental' });
    const args = mockRun.mock.calls[0][1];
    expect(args[0]).toContain('main.eflibrary');
    expect(args[1]).toBe('g');
    expect(args[2]).toContain('rental.eflibrary');
    expect(args[3]).toBe('');
  });

  it('refuses the same library as source and target', async () => {
    await expect(handleMoveToLibrary({ library: 'main', guid: 'g', target_library: 'main' })).rejects.toThrow();
    expect(mockRun).not.toHaveBeenCalled();
  });
});
