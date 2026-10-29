# Contributing to SwitchBar

Thanks for helping out! Issues and pull requests are welcome in English or Vietnamese.

## Reporting a bug

Open an issue with the **Bug report** template. Include your macOS version, your Mac model (Apple silicon or Intel), the SwitchBar version, and what you clicked. For network problems, the output of `networksetup -listnetworkserviceorder` helps a lot.

## Building

```bash
./build.sh install
```

This builds a universal app with `swiftc`, copies it to `~/Applications` and launches it. You need Xcode or the Command Line Tools; there is no Xcode project and no third-party dependency.

## Pull requests

- Keep changes focused: one fix or feature per pull request.
- Match the existing code style: small types, comments that explain *why*, no external dependencies.
- The interface text is Vietnamese. If you add a menu item or setting, write its label in Vietnamese (ask in the PR if you need help).
- New menu bar tools subclass `MenuBarModule` and are added to the `modules` list in `AppDelegate`.
- Add a line under a new `## [Unreleased]` heading in `CHANGELOG.md` if the change is visible to users.

There are no automated tests, so before opening a pull request please check by hand:

- [ ] `./build.sh` finishes without errors.
- [ ] Both icons appear, and hiding or showing them in Settings works.
- [ ] Switching the network and the scroll direction works, from the icon and from the menu.
- [ ] ⌃⌥⌘S switches the scroll direction, also with the icon hidden.
- [ ] Turning *Mở cùng máy* (Open at login) on and off updates System Settings → General → Login Items.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
