# Changelog

All notable changes to SwitchBar are listed here. Versions follow [Semantic Versioning](https://semver.org).

<!-- The release workflow copies the section whose heading matches the pushed tag into the GitHub release notes,
     so keep the "## [x.y.z] - YYYY-MM-DD" heading format. -->

## [1.0.0] - 2026-10-29

First public release. SwitchBar combines two earlier tools, NetSwitch and ScrollSwitch, into one menu bar app.

### Added

- **Network priority**: menu bar icon showing the preferred network; click a network to move it to the top of the service order. Asks for an administrator password only when macOS requires it.
- **Scroll direction**: click the icon to switch between natural and traditional scrolling instantly; right-click for the menu.
- Global shortcut ⌃⌥⌘S to switch scroll direction, even while the icon is hidden.
- Settings window to show or hide each icon, turn the shortcut on or off, and open SwitchBar at login.
- Universal binary for Apple silicon and Intel Macs, macOS 14 or later.
