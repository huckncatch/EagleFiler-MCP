import { execFile as execFileCb } from 'child_process';
import { promisify } from 'util';

const execFile = promisify(execFileCb);

export async function ensureEagleFilerRunning(): Promise<void> {
  const { stdout } = await execFile('osascript', [
    '-e',
    'tell application "System Events" to return (name of processes) contains "EagleFiler"',
  ]).catch(() => ({ stdout: 'false' }));

  if (stdout.trim() === 'true') return;

  // Launch in background
  await execFile('osascript', ['-e', 'tell application "EagleFiler" to launch']).catch(() => {});

  // Poll until ready (max 5s)
  for (let i = 0; i < 5; i++) {
    await new Promise((r) => setTimeout(r, 1000));
    const { stdout: ready } = await execFile('osascript', [
      '-e',
      'tell application "EagleFiler" to return name',
    ]).catch(() => ({ stdout: '' }));
    if (ready.trim()) return;
  }
}
