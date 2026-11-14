import { execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { describe, it } from 'vitest';

// osacompile needs macOS and the EagleFiler dictionary.
const canCompile =
  process.platform === 'darwin' && fs.existsSync('/Applications/EagleFiler.app');
const dir = path.join(__dirname, '..', 'scripts');
const scripts = fs.readdirSync(dir).filter((f) => f.endsWith('.applescript'));

describe.skipIf(!canCompile)('AppleScript scripts', () => {
  it.each(scripts)('%s compiles', (name) => {
    execFileSync('osacompile', ['-o', '/dev/null', path.join(dir, name)], { stdio: 'pipe' });
  });
});
