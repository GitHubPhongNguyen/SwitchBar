# SwitchBar

**English** · [Tiếng Việt](README.vi.md)

[![Build](https://github.com/GitHubPhongNguyen/SwitchBar/actions/workflows/build.yml/badge.svg)](https://github.com/GitHubPhongNguyen/SwitchBar/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/GitHubPhongNguyen/SwitchBar)](https://github.com/GitHubPhongNguyen/SwitchBar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A small macOS menu bar app with one-click switches for settings that are otherwise buried in System Settings:

- **Network priority**: choose whether your Mac prefers Wi-Fi or Ethernet, without opening *Network → Set Service Order*.
- **Scroll direction**: flip between natural and traditional scrolling instantly, without logging out. Works from the menu bar or with a global shortcut.

<!-- Add a screenshot: save it as docs/images/screenshot.png, then uncomment the line below.
![SwitchBar in the menu bar](docs/images/screenshot.png)
-->

> [!NOTE]
> The app's interface is in Vietnamese for now. This README gives the English meaning of each menu item in parentheses.

## Requirements

- macOS 14 Sonoma or later
- Apple silicon or Intel Mac (the app is a universal binary)

## Install

1. Download `SwitchBar-<version>.zip` from the [latest release](https://github.com/GitHubPhongNguyen/SwitchBar/releases/latest).
2. Unzip it and drag **SwitchBar.app** into your **Applications** folder.
3. Open SwitchBar. Because the app is not notarized by Apple, macOS blocks the first launch:
   1. In the warning, click **Done**.
   2. Open **System Settings → Privacy & Security**, scroll down, click **Open Anyway** and enter your password.

   You only need to do this once. Alternatively, run this in Terminal before the first launch:

   ```bash
   xattr -dr com.apple.quarantine /Applications/SwitchBar.app
   ```

To check that the download wasn't altered, compare it with the checksum published in the release:

```bash
shasum -a 256 -c SwitchBar-<version>.zip.sha256
```

> [!IMPORTANT]
> **Why the warning?** Apple only removes it for apps signed with a paid Apple Developer ID and notarized by Apple. SwitchBar is a free side project and is ad-hoc signed instead. The full source is in this repository, and you can [build it yourself](#build-from-source) if you prefer.

## Usage

Each tool has its own icon in the menu bar. You can show or hide each one in **Cài đặt SwitchBar…** (SwitchBar Settings…).

### Network priority — *Ưu tiên mạng*

- The icon shows which network your Mac currently prefers (Wi-Fi, Ethernet, iPhone hotspot…).
- Click the icon, then click the network you want to move to the top of the service order.
- Networks that aren't connected are listed under **Mạng khác** (Other networks).
- If your account isn't an administrator, macOS asks for an admin password.

### Scroll direction — *Hướng cuộn*

- Hand icon = natural scrolling (*Tự nhiên*); mouse icon = traditional scrolling (*Kiểu chuột*).
- **Click the icon to switch.** Right-click (or Control-click) to open its menu.
- Press **⌃⌥⌘S** in any app to switch, even while the icon is hidden. You can turn the shortcut off in Settings.

### Settings — *Cài đặt SwitchBar*

- Open it from any icon's menu, or press ⌘, while a menu is open.
- **Hiện trên thanh menu** (Show in menu bar): show or hide each tool's icon.
- **Ẩn icon này** (Hide this icon) in an icon's menu hides it quickly.
- If every icon is hidden, open SwitchBar again from Applications or Spotlight and the Settings window appears.
- **Mở cùng máy** (Open at login): start SwitchBar when you log in.
- Hold ⌘ and drag an icon to move it. SwitchBar remembers each icon's position.

## Privacy and permissions

SwitchBar makes no network requests and collects no data. It only changes the two settings it shows you:

| What | How |
| --- | --- |
| Network order | Runs `/usr/sbin/networksetup -ordernetworkservices`, the same change as *Set Service Order* in System Settings. It applies to the current network location. When macOS refuses, SwitchBar asks for an administrator password through the standard macOS prompt. |
| Scroll direction | Calls `setSwipeScrollDirection` from Apple's private `PreferencePanesSupport` framework, the function the Trackpad and Mouse settings use. This is why the change applies immediately. Because it's a private function, a future macOS update could break it; if that happens, SwitchBar shows an error instead of changing anything. |
| Global shortcut | Uses the Carbon hot key API, which doesn't need Accessibility permission. |
| Open at login | **On first launch SwitchBar adds itself to Login Items.** Turn this off in Settings → *Mở cùng máy*, or in System Settings → General → Login Items. |
| Settings storage | `~/Library/Preferences/io.github.githubphongnguyen.SwitchBar.plist` |

## Build from source

You need Xcode or the Command Line Tools (`xcode-select --install`). No other dependencies.

```bash
git clone https://github.com/GitHubPhongNguyen/SwitchBar.git
cd SwitchBar
./build.sh            # builds build/SwitchBar.app
./build.sh install    # builds, copies to ~/Applications and launches it
./build.sh dist       # builds and zips to build/SwitchBar-<version>.zip
```

The build compiles `Sources/*.swift` directly with `swiftc` into a universal (arm64 + x86_64) app and signs it ad-hoc. There is no Xcode project.

| File | Purpose |
| --- | --- |
| `Sources/main.swift`, `AppDelegate.swift` | App entry point, settings wiring, open at login |
| `Sources/MenuBarModule.swift` | Base class for one menu bar icon and its menu |
| `Sources/NetworkModule.swift`, `NetworkServices.swift` | Network priority tool |
| `Sources/ScrollModule.swift`, `ScrollDirection.swift`, `HotKey.swift` | Scroll direction tool and its shortcut |
| `Sources/Settings.swift` | Settings window (SwiftUI) |

## Troubleshooting

- **"SwitchBar is damaged and can't be opened"**: macOS shows this for some downloaded apps that aren't notarized. Run the `xattr` command from [Install](#install), then open the app again.
- **The ⌃⌥⌘S shortcut doesn't turn on**: another app already uses that combination. Quit that app or change its shortcut.
- **Changing the network fails**: check that the network is enabled in System Settings → Network, and that you entered an administrator's password when asked.
- **Nothing appears in the menu bar**: all icons may be hidden, or the menu bar may be full (common on MacBooks with a notch). Open SwitchBar from Applications to get to Settings.

## Uninstall

1. Open Settings and turn off **Mở cùng máy** (Open at login).
2. Choose **Thoát SwitchBar** (Quit SwitchBar) from any icon's menu.
3. Delete `SwitchBar.app` from Applications (or `~/Applications` if you used `./build.sh install`).
4. Optionally remove its settings: `defaults delete io.github.githubphongnguyen.SwitchBar`

## Contributing

Bug reports, ideas and pull requests are welcome, in English or Vietnamese. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 GitHubPhongNguyen
