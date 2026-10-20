# Pixel Experience 13 cho Galaxy Tab A 8.0 (2019)

Port Pixel Experience (Android 13, nhánh `thirteen-plus`) cho **SM-T290 (`gtowifi`)** và **SM-T295 (`gto`)**.

> **Trạng thái: chưa build thử lần nào.** Các `revision` trong manifest đã được kiểm tra bằng `git ls-remote`
> và script 02 đã chạy thử trên bản sao của device tree, nhưng toàn bộ quá trình sync và build thật
> chưa được chạy. Dự kiến sẽ có lỗi build ở bước đầu, xem [docs/PORTING.md](docs/PORTING.md).

Pixel Experience đã ngừng phát triển từ 10/04/2024. PE 13 là bản ổn định cuối cùng, nên repo này
bám theo nhánh `thirteen-plus` và không có bản cập nhật bảo mật mới từ upstream.

## Cách làm

PE không có device tree cho máy này, nên dùng tree **LineageOS 20 (Android 13)** của `gtowifi`:

| Thành phần | Nguồn |
|---|---|
| Source AOSP + framework | `PixelExperience/manifest` nhánh `thirteen-plus` |
| Device tree | `LineageOS/android_device_samsung_gtowifi` nhánh `lineage-20` |
| Kernel 4.9 | `LineageOS/android_kernel_samsung_sdm429` nhánh `lineage-20` |
| Vendor blobs | `TheMuppets/proprietary_vendor_samsung_gtowifi` nhánh `lineage-20` |
| `hardware/samsung` | `PixelExperience/hardware_samsung` nhánh `thirteen` |
| HAL Qualcomm `msm8953` (audio, display, media) | `LineageOS/android_hardware_qcom_*` nhánh `lineage-20.0-caf-msm8953` |

`local_manifests/gto.xml` khai báo các repo trên. `scripts/02-prepare-device.sh` đổi device tree từ
`lineage_gtowifi` sang `aosp_gtowifi` và vá `vendor/aosp` để bỏ qua GMS (xem bên dưới).

## Yêu cầu máy build

Container Claude Code không đủ tài nguyên, nên phải build trên máy riêng hoặc server:

- Linux (Ubuntu 22.04 trở lên), tối thiểu 16 GB RAM (nên có 32 GB), khoảng 250 GB ổ trống
- `repo`, `git`, `git-lfs`, `ccache` và các gói build AOSP theo
  [hướng dẫn của AOSP](https://source.android.com/docs/setup/start/requirements)

## Sử dụng

```bash
git clone https://github.com/Luongvanngoc123/port-rom && cd port-rom
scripts/01-sync.sh ~/pe13              # repo init + sync (vài giờ)
scripts/02-prepare-device.sh ~/pe13    # lineage_gtowifi -> aosp_gtowifi, vá vendor/aosp bỏ GMS
scripts/03-build.sh ~/pe13 userdebug   # build, log nằm ở ~/pe13/build-userdebug.log
```

Kết quả nằm trong `~/pe13/out/target/product/gtowifi/`. Chạy lại `02` sau mỗi lần `repo sync --force-sync`,
vì lệnh đó hoàn nguyên bản vá trong `vendor/aosp`.

## Bản build không có GMS

Hai repo PE `vendor_gms` và `external_faceunlock` nằm trên `gitlab.pixelexperience.org`, host này không còn
phân giải DNS (kiểm tra 2026-10-20), nên `repo sync` không lấy được. `gto.xml` gỡ cả hai bằng `remove-project`,
và `02-prepare-device.sh` đổi dòng `inherit-product vendor/gms/products/gms.mk` trong `vendor/aosp` thành
`inherit-product-if-exists`. Kết quả là ROM **không có Google Play Services và không có Face Unlock**
(Face Unlock vốn đã tắt bằng `TARGET_FACE_UNLOCK_SUPPORTED := false`). Cài MindTheGapps sau nếu cần GApps.

## Lưu ý với SM-T295 (LTE)

Device tree gốc là bản **Wi‑Fi only** của T290. Bản build từ tree này chạy trên T295 nhưng **không có SIM/4G**.
Người dùng trên XDA cũng báo cùng hiện tượng với LineageOS 22.2 port từ T290. Phần RIL cho T295 chưa có ai
công khai làm xong, quy trình nằm trong [docs/PORTING.md](docs/PORTING.md#sim-và-4g-trên-t295).

Nếu cần SIM/4G ngay, nên flash GSI của PE lên T295 (giữ nguyên vendor gốc của máy) thay vì build từ source.
