import { describe, it, expect } from 'vitest';
import { resolveLibrary, KNOWN_LIBRARIES } from '../src/libraries.js';
import os from 'os';

const HOME = os.homedir();
const BASE = `${HOME}/Dropbox/Apps/EagleFiler`;

describe('KNOWN_LIBRARIES', () => {
  it('contains main', () => {
    expect(KNOWN_LIBRARIES['main']).toBe(`${BASE}/main/main.eflibrary`);
  });
  it('contains all 9 libraries', () => {
    expect(Object.keys(KNOWN_LIBRARIES)).toHaveLength(9);
  });
});

describe('resolveLibrary', () => {
  it('resolves a known short name', () => {
    expect(resolveLibrary('main')).toBe(`${BASE}/main/main.eflibrary`);
  });
  it('passes through an absolute path unchanged', () => {
    const p = '/tmp/test.eflibrary';
    expect(resolveLibrary(p)).toBe(p);
  });
  it('expands ~ paths', () => {
    expect(resolveLibrary('~/some/lib.eflibrary')).toBe(`${HOME}/some/lib.eflibrary`);
  });
  it('throws for unknown short names', () => {
    expect(() => resolveLibrary('nonexistent')).toThrow('Unknown library');
  });
});
