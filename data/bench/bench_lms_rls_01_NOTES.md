# bench_lms_rls_01 — ghi chú log IMU thực tế

- Ngày ghi: 2026-11-05
- FC: Mamba F405 MK2, PX4 v1.17, USB → QGC → MAVLink forward UDP 14445 → `imu_log.py`
- Thời lượng: ~203 s, 29 906 mẫu HIGHRES_IMU (~147 Hz trung bình, chưa đạt 200–250 Hz)
- Động cơ (KV), số cell pin, cánh quạt: _cần bổ sung_

## Kịch bản PWM (4 động cơ cùng mức)

| Thời gian (s) | PWM |
|---|---|
| 0–43 | 1000 (tắt) — có va chạm ~36–39 s |
| 43–56 | 1140 |
| 56–73 | 1196 |
| 73–128 | 1000 (tắt) — có va chạm ~86 s; đoạn 90–125 s sạch |
| 128–143 | 1100 |
| 143–155 | 1212 |
| 156–167 | 1412 |
| 167–183 | 1900 (vượt giới hạn 40 % ga — nên bỏ) |
| 184–203 | 1000 (tắt, sạch) |

## Đánh giá

- ✅ PWM có bậc rõ, rung tăng theo ga, không mất dữ liệu (dt max 18 ms)
- ❌ Tần số mẫu thấp, các bậc < 20 s, có va chạm khi động cơ tắt
- Đề xuất dùng: lượt 2 (128–167 s) với nền sạch 90–125 s và 184–203 s
