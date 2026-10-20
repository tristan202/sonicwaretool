# Sonicware Lofi-12 XT Tool v1.6

A high-speed batch audio converter specifically designed for hardware samplers like the Sonicware Lofi-12 XT. Powered by the legendary SoX (Sound eXchange) engine for maximum precision and performance.

<img width="527" alt="Screenshot of Sonicware Lofi-12 XT Tool" src="docs/screenshot.png" />

## 🚀 Features

- **Batch processing:** Drag and drop multiple files or entire folders (WAV, MP3, FLAC, OGG, WMA, M4A).
- **Hardware profiles:** One-click presets for:

  | Device | Sample rate | Bit depth | Channels |
  | --- | --- | --- | --- |
  | Sonicware Lofi-12 XT | 24 kHz | 16-bit | Mono |
  | Sonicware Lofi-12 (Original) | 12 kHz | 16-bit | Mono |
  | Elektron Digitakt (Mk1) | 44.1 kHz | 16-bit | Mono |

  You can also pick sample rate (12/24/44.1/48 kHz), bit depth (16/24-bit) and channels (mono/stereo) by hand.
- **Smart filenames:** Replaces spaces and invalid characters with underscores and never overwrites existing files (a numbered suffix is added instead).
- **Normalize:** Peak normalization to 0 dB for consistent volume across all your samples.
- **Auto-Trim:** Removes silence at the start and end of each sample.
- **Reverse:** Reverses samples during conversion (output files get a `_rev` suffix).
- **Preview:** Click a file to play it and see its waveform (waveform display supports 16/24-bit PCM WAV).
- **Blazing fast:** Uses the SoX engine and converts in the background, so the window stays responsive.
- **Multilingual:** English, Danish, German, Spanish, French, Italian and Swedish (switch via the *Language* menu).
- **Open source:** Free to use, modify, and distribute.

Output is always WAV.

## 🛠 Installation

1. **Download the tool:** Get the latest `.exe` from the [Releases](https://github.com/tristan202/sonicwaretool/releases) page.
2. **Get SoX:** The tool requires `sox.exe` ([SoX](https://sourceforge.net/projects/sox/)) or `sox_ng.exe` ([SoX-NG](https://codeberg.org/sox_ng/sox_ng)). The tool looks for it in this order:
   - the same folder as the tool (place `sox.exe` / `sox_ng.exe` and its `.dll` files there),
   - `C:\Program Files (x86)\sox-14-4-2\`,
   - any folder on your `PATH`.

   If SoX can't be found, the tool asks you to locate it the first time you press **START CONVERSION**. MP3 and other compressed formats require a SoX build with support for those formats.
3. **Run:** Open the tool and you are ready to go.

Settings are stored in `%APPDATA%\SonicwareTool\lofi_config.ini`. Converted files go to `Documents\XT_Export` by default.

## 📖 How to Use

1. **Add files:** Drag and drop audio files or folders into the list, or use the **Add Files** / **Add Folder** buttons. Adding a folder doesn't include its subfolders.
2. **Set output:** Choose where you want your converted samples to be saved with **Change Folder**.
3. **Adjust settings:** Pick a target hardware profile, or select sample rate, bit depth and channels yourself. Enable **Normalize**, **Auto-Trim** or **Reverse** as needed.
4. **Convert:** Hit **START CONVERSION**. Progress is shown below the settings, along with the number of failed files, if any. Enable **Open folder when done** to have the output folder open automatically.

## 🧑‍💻 Building from Source

1. Install [PureBasic](https://www.purebasic.com/) 6.30 or newer (Windows x64).
2. Open `sonicware.pb` in the PureBasic IDE. The compiler options (thread-safe, XP skin, DPI aware, icon) are stored at the bottom of the file.
3. Compile, or from the command line:

   ```bash
   pbcompiler sonicware.pb /THREAD /XP /DPIAWARE /ICON sonicware.ico /EXE sonicwaretool.exe
   ```

## 📜 License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

You are free to use, study, modify and distribute this software, including commercially. If you distribute it or a modified version, you must make the source code available under the same license.

## 👤 Credits

Created by [tristan202](https://github.com/tristan202).

Special thanks to the Sonicware community for inspiration.
