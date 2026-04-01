import { execFile as execFileCb } from 'child_process';
import { promisify } from 'util';
import { McpError, ErrorCode } from '@modelcontextprotocol/sdk/types.js';

const execFile = promisify(execFileCb);

export async function ensureEagleFilerRunning(): Promise<void> {
  // Check if EagleFiler is already running
  const { stdout } = await execFile('osascript', [
    '-e',
    'tell application "System Events" to return (name of processes) contains "EagleFiler"',
  ]).catch(() => ({ stdout: 'false' }));

  if (stdout.trim() === 'true') return;

  // Launch in background
  await execFile('osascript', ['-e', 'tell application "EagleFiler" to launch']).catch(() => {});

  // Poll until ready (max 5s) using System Events process list check
  for (let i = 0; i < 5; i++) {
    await new Promise((r) => setTimeout(r, 1000));
    const { stdout: ready } = await execFile('osascript', [
      '-e',
      'tell application "System Events" to return (name of processes) contains "EagleFiler"',
    ]).catch(() => ({ stdout: 'false' }));
    if (ready.trim() === 'true') return;
  }

  // If we've exhausted the poll loop, throw an error
  throw new McpError(ErrorCode.InternalError, 'EagleFiler failed to start after 5 seconds');
}
