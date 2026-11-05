# Hướng dẫn ghi log IMU thực tế để kiểm chứng LMS/RLS

Mục tiêu: thu dữ liệu IMU thật khi động cơ quay trên bàn thử, sau đó lọc bằng LMS/RLS trong MATLAB và so sánh **trước / sau khi lọc**, giống phần mô phỏng (day04 – day13).

> LMS/RLS là thuật toán nhân quả, xử lý từng mẫu một (chỉ dùng mẫu hiện tại và quá khứ). Vì vậy lọc offline trên log đã ghi cho kết quả giống hệt chạy thời gian thực trên flight controller.

---

## 1. Chuẩn bị

| Thứ cần có | Ghi chú |
|---|---|
| Flight controller chạy PX4 (Mamba F405 MK2, PX4 v1.17) | Cắm USB vào máy tính |
| Pin + ESC + 4 động cơ | Pin đủ điện |
| QGroundControl (`~/Applications/QGroundControl.AppImage`) | Chạy trong WSL |
| Script ghi log: `~/drone/scripts/imu_log.py`, `plot_imu.py` | Cần `pymavlink`, `numpy`, `matplotlib` |
| Kẹp / băng dính cố định khung | Máy phải **đứng yên tuyệt đối** trong suốt lúc ghi |

**An toàn:**
- **THÁO HẾT CÁNH QUẠT** trước khi chạy động cơ.
- Kẹp chặt khung xuống bàn. Không chạm tay vào động cơ khi đang quay.
- Không vượt quá khoảng 40 % ga khi thử trên bàn.

> Script `motor_imu_test.py` (dùng `MAV_CMD_ACTUATOR_TEST`) hiện **không làm động cơ quay** (log `test1.csv` có PWM = 0). Vì vậy dùng **QGC để quay động cơ** và `imu_log.py` để ghi IMU song song.

---

## 2. Cấu hình (chỉ làm 1 lần)

1. Mở QGC → **Application Settings → MAVLink** → bật **Enable MAVLink forwarding**, host: `127.0.0.1:14445`.
   QGC giữ cổng USB, còn script nhận dữ liệu qua UDP nên không tranh cổng.
2. (Dự phòng) **Application Settings → General** → bật lưu telemetry log (`.tlog`), kể cả khi không arm.
3. (Tùy chọn) Muốn lấy mẫu > 200 Hz: đặt `IMU_INTEG_RATE = 400` rồi reboot FC.

---

## 3. Mỗi lần ghi log

### Bước 1 – Tăng tần số gửi IMU

QGC → **Analyze Tools → MAVLink Console**, gõ:

```
mavlink stream -d /dev/ttyACM0 -s HIGHRES_IMU -r 250
mavlink stream -d /dev/ttyACM0 -s SERVO_OUTPUT_RAW -r 50
mavlink status streams
```

Lệnh cuối để kiểm tra rate thực. Các lệnh `mavlink stream` **mất tác dụng sau khi reboot**, nên mỗi lần cắm lại FC phải gõ lại.

### Bước 2 – Bắt đầu ghi IMU (terminal WSL)

```bash
cd ~/drone/logs
python3 ../scripts/imu_log.py --port udpin:127.0.0.1:14445 --rate 250 --out bench_lms_rls_01.csv
```

Chờ đến khi thấy `Kết nối OK` và dòng số liệu chạy liên tục.

### Bước 3 – Quay động cơ theo kịch bản

QGC → **Vehicle Setup → Actuators** → bật **Enable sliders**, kéo **cả 4 thanh trượt cùng mức** và giữ yên:

| Đoạn | Thời gian | Mục đích trong thuật toán |
|---|---|---|
| Động cơ tắt | ~20 s | Tín hiệu sạch `s(n)` (chỉ có trọng lực) |
| Ga ~15 % | ~20 s | Mức rung 1 |
| Ga ~25 % | ~20 s | Mức rung 2 |
| Ga ~35 % | ~20 s | Mức rung 3 |
| Động cơ tắt | ~10 s | Kiểm tra lại mức nền |

- Không cần đúng phần trăm: PWM được ghi lại để tự tách đoạn sau.
- Mỗi bậc nên **≥ 20 s** để LMS kịp hội tụ (khoảng 2 s) và còn đủ đoạn xác lập để tính RMSE.
- Trong suốt quá trình: **không chạm, không di chuyển máy**.

### Bước 4 – Dừng ghi

Kéo tất cả thanh trượt về 0, tắt **Enable sliders**, rồi nhấn **Ctrl+C** ở terminal.

### Bước 5 – Kiểm tra nhanh

```bash
python3 ../scripts/plot_imu.py bench_lms_rls_01.csv
```

Log đạt yêu cầu khi:

- [ ] Tần số mẫu khoảng 200 – 250 Hz (in trên tiêu đề hình)
- [ ] Cột PWM có các bậc rõ ràng, **khác 0** khi động cơ quay
- [ ] Độ lệch chuẩn accel **tăng rõ** theo từng bậc ga (bảng in ra cuối)
- [ ] Không có khoảng mất dữ liệu dài (kiểm tra cột `time_usec_or_ms`)

Nếu chưa đạt: kiểm tra lại Bước 1 (rate), dây USB và pin, rồi ghi lại.

### Bước 6 – Lưu vào project

Sao chép log đạt yêu cầu vào repo (dùng lệnh Linux trong WSL, **không** copy qua Windows Explorer):

```bash
cp ~/drone/logs/bench_lms_rls_01.csv ~/advanced-signal-processing-imu-lms-rls/data/bench/
```

Ghi chú kèm theo (file `data/bench/<tên_log>_NOTES.md`): ngày ghi, loại động cơ (KV), số cell pin, có / không lắp cánh quạt, các mức PWM đã dùng.

---

## 4. Ánh xạ dữ liệu vào thuật toán (để xử lý bằng MATLAB)

| Đại lượng | Lấy từ log |
|---|---|
| `d(n)` – tín hiệu đo | `xacc`, `yacc`, `zacc` khi động cơ quay |
| `s(n)` – tín hiệu sạch | Trung bình accel trong đoạn động cơ tắt (máy đứng yên → chỉ có trọng lực) |
| `x(n)` – tham chiếu nhiễu | `sin/cos` tại tần số rung, lấy theo đỉnh PSD của từng bậc ga (hoặc từ RPM của ESC nếu bật được Bidirectional DShot) |
| Trục thời gian | `time_usec_or_ms` (thời gian của FC), **không** dùng `host_time` |

Sau đó chạy LMS/RLS và vẽ các hình như day04 – day13: tín hiệu theo thời gian, FFT/PSD trước và sau lọc, RMSE/SNR theo từng mức ga, đường hội tụ.
