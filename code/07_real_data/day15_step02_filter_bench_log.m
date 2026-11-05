%% DAY 15 - STEP 02: LMS / RLS ON REAL BENCH IMU LOG
% Data: data/bench/bench_lms_rls_01.csv (HIGHRES_IMU via MAVLink, ~147 Hz)
%
% The real log has no motor-noise reference (v_motor) and no ideal signal
% (s), unlike the Day 02 simulation. We therefore use an Adaptive Line
% Enhancer (ALE): the reference input is the measured signal itself,
% delayed by Delta samples. Periodic motor vibration stays correlated over
% the delay and is predicted (y), while the rest is not. Output e = d - y
% is the vibration-cancelled signal.
%
% Evaluation (no ground truth): vibration RMS = RMS of deviation from the
% mean of the clean motors-off baseline, per PWM segment, raw vs filtered.

clear; clc; close all;

%% 1. PATHS
codeDir = fileparts(mfilename('fullpath'));
if isempty(codeDir), codeDir = pwd; end
baseDir = fileparts(fileparts(codeDir));
resultDir = fullfile(baseDir, 'results', 'real_data');
logFile = fullfile(baseDir, 'data', 'bench', 'bench_lms_rls_01.csv');
assert(isfile(logFile), 'Log not found: %s', logFile);

%% 2. LOAD AND RESAMPLE TO UNIFORM GRID
T = readtable(logFile);
T = T(strcmp(T.msg, 'HIGHRES_IMU'), :);

tRaw = (T.time_usec_or_ms - T.time_usec_or_ms(1)) * 1e-6;   % FC clock, s
[tRaw, iu] = unique(tRaw);
accRaw = [T.xacc(iu), T.yacc(iu), T.zacc(iu)];
pwmRaw = T.servo1(iu);
pwmRaw(isnan(pwmRaw)) = 1000;

dtRaw = diff(tRaw);
fprintf('===== RAW LOG =====\n');
fprintf('Samples: %d, duration: %.1f s\n', numel(tRaw), tRaw(end));
fprintf('Mean rate: %.1f Hz, dt max: %.1f ms\n', 1/mean(dtRaw), 1e3*max(dtRaw));

Fs = 150;                                   % uniform resampling rate
t = (0:1/Fs:tRaw(end)).';
acc = interp1(tRaw, accRaw, t, 'linear');
pwm = interp1(tRaw, pwmRaw, t, 'previous');
N = numel(t);

%% 3. SEGMENTS (from bench_lms_rls_01_NOTES.md)
baseIdx = (t >= 90 & t <= 125) | (t >= 184);       % clean, motors off
segs = { 'PWM 1100', 128, 143;
         'PWM 1212', 143, 155;
         'PWM 1412', 156, 167 };

%% 4. FILTER PARAMETERS (best values from Day 09 / Day 12)
M      = 16;       % filter length
Delta  = 5;        % ALE decorrelation delay (samples)
mu     = 0.01;     % NLMS step size
lambda = 0.995;    % RLS forgetting factor
delta  = 0.01;     % RLS initialisation

axisNames = {'X', 'Y', 'Z'};
outLMS = zeros(N, 3);
outRLS = zeros(N, 3);
results = table();

