const { app, BrowserWindow, Menu, dialog, ipcMain, shell } = require('electron');
const fs = require('fs');
const path = require('path');
const sox = require('./sox');
const { Settings } = require('./settings');
const { LANGUAGES, getStrings } = require('./i18n');

app.setName('SonicwareTool');

let mainWindow = null;
let settings = null;
let soxPath = '';
let converting = false;
let currentChild = null;

// Folders searched for sox_ng/sox before the default install folder and PATH
function appDirs() {
  const dirs = [];
  if (process.env.PORTABLE_EXECUTABLE_DIR) dirs.push(process.env.PORTABLE_EXECUTABLE_DIR);
  if (app.isPackaged) dirs.push(path.dirname(process.execPath));
  else dirs.push(app.getAppPath());
  dirs.push(process.cwd());
  return [...new Set(dirs)];
}

function resolveSoxPath(saved) {
  if (saved) {
    const candidates = path.isAbsolute(saved) ? [saved] : appDirs().map((d) => path.join(d, saved));
    const found = candidates.find((p) => fs.existsSync(p));
    if (found) return found;
  }
  return sox.findSox(appDirs());
}

function strings() {
  return getStrings(settings.values.language);
}

function soxStatus() {
  return { path: soxPath, found: soxPath !== '', ng: soxPath !== '' && sox.isSoxNg(soxPath) };
}

function showAbout() {
  const s = strings();
  return dialog.showMessageBox(mainWindow, {
    type: 'info',
    title: s.MenuAbout,
    message: `Sonicware Lofi-12 XT Tool v${app.getVersion()}`,
    detail: `${s.AboutTxt}
${s.License}`,
  });
}

function setLanguage(language) {
  settings.update({ language });
  return strings();
}

function audioFilters(s) {
  return [
    { name: s.FilterAudio, extensions: sox.AUDIO_EXTENSIONS },
    { name: s.FilterAll, extensions: ['*'] },
  ];
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1100,
    height: 760,
    minWidth: 860,
    minHeight: 600,
    backgroundColor: '#323232',
    autoHideMenuBar: true,
    title: `Sonicware Lofi-12 XT Tool v${app.getVersion()}`,
    icon: path.join(__dirname, '..', 'renderer', 'icon.png'),
    show: false,
    webPreferences: {
      preload: path.join(__dirname, '..', 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });
  mainWindow.once('ready-to-show', () => mainWindow.show());
  mainWindow.loadFile(path.join(__dirname, '..', 'renderer', 'index.html'));
  // Keep the version in the title instead of the page <title>
  mainWindow.on('page-title-updated', (e) => e.preventDefault());
  if (!app.isPackaged) {
    mainWindow.webContents.on('before-input-event', (_e, input) => {
      if (input.type === 'keyDown' && input.key === 'F12') mainWindow.webContents.toggleDevTools();
    });
  }
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

function registerIpc() {
  ipcMain.handle('get-initial-state', () => ({
    settings: settings.values,
    strings: strings(),
    languages: LANGUAGES,
    sox: soxStatus(),
    version: app.getVersion(),
  }));

  ipcMain.handle('set-language', (_e, language) => setLanguage(language));
  ipcMain.handle('show-about', () => showAbout());

  ipcMain.handle('save-settings', (_e, patch) => settings.update(patch));

  ipcMain.handle('pick-files', async () => {
    const s = strings();
    const result = await dialog.showOpenDialog(mainWindow, {
      title: s.BtnFiles,
      properties: ['openFile', 'multiSelections'],
      filters: audioFilters(s),
    });
    return result.canceled ? [] : sox.expandPaths(result.filePaths);
  });

  ipcMain.handle('pick-folder', async () => {
    const result = await dialog.showOpenDialog(mainWindow, {
      title: strings().BtnFolder,
      properties: ['openDirectory'],
    });
    return result.canceled ? [] : sox.expandPaths(result.filePaths);
  });

  ipcMain.handle('expand-paths', (_e, paths) => sox.expandPaths(paths));

  ipcMain.handle('pick-output-dir', async () => {
    const result = await dialog.showOpenDialog(mainWindow, {
      title: strings().BtnChange,
      defaultPath: settings.values.outputDir,
      properties: ['openDirectory', 'createDirectory'],
    });
    if (result.canceled || !result.filePaths[0]) return null;
    settings.update({ outputDir: result.filePaths[0] });
    return result.filePaths[0];
  });

  ipcMain.handle('pick-sox', async () => {
    const isWin = process.platform === 'win32';
    const result = await dialog.showOpenDialog(mainWindow, {
      title: strings().FindSox,
      defaultPath: isWin ? 'C:\\' : '/usr/bin',
      properties: ['openFile'],
      filters: isWin ? [{ name: 'SoX (sox.exe, sox_ng.exe)', extensions: ['exe'] }] : [],
    });
    if (!result.canceled && result.filePaths[0]) {
      soxPath = result.filePaths[0];
      settings.update({ soxPath });
    }
    return soxStatus();
  });

  ipcMain.handle('read-file', async (_e, filePath) => {
    const data = await fs.promises.readFile(filePath);
    return new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
  });

  ipcMain.handle('open-path', (_e, dir) => shell.openPath(dir));

  ipcMain.handle('convert', async (event, job) => {
    if (converting) return { started: false, reason: 'busy' };
    if (!soxPath) return { started: false, reason: 'sox' };
    if (!sox.ensureDirectory(job.outputDir)) return { started: false, reason: 'output' };
    converting = true;
    const sender = event.sender;
    const send = (channel, data) => {
      if (!sender.isDestroyed()) sender.send(channel, data);
    };
    sox.convertAll({ ...job, soxPath }, (progress) => send('convert-progress', progress), (child) => {
      currentChild = child;
    }).then((failures) => {
      converting = false;
      currentChild = null;
      send('convert-done', { failures, outputDir: job.outputDir });
    });
    return { started: true };
  });
}

app.whenReady().then(() => {
  settings = new Settings(app.getPath('userData'), {
    outputDir: path.join(app.getPath('documents'), 'XT_Export'),
  });
  settings.load();
  soxPath = resolveSoxPath(settings.values.soxPath);
  registerIpc();
  // Like Skal: no menu bar; language and About live in the sidebar
  if (process.platform !== 'darwin') Menu.setApplicationMenu(null);
  createWindow();
});

app.on('window-all-closed', () => {
  if (currentChild) currentChild.kill();
  app.quit();
});
