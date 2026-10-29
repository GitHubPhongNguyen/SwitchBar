# SwitchBar

[English](README.md) · **Tiếng Việt**

[![Build](https://github.com/GitHubPhongNguyen/SwitchBar/actions/workflows/build.yml/badge.svg)](https://github.com/GitHubPhongNguyen/SwitchBar/actions/workflows/build.yml)
[![Bản mới nhất](https://img.shields.io/github/v/release/GitHubPhongNguyen/SwitchBar)](https://github.com/GitHubPhongNguyen/SwitchBar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

App nhỏ trên thanh menu macOS, gom các công tắc nhanh lại một chỗ cho những cài đặt vốn nằm sâu trong System Settings:

- **Ưu tiên mạng**: chọn Mac ưu tiên Wi-Fi hay dây cáp, không cần vào *Network → Set Service Order*.
- **Hướng cuộn**: đổi Cuộn tự nhiên ↔ Kiểu chuột, có hiệu lực ngay, không cần đăng xuất. Đổi bằng icon trên thanh menu hoặc bằng phím tắt.

<!-- Thêm ảnh chụp màn hình: lưu vào docs/images/screenshot.png rồi bỏ comment dòng dưới.
![SwitchBar trên thanh menu](docs/images/screenshot.png)
-->

## Yêu cầu

- macOS 14 Sonoma trở lên
- Mac chip Apple hoặc Mac Intel (app là bản universal)

## Cài đặt

1. Tải `SwitchBar-<phiên bản>.zip` ở [bản phát hành mới nhất](https://github.com/GitHubPhongNguyen/SwitchBar/releases/latest).
2. Giải nén, kéo **SwitchBar.app** vào thư mục **Applications**.
3. Mở SwitchBar. App chưa được Apple công chứng (notarize) nên lần đầu macOS sẽ chặn:
   1. Ở hộp cảnh báo, bấm **Xong** (Done).
   2. Vào **System Settings → Privacy & Security**, kéo xuống, bấm **Open Anyway** (Vẫn mở) rồi nhập mật khẩu máy.

   Chỉ cần làm một lần. Cách khác: trước khi mở lần đầu, chạy lệnh này trong Terminal

   ```bash
   xattr -dr com.apple.quarantine /Applications/SwitchBar.app
   ```

Muốn chắc file tải về không bị sửa đổi, so với mã checksum đi kèm bản phát hành:

```bash
shasum -a 256 -c SwitchBar-<phiên bản>.zip.sha256
```

> [!IMPORTANT]
> **Vì sao có cảnh báo?** Apple chỉ bỏ cảnh báo cho app được ký bằng Developer ID (tài khoản Apple Developer trả phí) và đã qua công chứng của Apple. SwitchBar là dự án cá nhân miễn phí nên chỉ ký ad-hoc. Toàn bộ mã nguồn có ở đây, bạn có thể [tự build](#build-từ-mã-nguồn) nếu muốn.

## Cách dùng

Mỗi công cụ có icon riêng trên thanh menu, bật/tắt từng icon trong **Cài đặt SwitchBar…**.

### Ưu tiên mạng

- Icon cho biết mạng đang được ưu tiên (Wi-Fi, dây cáp, iPhone…).
- Bấm icon → bấm vào mạng muốn dùng để đưa nó lên đầu danh sách.
- Mạng chưa kết nối nằm trong mục **Mạng khác**.
- Nếu tài khoản không phải quản trị viên, macOS sẽ hỏi mật khẩu admin.

### Hướng cuộn

- Icon bàn tay = Tự nhiên, icon con chuột = Kiểu chuột.
- **Bấm icon là đổi ngay.** Bấm chuột phải (hoặc giữ Control rồi bấm) để mở menu.
- Phím tắt **⌃⌥⌘S** đổi được ở bất cứ app nào, kể cả khi đã ẩn icon. Tắt phím tắt trong Cài đặt.

### Cài đặt SwitchBar

- Mở từ menu của bất kỳ icon nào (hoặc ⌘, khi menu đang mở).
- Bật/tắt từng icon ở mục **Hiện trên thanh menu**. Muốn ẩn nhanh: mở menu của icon → **Ẩn icon này**.
- Ẩn hết icon rồi thì mở lại SwitchBar từ Applications hoặc Spotlight, cửa sổ Cài đặt sẽ hiện ra.
- **Mở cùng máy**: tự chạy SwitchBar khi đăng nhập.
- Giữ ⌘ rồi kéo icon để đổi vị trí; SwitchBar nhớ vị trí của từng icon.

## Quyền riêng tư và quyền hệ thống

SwitchBar không kết nối mạng, không thu thập dữ liệu. App chỉ đổi đúng hai cài đặt nó hiển thị:

| Việc | Cách làm |
| --- | --- |
| Thứ tự mạng | Chạy `/usr/sbin/networksetup -ordernetworkservices`, giống hệt *Set Service Order* trong System Settings, áp dụng cho network location hiện tại. Khi macOS từ chối, SwitchBar xin mật khẩu admin qua hộp thoại chuẩn của macOS. |
| Hướng cuộn | Gọi hàm `setSwipeScrollDirection` trong framework riêng `PreferencePanesSupport` của Apple, chính là hàm mà phần cài đặt Trackpad/Chuột dùng, nên có hiệu lực ngay. Vì là hàm riêng (private), bản macOS sau có thể làm nó hỏng; khi đó SwitchBar báo lỗi chứ không đổi gì cả. |
| Phím tắt toàn hệ thống | Dùng Carbon hot key, không cần quyền Accessibility. |
| Mở cùng máy | **Lần mở đầu tiên, SwitchBar tự thêm mình vào Login Items.** Tắt trong Cài đặt → *Mở cùng máy*, hoặc System Settings → General → Login Items. |
| Nơi lưu cài đặt | `~/Library/Preferences/io.github.githubphongnguyen.SwitchBar.plist` |

## Build từ mã nguồn

Cần Xcode hoặc Command Line Tools (`xcode-select --install`). Không phụ thuộc thư viện nào khác.

```bash
git clone https://github.com/GitHubPhongNguyen/SwitchBar.git
cd SwitchBar
./build.sh            # chỉ build ra build/SwitchBar.app
./build.sh install    # build, chép vào ~/Applications rồi chạy
./build.sh dist       # build rồi nén thành build/SwitchBar-<phiên bản>.zip
```

`build.sh` biên dịch thẳng `Sources/*.swift` bằng `swiftc` thành app universal (arm64 + x86_64) và ký ad-hoc. Không có project Xcode.

## Xử lý sự cố

- **"SwitchBar is damaged and can't be opened"** (app bị hỏng): macOS hiện thông báo này với một số app tải về chưa công chứng. Chạy lệnh `xattr` ở phần [Cài đặt](#cài-đặt) rồi mở lại.
- **Không bật được phím tắt ⌃⌥⌘S**: một app khác đang dùng tổ hợp phím này. Thoát app đó hoặc đổi phím tắt của nó.
- **Không đổi được mạng**: kiểm tra mạng đó đang bật trong System Settings → Network, và đã nhập đúng mật khẩu admin khi được hỏi.
- **Không thấy icon nào trên thanh menu**: có thể đã ẩn hết icon, hoặc thanh menu đã đầy (hay gặp trên MacBook có tai thỏ). Mở SwitchBar từ Applications để vào Cài đặt.

## Gỡ cài đặt

1. Mở Cài đặt, tắt **Mở cùng máy**.
2. Chọn **Thoát SwitchBar** trong menu của icon bất kỳ.
3. Xoá `SwitchBar.app` khỏi Applications (hoặc `~/Applications` nếu đã cài bằng `./build.sh install`).
4. Nếu muốn xoá luôn cài đặt: `defaults delete io.github.githubphongnguyen.SwitchBar`

## Đóng góp

Rất hoan nghênh báo lỗi, góp ý và pull request, bằng tiếng Việt hay tiếng Anh đều được. Xem [CONTRIBUTING.md](CONTRIBUTING.md).

## Giấy phép

[MIT](LICENSE) © 2026 GitHubPhongNguyen
