import { execFile as execFileCb } from 'child_process';
import { promisify } from 'util';
import { McpError, ErrorCode } from '@modelcontextprotocol/sdk/types.js';

const execFile = promisify(execFileCb);

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// After a launch, EagleFiler reopens its libraries some time after the process starts
const RESTORE_POLL_MS = 500;
const RESTORE_STABLE_POLLS = 2;
const RESTORE_TIMEOUT_MS = 10000;

async function isRunning(): Promise<boolean> {
  const { stdout } = await execFile('osascript', [
    '-e',
    'tell application "System Events" to return (name of processes) contains "EagleFiler"',
  ]).catch(() => ({ stdout: 'false' }));
  return stdout.trim() === 'true';
}

async function countLibraries(): Promise<number> {
  const { stdout } = await execFile('osascript', [
    '-e',
    'tell application "EagleFiler" to return count of library documents',
  ]).catch(() => ({ stdout: '0' }));
  return parseInt(stdout.trim(), 10) || 0;
}

// Wait until the open library count is above 0 and stays the same for RESTORE_STABLE_POLLS polls.
// If no library reopens, stop after RESTORE_TIMEOUT_MS.
async function waitForLibraries(): Promise<void> {
  let last = -1;
  let stable = 0;
  for (let waited = 0; waited < RESTORE_TIMEOUT_MS; waited += RESTORE_POLL_MS) {
    const n = await countLibraries();
    if (n > 0 && n === last) {
      stable++;
      if (stable >= RESTORE_STABLE_POLLS) return;
    } else {
      stable = 0;
    }
    last = n;
    await sleep(RESTORE_POLL_MS);
  }
}

export async function ensureEagleFilerRunning(): Promise<void> {
  if (await isRunning()) return;

  // Launch in background
  await execFile('osascript', ['-e', 'tell application "EagleFiler" to launch']).catch(() => {});

  // Poll until ready (max 5s) using System Events process list check
  for (let i = 0; i < 5; i++) {
    await sleep(1000);
    if (await isRunning()) {
      await waitForLibraries();
      return;
    }
  }

  // If we've exhausted the poll loop, throw an error
  throw new McpError(ErrorCode.InternalError, 'EagleFiler failed to start after 5 seconds');
}
