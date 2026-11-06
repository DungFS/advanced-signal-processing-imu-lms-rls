# Lọc nhiễu rung IMU bằng bộ lọc thích nghi LMS/RLS

**Bài tập lớn môn Xử lý tín hiệu nâng cao** (Advanced Digital Signal Processing)

Đề tài dùng bộ lọc thích nghi **LMS** (Least Mean Squares) và **RLS** (Recursive Least Squares) để khử nhiễu rung động cơ trong tín hiệu gia tốc IMU. Sau đó so sánh hai thuật toán theo các tiêu chí: miền thời gian, miền tần số, tốc độ hội tụ, độ ổn định và độ nhạy với tham số.

| | |
|---|---|
| **Học viên** | Nguyễn Việt Dũng (20252690M), Trần Quốc Việt (20251011M) |
| **Giảng viên hướng dẫn** | Thầy Đặng Quang Hiếu |
| **Đơn vị** | Khoa Điện tử, Trường Điện – Điện tử, Đại học Bách khoa Hà Nội |

📄 **Báo cáo:** [`docs/report/IMU_LMS_RLS_Report.pdf`](docs/report/IMU_LMS_RLS_Report.pdf) (mã nguồn LaTeX trong [`docs/report/latex/`](docs/report/latex/))
📊 **Slide:** [`docs/slides/Slide_LMS_RLS_IMU_HUST.pptx`](docs/slides/Slide_LMS_RLS_IMU_HUST.pptx)
🎥 **Demo bàn thử:** [`docs/media/demo_video.mp4`](docs/media/demo_video.mp4), ảnh [`docs/media/bench_setup.jpg`](docs/media/bench_setup.jpg)

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
├── README.md
├── docs/
│   ├── HUONG_DAN_GHI_LOG.md     Hướng dẫn ghi log IMU trên bàn thử qua QGC
│   ├── report/
│   │   ├── IMU_LMS_RLS_Report.pdf   Báo cáo bài tập lớn (bản PDF)
│   │   └── latex/               Mã nguồn LaTeX (main.tex, Chapter/, figures/)
│   ├── slides/                  Slide thuyết trình (.pptx)
│   └── media/                   Video demo và ảnh bàn thử
├── code/                        Mã nguồn MATLAB, chia theo giai đoạn
│   ├── 01_setup/                Làm quen MATLAB
│   ├── 02_simulation/           Sinh tín hiệu IMU mô phỏng, phân tích FFT/PSD
│   ├── 03_lms_rls/              Cài đặt LMS, RLS và so sánh hai bộ lọc
│   ├── 04_parameter_study/      Khảo sát tham số μ, λ và độ nhạy
│   ├── 05_robustness/           Thử nhiều mức rung, hội tụ, ổn định
│   ├── 06_summary/              Tổng hợp, vẽ hình cuối, kiểm tra kết quả
│   └── 07_real_data/            Áp dụng cho log IMU thật
├── data/                        Dữ liệu đo thật (đầu vào, không sinh lại được)
│   ├── bench/                   Log bàn thử: bench_lms_rls_01.csv + ghi chú
│   └── flight/                  Log bay PX4 (.ulg)
└── results/                     Kết quả do script sinh ra
    ├── simulation/              Kết quả trên dữ liệu mô phỏng (day02 → day14)
    └── real_data/               Kết quả lọc log thật (day15)
