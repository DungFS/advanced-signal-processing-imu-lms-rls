# Lọc nhiễu rung IMU bằng bộ lọc thích nghi LMS/RLS

**Bài tập lớn môn Xử lý tín hiệu nâng cao** (Advanced Digital Signal Processing)

Đề tài dùng bộ lọc thích nghi **LMS** (Least Mean Squares) và **RLS** (Recursive Least Squares) để khử nhiễu rung động cơ trong tín hiệu gia tốc IMU. Sau đó so sánh hai thuật toán theo các tiêu chí: miền thời gian, miền tần số, tốc độ hội tụ, độ ổn định và độ nhạy với tham số.

Công cụ: **MATLAB R2023a**. Cần thêm Signal Processing Toolbox (`pwelch`) và UAV Toolbox (`ulogreader`, chỉ để đọc log PX4).

---

## 1. Mô hình bài toán

Hệ khử nhiễu thích nghi (Adaptive Noise Cancellation):

```
            s(n) ──┐
                   (+)── d(n) = s(n) + v(n) ──────────────(+)── e(n) ≈ s(n)
  v(n) ────────────┘                                     │ -
                                                         │
  x(n) (tham chiếu nhiễu) ──► [ Bộ lọc FIR thích nghi w ] ── y(n) ≈ v(n)
                                      ▲
                                      └──── cập nhật bằng e(n) (LMS / RLS)
```

Tín hiệu mô phỏng (`day02_generate_imu.m`), với `Fs = 200 Hz` và `T = 10 s`:

| Thành phần | Biểu thức |
|---|---|
| Tín hiệu IMU lý tưởng `s(n)` | `0.5·sin(2π·1·t) + 0.2·sin(2π·3·t)` |
| Nhiễu rung động cơ `v_motor(n)` | `0.8·sin(2π·30·t) + 0.3·sin(2π·60·t)` |
| Nhiễu ngẫu nhiên cảm biến | `0.1·randn` |
| Tín hiệu đo `d(n)` | `s(n) + v_motor(n) + nhiễu ngẫu nhiên` |
| Tín hiệu tham chiếu `x(n)` | `v_motor(n)` |

Tham số mặc định:

- **LMS:** bậc lọc `M = 16`, bước học `μ = 0.01`
- **RLS:** bậc lọc `M = 16`, hệ số quên `λ = 0.99`, khởi tạo `δ = 0.01`

---

## 2. Cấu trúc thư mục

```
├── 09_MATLABCODE/   Mã nguồn MATLAB (chạy theo thứ tự ngày)
└── 06_RESULTS/      Kết quả: dữ liệu .mat, bảng .csv, hình .png, log PX4 .ulg
```

| Script | Nội dung |
|---|---|
| `test_matlab.m` | Làm quen MATLAB: mô phỏng sóng sin |
| `day02_generate_imu.m` | Sinh tín hiệu IMU mô phỏng và nhiễu rung |
| `day03_fft_psd_analysis.m` | Phân tích FFT và PSD của tín hiệu gốc |
| `day04_lms.m` | Cài đặt bộ lọc LMS |
| `day05_rls.m` | Cài đặt bộ lọc RLS |
| `day06_compare_lms_rls.m` | So sánh LMS và RLS trong miền thời gian |
| `day07_fft_psd_comparison.m` | So sánh trong miền tần số (FFT/PSD) |
| `day08_rmse_snr_evaluation.m` | Đánh giá RMSE, SNR và đường hội tụ sai số |
| `day09_parameter_study.m` | Khảo sát tham số `μ` (LMS) và `λ` (RLS) |
| `day09_rls_diagnostic.m` | Chẩn đoán RLS mất ổn định khi `λ` nhỏ |
| `day10_check_inputs.m` | Kiểm tra dữ liệu đầu vào |
| `day10_vibration_levels.m` | Thử với 4 mức nhiễu rung (0.25, 0.5, 1.0, 1.5) |
| `day10_frequency_levels.m` | FFT/PSD theo từng mức rung |
| `day10_residual_validation.m` | Kiểm tra nhiễu dư sau lọc |
| `day11_convergence_analysis.m` | Phân tích hội tụ và ổn định |
| `day12_parameter_sensitivity.m` | Độ nhạy của kết quả với tham số |
| `day13_*.m` | Tổng hợp kết quả và vẽ hình cuối cùng |
| `day14_*.m` | Kiểm tra, xác nhận toàn bộ file kết quả |
| `day15_step01_inspect_px4_log.m` | Đọc log bay PX4 thực tế (`.ulg`) để chuẩn bị áp dụng cho dữ liệu thật |

---

## 3. Kết quả chính

Kết quả trên dữ liệu mô phỏng, mức rung 1.0 (từ `day13_final_summary.csv`, `day13_convergence_summary.csv` và `day13_frequency_summary.csv`):

| Phương pháp | RMSE xác lập | Giảm RMSE | SNR (dB) | Tăng SNR (dB) | Thời gian hội tụ |
|---|---|---|---|---|---|
| Tín hiệu gốc | 0.6136 | – | −4.14 | – | – |
| **LMS** | 0.1054 | 82.8 % | 11.16 | +15.30 | 2.035 s |
| **RLS** | 0.1042 | 83.0 % | 11.26 | +15.40 | 0.600 s |

Độ suy giảm nhiễu trong miền tần số:

| Phương pháp | Suy giảm FFT (dB) | Suy giảm PSD (dB) |
|---|---|---|
| LMS | 32.3 | 30.1 |
| RLS | 46.8 | 37.5 |

**Nhận xét:**

- Hai bộ lọc cho RMSE xác lập gần như nhau. **RLS hội tụ nhanh hơn khoảng 3.4 lần** và triệt nhiễu tại 30/60 Hz sâu hơn.
- **LMS** ổn định với mọi `μ` trong khoảng 0.001 – 0.02. Giá trị tối ưu là `μ ≈ 0.01`. Khi `μ = 0.001`, LMS hội tụ chậm và RMSE tăng lên 0.160.
- **RLS** mất ổn định số khi `λ ≤ 0.98`, và chỉ ổn định khi `λ ≥ 0.99`. Chi tiết xem `day13_rls_diagnostics.csv`.
- Mức rung càng lớn thì tỉ lệ giảm RMSE càng cao: LMS từ 33 % lên 85 %, RLS từ 42 % lên 88 %. Đổi lại, RLS chậm hơn LMS khoảng 4 lần về thời gian tính toán.

---

## 4. Cách chạy

1. Mở MATLAB R2023a.
2. Sửa đường dẫn gốc ở đầu mỗi script (biến `projectRoot` / `rootDir` / `baseDir`) thành thư mục chứa repo này.
3. Chạy các script trong `09_MATLABCODE` theo thứ tự `day02` → `day14`. Script sau dùng file `.mat` do script trước tạo ra trong `06_RESULTS`.

---

## 5. Hướng phát triển

- Áp dụng LMS/RLS cho dữ liệu IMU thật từ log bay PX4 (`06_RESULTS/log_4_2026-10-25-17-24-42.ulg`).
- Thu log IMU trên bàn thử (động cơ quay qua QGC) rồi lọc bằng MATLAB. Xem hướng dẫn chi tiết trong [`HUONG_DAN_GHI_LOG.md`](HUONG_DAN_GHI_LOG.md).
- Thử các biến thể như NLMS và RLS có regularization để cải thiện độ ổn định.