for a = 1:3
    g0 = mean(acc(baseIdx, a));             % static level (gravity/bias)
    d  = acc(:, a) - g0;                    % zero-mean primary signal
    x  = [zeros(Delta, 1); d(1:end-Delta)]; % delayed reference

    % ---- NLMS ----
    w = zeros(M, 1); eL = d;
    tic;
    for n = M:N
        xv = x(n:-1:n-M+1);
        y = w.' * xv;
        eL(n) = d(n) - y;
        w = w + (mu / (1e-6 + xv.' * xv)) * eL(n) * xv;
    end
    tL = toc;

    % ---- RLS ----
    w = zeros(M, 1); P = eye(M) / delta; eR = d;
    tic;
    for n = M:N
        xv = x(n:-1:n-M+1);
        eR(n) = d(n) - w.' * xv;
        Px = P * xv;
        K = Px / (lambda + xv.' * Px);
        w = w + K * eR(n);
        P = (P - K * Px.') / lambda;
        P = (P + P.') / 2;
    end
    tR = toc;

    outLMS(:, a) = eL + g0;
    outRLS(:, a) = eR + g0;

    for k = 1:size(segs, 1)
        idx = t >= segs{k, 2} & t <= segs{k, 3};
        rRaw = rms(d(idx)); rL = rms(eL(idx)); rR = rms(eR(idx));
        results = [results; table(string(axisNames{a}), string(segs{k, 1}), ...
            rRaw, rL, rR, 100*(1-rL/rRaw), 100*(1-rR/rRaw), ...
            'VariableNames', {'Axis','Segment','RMS_Raw','RMS_LMS','RMS_RLS', ...
            'LMS_Reduction_Pct','RLS_Reduction_Pct'})]; %#ok<AGROW>
    end
    fprintf('Axis %s: NLMS %.2f s, RLS %.2f s, baseline noise RMS %.4f m/s^2\n', ...
        axisNames{a}, tL, tR, rms(d(baseIdx)));
end

fprintf('\n===== VIBRATION RMS (deviation from motors-off level, m/s^2) =====\n');
disp(results);

%% 5. FIGURE 1 - TIME DOMAIN (Z axis, whole log + zoom)
az = 3;
fig1 = figure('Name', 'Bench log - time domain', 'Position', [80 80 1200 800]);

subplot(3, 1, 1);
plot(t, pwm, 'k'); grid on;
ylabel('PWM (us)'); title('Motor command (servo1)');
xlim([0 t(end)]);

subplot(3, 1, 2);
plot(t, acc(:, az), 'Color', [0.7 0.7 0.7]); hold on;
plot(t, outLMS(:, az), 'b');
plot(t, outRLS(:, az), 'r');
grid on; xlim([0 t(end)]);
ylabel('a_z (m/s^2)'); title('Z acceleration: raw vs NLMS vs RLS (ALE)');
legend('Raw', 'NLMS', 'RLS', 'Location', 'best');
for k = 1:size(segs, 1)
    xline(segs{k, 2}, ':k', 'HandleVisibility', 'off');
end

subplot(3, 1, 3);
iz = t >= 158 & t <= 160;
plot(t(iz), acc(iz, az), 'Color', [0.6 0.6 0.6]); hold on;
plot(t(iz), outLMS(iz, az), 'b');
plot(t(iz), outRLS(iz, az), 'r', 'LineWidth', 1.2);
grid on; xlabel('Time (s)'); ylabel('a_z (m/s^2)');
title('Zoom 158-160 s (PWM 1412)');
legend('Raw', 'NLMS', 'RLS', 'Location', 'best');

saveas(fig1, fullfile(resultDir, 'day15_bench_time_domain.png'));

%% 6. FIGURE 2 - PSD IN STRONGEST SEGMENT
idx = t >= 156 & t <= 167;
win = hamming(256); nov = 128; nfft = 1024;
fig2 = figure('Name', 'Bench log - PSD', 'Position', [120 120 1200 450]);
for a = 1:3
    subplot(1, 3, a);
    [pB, f] = pwelch(acc(baseIdx, a) - mean(acc(baseIdx, a)), win, nov, nfft, Fs);
    pRaw = pwelch(acc(idx, a) - mean(acc(idx, a)), win, nov, nfft, Fs);
    pL   = pwelch(outLMS(idx, a) - mean(outLMS(idx, a)), win, nov, nfft, Fs);
    pR   = pwelch(outRLS(idx, a) - mean(outRLS(idx, a)), win, nov, nfft, Fs);
    plot(f, 10*log10(pRaw), 'Color', [0.5 0.5 0.5]); hold on;
    plot(f, 10*log10(pL), 'b');
    plot(f, 10*log10(pR), 'r');
    plot(f, 10*log10(pB), 'k:', 'LineWidth', 1.2);
    grid on; xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)');
    title(sprintf('%s axis, PWM 1412', axisNames{a}));
    if a == 1, legend('Raw', 'NLMS', 'RLS', 'Motors off', 'Location', 'southwest'); end
end
saveas(fig2, fullfile(resultDir, 'day15_bench_psd.png'));

%% 7. FIGURE 3 - RMS REDUCTION BAR CHART
fig3 = figure('Name', 'Bench log - RMS', 'Position', [160 160 1100 400]);
for a = 1:3
    subplot(1, 3, a);
    r = results(results.Axis == axisNames{a}, :);
    bar(categorical(r.Segment), [r.RMS_Raw r.RMS_LMS r.RMS_RLS]);
    grid on; ylabel('Vibration RMS (m/s^2)');
    title(sprintf('%s axis', axisNames{a}));
    if a == 1, legend('Raw', 'NLMS', 'RLS', 'Location', 'northwest'); end
end
saveas(fig3, fullfile(resultDir, 'day15_bench_rms.png'));

%% 8. SAVE
writetable(results, fullfile(resultDir, 'day15_bench_rms_summary.csv'));
save(fullfile(resultDir, 'day15_bench_filter_results.mat'), ...
    't', 'Fs', 'acc', 'pwm', 'outLMS', 'outRLS', 'results', ...
    'M', 'Delta', 'mu', 'lambda', 'delta');
fprintf('\n===== STEP 02 COMPLETE =====\n');