```

| Thư mục | Script | Nội dung |
|---|---|---|
| `01_setup` | `test_matlab.m` | Làm quen MATLAB: mô phỏng sóng sin |
| `02_simulation` | `day02_generate_imu.m` | Sinh tín hiệu IMU mô phỏng và nhiễu rung |
| | `day03_fft_psd_analysis.m` | Phân tích FFT và PSD của tín hiệu gốc |
| `03_lms_rls` | `day04_lms.m` | Cài đặt bộ lọc LMS |
| | `day05_rls.m` | Cài đặt bộ lọc RLS |
| | `day06_compare_lms_rls.m` | So sánh LMS và RLS trong miền thời gian |
| | `day07_fft_psd_comparison.m` | So sánh trong miền tần số (FFT/PSD) |
| | `day08_rmse_snr_evaluation.m` | Đánh giá RMSE, SNR và đường hội tụ sai số |
| `04_parameter_study` | `day09_parameter_study.m` | Khảo sát tham số `μ` (LMS) và `λ` (RLS) |
| | `day09_rls_diagnostic.m` | Chẩn đoán RLS mất ổn định khi `λ` nhỏ |
| | `day12_parameter_sensitivity.m` | Độ nhạy của kết quả với tham số |
| `05_robustness` | `day10_check_inputs.m` | Kiểm tra dữ liệu đầu vào |
| | `day10_vibration_levels.m` | Thử với 4 mức nhiễu rung (0.25, 0.5, 1.0, 1.5) |
| | `day10_frequency_levels.m` | FFT/PSD theo từng mức rung |
| | `day10_residual_validation.m` | Kiểm tra nhiễu dư sau lọc |
| | `day11_convergence_analysis.m` | Phân tích hội tụ và ổn định |
| `06_summary` | `day13_*.m` | Tổng hợp kết quả và vẽ hình cuối cùng |
| | `day14_*.m` | Kiểm tra, xác nhận toàn bộ file kết quả |
| `07_real_data` | `day15_step01_inspect_px4_log.m` | Liệt kê các topic trong log bay PX4 (`.ulg`, cần UAV Toolbox) |
| | `day15_step02_filter_bench_log.m` | Lọc NLMS/RLS (dạng ALE) trên log bàn thử `bench_lms_rls_01` |

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

### Trên log bàn thử thật (`bench_lms_rls_01`)

Log thật không có tín hiệu tham chiếu nhiễu, nên `day15_step02` dùng cấu trúc **Adaptive Line Enhancer**: tham chiếu là chính tín hiệu IMU trễ 5 mẫu. Giảm RMS rung so với mức khi tắt động cơ (`results/real_data/day15_bench_rms_summary.csv`):

| Đoạn | X (NLMS / RLS) | Y (NLMS / RLS) | Z (NLMS / RLS) |
|---|---|---|---|
| PWM 1100 | 2 % / −1 % | 4 % / 3 % | 1 % / −1 % |
| PWM 1212 | 11 % / 20 % | 19 % / 29 % | 6 % / 9 % |
| PWM 1412 | 23 % / 26 % | 24 % / 24 % | 19 % / 20 % |

Mức giảm thấp hơn mô phỏng vì không có tham chiếu nhiễu thật và log chỉ lấy mẫu khoảng 147 Hz, nên rung tần số cao bị chồng phổ.

### Trên log bay PX4 (sơ bộ)

Báo cáo (mục 4.5) chạy NLMS/RLS dạng ALE trên topic `sensor_combined_0` của log bay (`Fs ≈ 208 Hz`, khoảng 70 s). RMS AC của đầu ra dự đoán `y(n)` thấp hơn tín hiệu gốc 18.9–28.1 % với NLMS và 34.9–42.3 % với RLS. Tuy vậy, PSD cho thấy các đỉnh rung 14 Hz và 22 Hz vẫn còn, nên đây **chưa phải** là mức khử rung thực sự. Nhánh này cần làm tiếp.

---

## 4. Cách chạy

1. Mở MATLAB (R2023a trở lên).
2. Chạy các script theo thứ tự thư mục `code/01_setup` → `code/07_real_data`. Mỗi script tự xác định thư mục gốc của repo, nên không cần sửa đường dẫn.
3. Kết quả mô phỏng được ghi vào `results/simulation/`. Script sau dùng file `.mat` do script trước tạo ra trong thư mục này.
4. Script dữ liệu thật đọc log trong `data/` và ghi kết quả vào `results/real_data/`.

**Biên dịch báo cáo:** nén thư mục `docs/report/latex/` thành file zip rồi tải lên Overleaf (New Project → Upload Project), hoặc biên dịch tại máy với `main.tex` là file chính (BibTeX, kiểu IEEEtran).

---

## 5. Hướng phát triển

- Hoàn thiện nhánh log bay PX4 (`data/flight/log_4_2026-10-25-17-24-42.ulg`). Báo cáo đã có kết quả sơ bộ (mục 4.5) từ script `day16_step04_filter_flight_imu.m`, nhưng script này chưa được đưa vào repo.
- Ghi thêm log bàn thử với tần số lấy mẫu cao hơn (200–250 Hz) và mỗi mức ga dài hơn 20 s. Xem hướng dẫn trong [`docs/HUONG_DAN_GHI_LOG.md`](docs/HUONG_DAN_GHI_LOG.md).
- Thử các biến thể như NLMS và RLS có regularization để cải thiện độ ổn định.
