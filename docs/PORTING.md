# Ghi chú port

## Đã kiểm chứng và chưa kiểm chứng

| Việc | Trạng thái |
|---|---|
| Các nhánh trong `gto.xml` tồn tại trên remote | Đã kiểm tra bằng `git ls-remote` (2026-10-20) |
| Device tree lineage-20 chỉ phụ thuộc `vendor/lineage` ở một dòng (`inherit-product`) và thư mục `overlay-lineage` | Đã grep toàn bộ tree, đọc `BoardConfig.mk`, `Android.mk` và phần lớn `device.mk` |
| PE ánh xạ `msm8937` + QSSI sang `QCOM_HARDWARE_VARIANT := msm8953` | Đã đọc `vendor/aosp/config/BoardConfigQcom.mk` |
| `02-prepare-device.sh` | Đã chạy thử trên bản sao của device tree và `vendor/aosp` (nhánh `thirteen-plus`), chạy hai lần cho kết quả giống nhau; báo lỗi và dừng nếu dòng GMS trong `common.mk` không còn |
| `gitlab.pixelexperience.org` | Không phân giải DNS (2026-10-20), kiểm tra cả từ máy cá nhân lẫn Google Colab; `vendor_gms` và `external_faceunlock` không có bản sao trên GitHub của PixelExperience |
| `inherit-product-if-exists` có trong build system | Đã đọc `build/make/core/product.mk` tại `android-13.0.0_r75` |
| `repo init` + gộp `gto.xml` vào manifest PE | Đã chạy trên Colab: ra 1171 project, đủ 7 project của `gto.xml`, không báo lỗi |
| `repo sync` và build thật | **Chưa chạy.** Colab (2 CPU, 12 GB RAM, ~88 GB ổ trống) không đủ cho bản build này |
| Bản không GMS có qua được toàn bộ bước build | **Chưa thử** |
| Máy khởi động, Wi‑Fi, âm thanh, camera, cảm biến | **Chưa thử** |

## Điểm dễ lỗi khi build

1. **HAL msm8953 lấy từ LineageOS.** PE không có fork `hardware_qcom-caf_msm8953_*`, nên dùng nhánh
   `lineage-20.0-caf-msm8953`. Các nhánh này có thể tham chiếu module chỉ có trong LineageOS
   (ví dụ `vendor.lineage.*`, `lineage-sdk`). Nếu build báo thiếu module, hoặc xoá phần tham chiếu trong HAL,
   hoặc thêm repo tương ứng vào `gto.xml`.
2. **Namespace display.** Guard `os_pickup_qssi.bp` của PE import thêm `vendor/qcom/opensource/commonsys/display`
   so với bản của LineageOS. Cả ba thư mục đều có trong manifest PE nên thường không cần sửa gì.
3. **`hardware/qcom-caf/bt`.** Manifest PE không có repo này. Tree gtowifi dùng blob Bluetooth của Samsung nên
   có thể không cần. Nếu build báo thiếu, thêm
   `LineageOS/android_hardware_qcom_bt` nhánh `lineage-20.0-caf` vào `gto.xml`.
4. **SELinux.** Tree include `device/qcom/sepolicy-legacy-um/SEPolicy.mk`, PE có repo này (nhánh `thirteen`).
   Policy của PE khác LineageOS nên có thể xuất hiện `neverallow` khi build, hoặc `avc: denied` khi chạy.
5. **`hardware/samsung`.** Tree cần `android.hardware.light-service.samsung`, PE `hardware_samsung` có `aidl/light`.
   Kiểm tra lại khi build vì hai repo không phải bản sao của nhau.
6. **Kernel.** Kernel 4.9 và `lineageos_gtowifi_defconfig` giữ nguyên. Nếu PE đòi cấu hình kernel khác
   (ví dụ `TARGET_KERNEL_CLANG_VERSION`) thì chỉnh trong `BoardConfig.mk`.

## Lỗi thường gặp

- **Build báo thiếu `vendor/gms` hoặc `external/faceunlock`**: `gto.xml` đã gỡ hai repo này (host gitlab của PE
  không còn). Nếu lỗi `vendor/gms/products/gms.mk` vẫn xuất hiện, bản vá của `02-prepare-device.sh` chưa được
  áp dụng, thường do `repo sync --force-sync` vừa hoàn nguyên `vendor/aosp`. Chạy lại `02`.
  Nếu một module khác cũng tham chiếu `vendor/gms` hoặc `external/faceunlock`, xoá phần tham chiếu đó
  (chỉ mới kiểm tra `vendor/aosp` và device tree, chưa kiểm tra toàn bộ source).
- **Hết RAM khi link**: thêm swap hoặc giảm `-j`.

## SIM và 4G trên T295

Tree T290 không có các thành phần modem. Quy trình để có 4G (chưa ai công khai làm xong):

1. Tải firmware gốc Android 11 của **SM-T295**. Giải nén `AP_*.tar.md5`, lấy `super.img` hoặc `vendor.img`,
   dùng `lz4 -d` và `simg2img` rồi mount.
2. So sánh `vendor/` của T295 với T290. Các file chỉ có ở T295 (rild, thư viện RIL của Samsung, `.rc` của RIL,
   `qcril`, `ims`) cho vào `proprietary-files.txt` của một tree mới `gto`.
3. Thêm HAL radio, IMS, data vào `manifest.xml` của tree, thêm `android.hardware.telephony*.xml`.
4. Dùng `vendor/aosp/config/common_full_phone.mk` thay cho bản tablet-wifionly, giữ
   `PRODUCT_CHARACTERISTICS := tablet`.
5. Lấy kernel của T295 từ opensource.samsung.com để so sánh defconfig và device tree (`dts`).
6. Sửa SELinux dựa trên log `avc: denied` khi chạy thử.
7. Đổi `PRODUCT_DEVICE := gto`, `PRODUCT_MODEL := SM-T295`, `TARGET_OTA_ASSERT_DEVICE := gto`.

## Cài lên máy

1. Kiểm tra số binary trong mã firmware (ví dụ `T295XXU6...` là binary 6). Samsung không cho hạ binary.
2. Mở khoá bootloader (bật OEM unlocking, vào Download mode bằng Vol Up + Vol Down khi cắm USB).
   Thao tác này xoá dữ liệu và đánh dấu Knox vĩnh viễn.
3. Flash TWRP bằng Odin, bỏ tick Auto Reboot, rồi vào thẳng recovery bằng Vol Up + Power.
4. Trong TWRP: Wipe, Format Data, rồi flash zip build ra. Vbmeta cần tắt verify.
5. Khởi động lại.

Luôn sao lưu `efs` và `persist` trước khi flash. Nếu mất, SIM và Wi‑Fi MAC không khôi phục được.
