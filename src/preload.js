const { contextBridge, ipcRenderer, webUtils } = require('electron');

contextBridge.exposeInMainWorld('api', {
  getInitialState: () => ipcRenderer.invoke('get-initial-state'),
  saveSettings: (patch) => ipcRenderer.invoke('save-settings', patch),
  setLanguage: (language) => ipcRenderer.invoke('set-language', language),
  showAbout: () => ipcRenderer.invoke('show-about'),
  pickFiles: () => ipcRenderer.invoke('pick-files'),
  pickFolder: () => ipcRenderer.invoke('pick-folder'),
  expandPaths: (paths) => ipcRenderer.invoke('expand-paths', paths),
  pickOutputDir: () => ipcRenderer.invoke('pick-output-dir'),
  pickSox: () => ipcRenderer.invoke('pick-sox'),
  readFile: (filePath) => ipcRenderer.invoke('read-file', filePath),
  openPath: (dir) => ipcRenderer.invoke('open-path', dir),
  convert: (job) => ipcRenderer.invoke('convert', job),
  pathForFile: (file) => webUtils.getPathForFile(file),
  onConvertProgress: (cb) => ipcRenderer.on('convert-progress', (_e, data) => cb(data)),
  onConvertDone: (cb) => ipcRenderer.on('convert-done', (_e, data) => cb(data)),
});
