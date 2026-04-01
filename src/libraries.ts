import os from 'os';
import path from 'path';

const HOME = os.homedir();
const BASE = path.join(HOME, 'Dropbox', 'Apps', 'EagleFiler');

export const KNOWN_LIBRARIES: Record<string, string> = {
  main:        path.join(BASE, 'main', 'main.eflibrary'),
  development: path.join(BASE, 'development', 'development.eflibrary'),
  knowledge:   path.join(BASE, 'Knowledge', 'Knowledge.eflibrary'),
  work:        path.join(BASE, 'work', 'work.eflibrary'),
  rental:      path.join(BASE, 'rental', 'rental.eflibrary'),
  evernote:    path.join(BASE, 'Evernote', 'Evernote.eflibrary'),
  joplin:      path.join(BASE, 'Joplin', 'Joplin.eflibrary'),
  scraps:      path.join(BASE, 'scraps', 'scraps.eflibrary'),
  erotica:     path.join(BASE, 'erotica', 'erotica.eflibrary'),
};

export function resolveLibrary(name: string): string {
  if (KNOWN_LIBRARIES[name]) return KNOWN_LIBRARIES[name];
  if (name.startsWith('/')) return name;
  if (name.startsWith('~/')) return path.join(HOME, name.slice(2));
  throw new Error(`Unknown library: "${name}". Use a known short name or an absolute path.`);
}
