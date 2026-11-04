
%% DAY 03 - FFT AND PSD ANALYSIS
% Project: Adaptive LMS/RLS for IMU vibration noise reduction
% MATLAB R2023a

clear;
clc;
close all;

%% STEP 1: LOAD DAY 02 DATA

projectFolder = ...
    'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';

dataFile = fullfile(projectFolder, ...
    '06_RESULTS', 'day02_imu_data.mat');

outputFolder = fullfile(projectFolder, '06_RESULTS');

assert(isfile(dataFile), 'Day 02 data file not found.');

data = load(dataFile);

Fs = data.Fs;
t = data.t(:);
s = data.s(:);
d = data.d(:);
v = data.v(:);
v_motor = data.v_motor(:);
v_random = data.v_random(:);

N = length(d);

%% STEP 2: VALIDATE DATA

assert(Fs > 0 && isfinite(Fs), 'Invalid Fs.');
assert(all(isfinite([s; d; v; v_motor; v_random])), ...
    'Signal contains NaN or Inf.');

assert(all([length(t), length(s), length(v), ...
    length(v_motor), length(v_random)] == N), ...
    'Signal lengths do not match.');

dt = diff(t);
assert(all(dt > 0), 'Time vector must be increasing.');

fprintf('===== DATA INFORMATION =====\n');
fprintf('Sampling frequency: %.2f Hz\n', Fs);
fprintf('Number of samples: %d\n', N);
fprintf('Signal duration: %.2f s\n', N/Fs);
fprintf('Nyquist frequency: %.2f Hz\n', Fs/2);

fprintf('\n===== SIGNAL RELATION CHECK =====\n');
fprintf('max|d - (s+v)| = %.6g\n', ...
    max(abs(d-s-v)));

fprintf('max|v - (v_motor+v_random)| = %.6g\n', ...
    max(abs(v-v_motor-v_random)));

fprintf('Max sampling interval error: %.6g s\n', ...
    max(abs(dt-1/Fs)));

%% STEP 3: TIME DOMAIN PLOT

fig1 = figure('Name','Day03 Time Domain');

subplot(3,1,1);
plot(t,s,'b');
title('Ideal IMU Signal');
ylabel('Acceleration (m/s^2)');
grid on;

subplot(3,1,2);
plot(t,v,'r');
title('Total Vibration Noise');
ylabel('Acceleration (m/s^2)');
grid on;

subplot(3,1,3);
plot(t,d,'k');
title('Raw IMU Signal');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
grid on;

saveas(fig1, fullfile(outputFolder, ...
    'day03_time_domain.png'));

%% STEP 4: SINGLE-SIDED FFT

% Remove mean to focus on varying components
s0 = s - mean(s);
v0 = v - mean(v);
d0 = d - mean(d);

% FFT
S = fft(s0);
V = fft(v0);
D = fft(d0);

% Single-sided amplitude spectrum
nHalf = floor(N/2);

f = (0:nHalf)' * Fs/N;

A_s = abs(S(1:nHalf+1))/N;
A_v = abs(V(1:nHalf+1))/N;
A_d = abs(D(1:nHalf+1))/N;

% Double non-DC and non-Nyquist components
if mod(N,2) == 0
    idx = 2:nHalf;
else
    idx = 2:nHalf+1;
end

A_s(idx) = 2*A_s(idx);
A_v(idx) = 2*A_v(idx);
A_d(idx) = 2*A_d(idx);

fig2 = figure('Name','Day03 FFT');

subplot(3,1,1);
plot(f,A_s,'b');
title('FFT - Ideal Signal');
ylabel('Amplitude (m/s^2)');
grid on;
xlim([0 Fs/2]);

subplot(3,1,2);
plot(f,A_v,'r');
title('FFT - Noise Signal');
ylabel('Amplitude (m/s^2)');
grid on;
xlim([0 Fs/2]);

subplot(3,1,3);
plot(f,A_d,'k');
title('FFT - Raw Signal');
xlabel('Frequency (Hz)');
ylabel('Amplitude (m/s^2)');
grid on;
xlim([0 Fs/2]);

saveas(fig2, fullfile(outputFolder, ...
    'day03_fft.png'));

%% STEP 5: FIND DOMINANT FREQUENCY

% Exclude DC bin
[peakNoise, idxPeak] = max(A_v(2:end));
idxPeak = idxPeak + 1;

dominantFreq = f(idxPeak);

fprintf('\n===== FFT ANALYSIS =====\n');
fprintf('Dominant noise frequency: %.2f Hz\n', ...
    dominantFreq);
fprintf('Peak noise amplitude: %.6f m/s^2\n', ...
    peakNoise);
fprintf('FFT frequency resolution: %.4f Hz\n', Fs/N);

%% STEP 6: PSD USING WELCH METHOD

% Signal Processing Toolbox required
windowLength = 256;
window = hamming(windowLength);
overlap = 128;
nfft = 1024;

[P_s,f_psd] = pwelch(s0,window,overlap,nfft,Fs);
[P_v,~] = pwelch(v0,window,overlap,nfft,Fs);
[P_d,~] = pwelch(d0,window,overlap,nfft,Fs);

fig3 = figure('Name','Day03 PSD');

plot(f_psd,10*log10(P_s+eps),'b', ...
     'LineWidth',1.2);
hold on;

plot(f_psd,10*log10(P_v+eps),'r', ...
     'LineWidth',1.2);

plot(f_psd,10*log10(P_d+eps),'k', ...
     'LineWidth',1.2);

title('PSD Comparison - Welch Method');
xlabel('Frequency (Hz)');
ylabel('PSD (dB re 1 (m/s^2)^2/Hz)');
legend('Ideal','Noise','Raw');
grid on;
xlim([0 Fs/2]);

saveas(fig3, fullfile(outputFolder, ...
    'day03_psd.png'));

%% STEP 7: SAVE ANALYSIS DATA

save(fullfile(outputFolder,'day03_analysis.mat'), ...
    'Fs','N','f','A_s','A_v','A_d', ...
    'f_psd','P_s','P_v','P_d', ...
    'dominantFreq','peakNoise');

fprintf('\n===== DAY 03 COMPLETED =====\n');
fprintf('Figures and analysis data saved.\n');
