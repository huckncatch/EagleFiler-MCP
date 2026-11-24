import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { promisify } from 'util';

// Each osascript call is answered by `respond`, which tests replace
let respond: (script: string) => string = () => '';
const calls: string[] = [];

vi.mock('child_process', () => {
  const mock = vi.fn();
  (mock as any)[promisify.custom] = (_cmd: string, args: string[]) => {
    const script = args[args.length - 1];
    calls.push(script);
    return Promise.resolve({ stdout: respond(script), stderr: '' });
  };
  return { execFile: mock };
});

import { ensureEagleFilerRunning } from '../src/launcher.js';

const isProcessCheck = (s: string) => s.includes('System Events');
const isLibraryCount = (s: string) => s.includes('count of library documents');

describe('ensureEagleFilerRunning', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    calls.length = 0;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('returns at once when EagleFiler is already running', async () => {
    respond = (s) => (isProcessCheck(s) ? 'true' : '');
    await ensureEagleFilerRunning();
    expect(calls.filter(isLibraryCount)).toHaveLength(0);
  });

  it('after a launch, waits until the open libraries stop changing', async () => {
    let launched = false;
    const counts = ['0', '0', '1', '2', '2', '2', '2'];
    respond = (s) => {
      if (s.includes('to launch')) { launched = true; return ''; }
      if (isProcessCheck(s)) return launched ? 'true' : 'false';
      if (isLibraryCount(s)) return counts.shift() ?? '2';
      return '';
    };
    const done = ensureEagleFilerRunning();
    await vi.runAllTimersAsync();
    await done;
    // 0, 0, 1, 2, then 2 twice more: stable for two polls
    expect(calls.filter(isLibraryCount)).toHaveLength(6);
  });

  it('after a launch, stops waiting when no library reopens', async () => {
    let launched = false;
    respond = (s) => {
      if (s.includes('to launch')) { launched = true; return ''; }
      if (isProcessCheck(s)) return launched ? 'true' : 'false';
      if (isLibraryCount(s)) return '0';
      return '';
    };
    const done = ensureEagleFilerRunning();
    await vi.runAllTimersAsync();
    await done;
    // 10 s limit at one poll per 500 ms
    expect(calls.filter(isLibraryCount)).toHaveLength(20);
  });

  it('throws when EagleFiler does not start', async () => {
    respond = (s) => (isProcessCheck(s) ? 'false' : '');
    const done = expect(ensureEagleFilerRunning()).rejects.toThrow('failed to start');
    await vi.runAllTimersAsync();
    await done;
  });
});
