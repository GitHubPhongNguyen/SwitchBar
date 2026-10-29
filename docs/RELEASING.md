# Hướng dẫn phát hành SwitchBar

Tài liệu cho người duy trì repo [GitHubPhongNguyen/SwitchBar](https://github.com/GitHubPhongNguyen/SwitchBar):
thiết lập một lần, và các bước mỗi lần ra phiên bản mới.

## 1. Thiết lập một lần

**Giấu email cá nhân.** Repo công khai thì ai cũng đọc được email tác giả trong từng commit, nên commit bằng email ẩn danh GitHub cấp:

```bash
git config user.email "38127080+GitHubPhongNguyen@users.noreply.github.com"
git log -1 --format=%ae      # kiểm tra commit mới nhất dùng email nào
```

Trên GitHub → Settings → Emails, bật **Keep my email addresses private** và
**Block command line pushes that expose my email** để GitHub chặn nếu lỡ push bằng email thật.

**Mô tả và topic** giúp người khác tìm thấy repo. Bấm biểu tượng ⚙ cạnh mục **About** trên trang repo, hoặc dùng
[GitHub CLI](https://cli.github.com) (`brew install gh`, rồi `gh auth login`):

```bash
gh repo edit --description "Menu bar switches for macOS: network priority and scroll direction" \
  --add-topic macos,menu-bar,menubar-app,swift,swiftui,network,scrolling
```

## 2. Phát hành một phiên bản

Phiên bản theo dạng `MAJOR.MINOR.PATCH` ([Semantic Versioning](https://semver.org)):
sửa lỗi thì tăng PATCH (1.0.0 → 1.0.1), thêm tính năng thì tăng MINOR (1.0.1 → 1.1.0).

1. Sửa `Info.plist`:
   - `CFBundleShortVersionString`: số phiên bản mới, ví dụ `1.1.0`.
   - `CFBundleVersion`: tăng thêm 1 (`1` → `2`…).
2. Thêm mục mới ở đầu `CHANGELOG.md`, giữ đúng định dạng tiêu đề vì workflow dựa vào nó để viết release notes:

   ```markdown
   ## [1.1.0] - 2026-11-15

   ### Added
   - ...

   ### Fixed
   - ...
   ```

3. Commit, gắn tag rồi đẩy lên:

   ```bash
   git commit -am "Release 1.1.0"
   git tag v1.1.0
   git push origin main v1.1.0
   ```

4. Workflow **Release** tự chạy: kiểm tra tag khớp với `Info.plist`, build app universal, tạo
   `SwitchBar-1.1.0.zip` kèm file `.sha256`, rồi đăng lên tab **Releases** với nội dung lấy từ CHANGELOG.
5. Tải file zip từ trang Release về, mở thử trên máy (tốt nhất là một máy Mac khác hoặc một tài khoản
   người dùng khác) để chắc bước "Open Anyway" chạy đúng như README mô tả.

Nếu workflow báo lỗi tag không khớp: xoá tag, sửa `Info.plist`, gắn tag lại.
Nếu tag đã lên GitHub mà workflow **Release** không chạy (từng gặp khi push code và tag cùng lúc lần đầu tiên),
cũng xoá tag trên GitHub rồi push lại tag.

```bash
git tag -d v1.1.0 && git push origin :refs/tags/v1.1.0
```

## 3. Bỏ cảnh báo Gatekeeper (tuỳ chọn, tốn phí)

Hiện app chỉ ký ad-hoc nên người dùng phải bấm "Open Anyway" ở lần mở đầu. Muốn bỏ bước này:

1. Đăng ký [Apple Developer Program](https://developer.apple.com/programs/) (99 USD/năm).
2. Tạo chứng chỉ **Developer ID Application** trong Xcode → Settings → Accounts → Manage Certificates.
   Chứng chỉ "Apple Development" đang có trên máy **không** dùng được cho việc này.
3. Ký với hardened runtime thay cho `codesign --sign -` trong `build.sh`:

   ```bash
   codesign --force --options runtime --timestamp \
     --sign "Developer ID Application: <Tên> (<TEAM_ID>)" build/SwitchBar.app
   ```

4. Gửi Apple công chứng, rồi đóng dấu kết quả vào app:

   ```bash
   ditto -c -k --keepParent build/SwitchBar.app build/notarize.zip
   xcrun notarytool submit build/notarize.zip --wait \
     --apple-id <email> --team-id <TEAM_ID> --password <app-specific-password>
   xcrun stapler staple build/SwitchBar.app
   ```

5. Nén lại bằng `ditto` như trong `./build.sh dist` rồi phát hành.

Sau khi bật hardened runtime, cần thử lại cả hai công cụ, đặc biệt là đổi mạng bằng mật khẩu admin
(chạy qua AppleScript) và đổi hướng cuộn (nạp framework riêng của Apple bằng `dlopen`).
Khi quy trình này chạy ổn trên máy, có thể đưa vào workflow Release bằng GitHub Secrets.

## 4. Việc nên làm thêm

- **Ảnh chụp màn hình**: lưu vào `docs/images/screenshot.png` rồi bỏ comment dòng ảnh trong cả hai README.
  Trang GitHub có ảnh sẽ thuyết phục người xem hơn nhiều.
- **Icon app**: hiện app dùng icon mặc định của macOS (chỉ thấy trong Finder/Applications, không ảnh hưởng
  thanh menu). Thêm `AppIcon.icns` vào `Contents/Resources` và khai báo `CFBundleIconFile` trong `Info.plist`.
- **Social preview**: GitHub → Settings → General → Social preview, tải lên ảnh 1280×640 để link chia sẻ có ảnh đẹp.
