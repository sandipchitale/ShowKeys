# ShowKeys ⌨️

ShowKeys is a lightweight, high-performance macOS menu bar utility that displays your keystrokes on-screen in real time. Designed with a premium Apple-like aesthetic, it is perfect for live presentations, video tutorials, screencasts, and developer pair-programming.

<div align="center">
  <h3>Skeuomorphic 3D Keycaps & Glassmorphic Hud</h3>
</div>

---

## Features

- **Skeuomorphic 3D Keycaps**: Keycaps are rendered to look like actual physical keyboard keys:
  - **Modifier Keys** (Command, Option, Control, Shift) are styled as dark keys with symbols on the top-right and names on the bottom-left.
  - **Standard Keys** are styled as light keys with bold centered text/symbols.
- **Glassmorphic HUD Container**: Displays keys side-by-side using macOS `.hudWindow` materials for a sleek translucent glass backdrop.
- **Accessibility Guided Setup**: Automatically detects if the required macOS Accessibility permission is granted. Displays an instructional window prompting you with a direct link to System Settings if trust is missing.
- **Enable / Disable Toggle**: Toggle key displaying on or off anytime via the status bar menu. When disabled, the keystroke capture stops and any active keys on-screen are cleared immediately.
- **Corner Selection**: Place the on-screen display in any of the four corners (Top-Left, Top-Right, Bottom-Left, Bottom-Right) of your visible screen.
- **Modifier Filter**: Option to display keystrokes *only* when modifier keys are pressed.

---

## Build & Run

### Prerequisites
- macOS Big Sur (11.0) or later.
- Swift 5.5+ / Xcode Command Line Tools.

### Compilation
Build the application bundle by running the following command in the root folder:
```bash
make bundle
```
This compiles the release executable, packages it, and automatically applies an ad-hoc code signature to `ShowKeys.app` so that macOS TCC correctly tracks its security permissions.

### Running
Launch the application:
```bash
open ShowKeys.app
```
You can also drag `ShowKeys.app` to your `/Applications` folder for ease of access.

---

## Accessibility Permission Setup

Because ShowKeys intercepts global keyboard events to display them, macOS requires that it be granted **Accessibility** permission.

1. On launch, if permission is missing, an **Accessibility Access Required** dialog will appear.
2. Click **Open System Settings**.
3. Toggle the switch for **ShowKeys** to **On** (you may need to authenticate).
4. ShowKeys will automatically detect the approval, dismiss the dialog, and begin capturing events immediately.

### ⚠️ Recompilation Troubleshooting
When you recompile or modify ShowKeys, macOS's security daemon (TCC) might silently block event capturing because the binary's hash signature changed, even if it still appears as "Enabled" in your settings.

To fix this:
1. Open **System Settings > Privacy & Security > Accessibility**.
2. Select **ShowKeys** in the list, and click the **`-` (minus)** button at the bottom of the list to remove it completely.
3. Relaunch `ShowKeys.app`.
4. When prompted, add and enable it again.
