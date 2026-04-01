import { describe, it, expect, vi, beforeEach } from 'vitest';
import { McpError } from '@modelcontextprotocol/sdk/types.js';
import { promisify } from 'util';

// Mock child_process before importing dispatcher
vi.mock('child_process', () => {
  let currentImpl: ((cmd: string, args: string[], cb: Function) => void) | null = null;

  const mock = vi.fn((cmd: string, args: string[], cb: Function) => {
    if (currentImpl) {
      return currentImpl(cmd, args, cb);
    }
    // Default: call callback with empty strings
    setImmediate(() => cb(null, '', ''));
  });

  // Add the custom promisify handler that uses the real implementation
  mock[promisify.custom] = (cmd: string, args: string[]) => {
    return new Promise((resolve, reject) => {
      mock(cmd, args, (err: Error | null, stdout: string, stderr: string) => {
        if (err) reject(err);
        else resolve({ stdout, stderr });
      });
    });
  };

  // Store reference to set implementations
  (mock as any)._setImpl = (impl: typeof currentImpl) => {
    currentImpl = impl;
  };

  return { execFile: mock };
});

// Mock osascript launch helper
vi.mock('../src/launcher.js', () => ({
  ensureEagleFilerRunning: vi.fn().mockResolvedValue(undefined),
}));

import * as cp from 'child_process';
import { run } from '../src/dispatcher.js';

const mockExecFile = vi.mocked(cp.execFile);

function makeExecFileImpl(stdout: string, stderr = '', code = 0) {
  return (_cmd: string, _args: string[], cb: Function) => {
    setImmediate(() => {
      if (code !== 0) {
        const err = Object.assign(new Error('osascript failed'), { code });
        cb(err, '', stderr);
      } else {
        cb(null, stdout, stderr);
      }
    });
  };
}

beforeEach(() => vi.clearAllMocks());

describe('run', () => {
  it('returns parsed data on ok:true response', async () => {
    const impl = makeExecFileImpl(JSON.stringify({ ok: true, data: { name: 'test' } }));
    (mockExecFile as any)._setImpl(impl);
    const result = await run('list_libraries', []);
    expect(result).toEqual({ name: 'test' });
  });

  it('throws McpError on ok:false response', async () => {
    (mockExecFile as any)._setImpl(
      makeExecFileImpl(JSON.stringify({ ok: false, error: 'library not found' }))
    );
    await expect(run('list_libraries', [])).rejects.toThrow('library not found');
  });

  it('throws McpError when osascript exits non-zero', async () => {
    (mockExecFile as any)._setImpl(
      makeExecFileImpl('', 'execution error: EagleFiler got an error', 1)
    );
    await expect(run('list_libraries', [])).rejects.toThrow(McpError);
  });

  it('throws McpError on invalid JSON output', async () => {
    (mockExecFile as any)._setImpl(makeExecFileImpl('not json'));
    await expect(run('list_libraries', [])).rejects.toThrow(McpError);
  });

  it('passes args as positional parameters to osascript', async () => {
    (mockExecFile as any)._setImpl(
      makeExecFileImpl(JSON.stringify({ ok: true, data: {} }))
    );
    await run('get_record', ['/path/to/lib.eflibrary', 'abc-guid']);
    const [, args] = mockExecFile.mock.calls[0];
    expect(args[1]).toBe('/path/to/lib.eflibrary');
    expect(args[2]).toBe('abc-guid');
  });
});
