// SoX helpers: locating the executable, building arguments and running conversions.
// Kept free of Electron imports so it can be unit tested with plain Node.

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const AUDIO_EXTENSIONS = ['wav', 'mp3', 'flac', 'ogg', 'wma', 'm4a'];
const SOX_NAMES = process.platform === 'win32' ? ['sox_ng.exe', 'sox.exe'] : ['sox_ng', 'sox'];
const WINDOWS_SOX_DIR = 'C:\\Program Files (x86)\\sox-14-4-2';

function isFile(p) {
  try {
    return fs.statSync(p).isFile();
  } catch {
    return false;
  }
}

function isDirectory(p) {
  try {
    return fs.statSync(p).isDirectory();
  } catch {
    return false;
  }
}

function isAudioFile(p) {
  return AUDIO_EXTENSIONS.includes(path.extname(p).slice(1).toLowerCase());
}

// Finds sox_ng/sox in the given folders, then the default Windows install folder, then PATH.
function findSox(searchDirs = []) {
  const pathDirs = (process.env.PATH || '').split(path.delimiter).filter(Boolean);
  const dirs = [...searchDirs];
  if (process.platform === 'win32') dirs.push(WINDOWS_SOX_DIR);
  dirs.push(...pathDirs);
  for (const name of SOX_NAMES) {
    for (const dir of dirs) {
      const candidate = path.join(dir, name);
      if (isFile(candidate)) return candidate;
    }
  }
  return '';
}

function isSoxNg(soxPath) {
  return path.basename(soxPath).toLowerCase().startsWith('sox_ng');
}

// Lists audio files in a folder (not recursive, like "Add Folder" always did).
function scanDirectory(dir) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }
  return entries
    .filter((e) => e.isFile() && isAudioFile(e.name))
    .map((e) => path.join(dir, e.name))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' }));
}

// Turns dropped/picked paths into a flat list of audio files; folders are scanned.
function expandPaths(paths) {
  const result = [];
  for (const p of paths) {
    if (isDirectory(p)) result.push(...scanDirectory(p));
    else if (isFile(p) && isAudioFile(p)) result.push(p);
  }
  return result;
}

function cleanFileName(fullPath) {
  const base = path.basename(fullPath, path.extname(fullPath));
  const cleaned = base.replace(/[\s\\/:*?"<>|]/g, '_');
  return cleaned || 'sample';
}

function uniqueOutputName(outputDir, baseName, suffix) {
  let counter = 0;
  for (;;) {
    const name = counter === 0
      ? `${baseName}${suffix}.wav`
      : `${baseName}${suffix}_${String(counter).padStart(3, '0')}.wav`;
    const candidate = path.join(outputDir, name);
    if (!fs.existsSync(candidate)) return candidate;
    counter++;
  }
}

function buildArgs(input, output, options) {
  const args = [];
  if (options.normalize) args.push('--norm');
  args.push(input, '-b', String(options.bitDepth), output);
  args.push('channels', String(options.channels), 'rate', String(options.sampleRate));
  if (options.autoTrim) {
    args.push('silence', '1', '0.1', '1%', 'reverse', 'silence', '1', '0.1', '1%', 'reverse');
  }
  if (options.reverse) args.push('reverse');
  return args;
}

function ensureDirectory(dir) {
  try {
    fs.mkdirSync(dir, { recursive: true });
  } catch {
    // Checked below
  }
  return isDirectory(dir);
}

function runSox(soxPath, args, onSpawn) {
  return new Promise((resolve) => {
    let stderr = '';
    let child;
    try {
      child = spawn(soxPath, args, { windowsHide: true });
    } catch (err) {
      resolve({ ok: false, error: err.message });
      return;
    }
    if (onSpawn) onSpawn(child);
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });
    child.on('error', (err) => resolve({ ok: false, error: err.message }));
    child.on('close', (code) => {
      if (code === 0) {
        resolve({ ok: true });
      } else {
        const lastLine = stderr.trim().split(/\r?\n/).pop() || `exit code ${code}`;
        resolve({ ok: false, error: lastLine });
      }
    });
  });
}

// Converts files one at a time. onProgress gets { index, total, file, output, ok, error }.
async function convertAll(job, onProgress, onSpawn) {
  const suffix = job.reverse ? '_rev' : '';
  const failures = [];
  for (let i = 0; i < job.files.length; i++) {
    const input = job.files[i];
    const output = uniqueOutputName(job.outputDir, cleanFileName(input), suffix);
    const result = await runSox(job.soxPath, buildArgs(input, output, job), onSpawn);
    if (!result.ok) failures.push({ file: input, error: result.error });
    if (onProgress) onProgress({ index: i + 1, total: job.files.length, file: input, output, ...result });
  }
  return failures;
}

module.exports = {
  AUDIO_EXTENSIONS,
  isAudioFile,
  findSox,
  isSoxNg,
  scanDirectory,
  expandPaths,
  cleanFileName,
  uniqueOutputName,
  buildArgs,
  ensureDirectory,
  convertAll,
};
