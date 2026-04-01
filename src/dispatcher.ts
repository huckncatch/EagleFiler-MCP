import { execFile as execFileCallback } from 'child_process';
import { promisify } from 'util';
import { fileURLToPath } from 'url';
import path from 'path';
import { McpError, ErrorCode } from '@modelcontextprotocol/sdk/types.js';
import { ensureEagleFilerRunning } from './launcher.js';

const execFile = promisify(execFileCallback);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const SCRIPTS_DIR = path.join(__dirname, '..', 'scripts');

export async function run(scriptName: string, args: string[]): Promise<unknown> {
  await ensureEagleFilerRunning();

  const scriptPath = path.join(SCRIPTS_DIR, `${scriptName}.applescript`);

  let stdout: string;
  let stderr: string;
  try {
    ({ stdout, stderr } = await execFile('osascript', [scriptPath, ...args]));
  } catch (err: any) {
    throw new McpError(
      ErrorCode.InternalError,
      `osascript failed: ${err.stderr ?? err.message}`
    );
  }

  let parsed: { ok: boolean; data?: unknown; error?: string };
  try {
    parsed = JSON.parse(stdout.trim());
  } catch {
    throw new McpError(
      ErrorCode.InternalError,
      `Script returned invalid JSON: ${stdout.slice(0, 200)}`
    );
  }

  if (!parsed.ok) {
    throw new McpError(ErrorCode.InternalError, parsed.error ?? 'Unknown script error');
  }

  return parsed.data;
}
