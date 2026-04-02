import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/dispatcher.js', () => ({
  run: vi.fn(),
}));

import * as dispatcher from '../../src/dispatcher.js';
import { handleListLibraries, handleOpenLibrary, libraryTools } from '../../src/tools/libraries.js';

const mockRun = vi.mocked(dispatcher.run);

beforeEach(() => vi.clearAllMocks());

describe('handleListLibraries', () => {
  it('calls list_libraries with JSON-encoded known map', async () => {
    mockRun.mockResolvedValue({ open: [], known: [] });
    await handleListLibraries({});
    expect(mockRun).toHaveBeenCalledWith('list_libraries', [expect.stringContaining('"main"')]);
  });

  it('returns open and known arrays', async () => {
    const fakeData = { open: [{ name: 'main' }], known: [] };
    mockRun.mockResolvedValue(fakeData);
    const result = await handleListLibraries({});
    expect(result).toEqual(fakeData);
  });
});

describe('handleOpenLibrary', () => {
  it('rejects unknown library names', async () => {
    await expect(handleOpenLibrary({ name: 'nonexistent' })).rejects.toThrow('Unknown library');
  });

  it('resolves short name and calls open_library', async () => {
    mockRun.mockResolvedValue({ path: '/some/path', already_open: false });
    await handleOpenLibrary({ name: 'main' });
    expect(mockRun).toHaveBeenCalledWith('open_library', [expect.stringContaining('main.eflibrary')]);
  });
});

describe('libraryTools', () => {
  it('exports two tools', () => {
    expect(libraryTools).toHaveLength(2);
    expect(libraryTools.map((t) => t.name)).toEqual(['list_libraries', 'open_library']);
  });
});
