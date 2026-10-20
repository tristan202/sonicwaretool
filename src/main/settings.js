// Settings are stored as JSON in the user data folder (%APPDATA%\SonicwareTool on Windows).
// Settings from the old PureBasic version (lofi_config.ini) are imported the first time.

const fs = require('fs');
const path = require('path');

const DEFAULTS = {
  outputDir: '',
  language: 'English',
  deviceIdx: 0,
  sampleRateIdx: 1,
  bitDepthIdx: 0,
  channelsIdx: 0,
  normalize: false,
  autoTrim: false,
  reverse: false,
  openDir: true,
  soxPath: '',
};

// Maps keys in the old ini file to settings keys.
const INI_KEYS = {
  OutputDir: 'outputDir',
  Language: 'language',
  DeviceIdx: 'deviceIdx',
  SampleRateIdx: 'sampleRateIdx',
  BitDepthIdx: 'bitDepthIdx',
  ChannelsIdx: 'channelsIdx',
  Normalize: 'normalize',
  AutoTrim: 'autoTrim',
  Reverse: 'reverse',
  OpenDir: 'openDir',
  SoXPath: 'soxPath',
};

function parseIni(text) {
  const result = {};
  for (const rawLine of text.replace(/^﻿/, '').split(/\r?\n/)) {
    const line = rawLine.trim();
    const eq = line.indexOf('=');
    if (!line || line.startsWith('[') || line.startsWith(';') || eq < 0) continue;
    const key = INI_KEYS[line.slice(0, eq).trim()];
    if (!key) continue;
    const value = line.slice(eq + 1).trim();
    result[key] = typeof DEFAULTS[key] === 'number' ? parseInt(value, 10) || 0
      : typeof DEFAULTS[key] === 'boolean' ? value !== '0'
        : value;
  }
  return result;
}

class Settings {
  constructor(dir, defaults = {}) {
    this.file = path.join(dir, 'settings.json');
    this.iniFile = path.join(dir, 'lofi_config.ini');
    this.values = { ...DEFAULTS, ...defaults };
  }

  load() {
    let stored = null;
    try {
      stored = JSON.parse(fs.readFileSync(this.file, 'utf8'));
    } catch {
      try {
        stored = parseIni(fs.readFileSync(this.iniFile, 'utf8'));
      } catch {
        // First run
      }
    }
    if (stored) {
      for (const key of Object.keys(DEFAULTS)) {
        if (key in stored && typeof stored[key] === typeof DEFAULTS[key]) this.values[key] = stored[key];
      }
    }
    return this.values;
  }

  update(patch) {
    for (const key of Object.keys(patch)) {
      if (key in DEFAULTS && typeof patch[key] === typeof DEFAULTS[key]) this.values[key] = patch[key];
    }
    this.save();
    return this.values;
  }

  save() {
    try {
      fs.mkdirSync(path.dirname(this.file), { recursive: true });
      fs.writeFileSync(this.file, JSON.stringify(this.values, null, 2));
    } catch {
      // Not fatal: the app keeps working with the settings in memory
    }
  }
}

module.exports = { Settings, parseIni, DEFAULTS };
