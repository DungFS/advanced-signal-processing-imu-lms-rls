
%% =========================================================
% DAY 10 - INPUT DATA CHECK
% Project: Adaptive LMS/RLS for IMU Vibration Noise Reduction
% MATLAB Version: R2023a
% No additional toolbox required for correlation
%% =========================================================

clc;
clear;
close all;

%% STEP 1 - DEFINE PROJECT DIRECTORIES

rootDir = ...
    fileparts(fileparts(fileparts(mfilename('fullpath'))));

resultDir = fullfile(rootDir, 'results', 'simulation');

fileDay02 = fullfile(resultDir, ...
    'day02_imu_data.mat');

fileDay04 = fullfile(resultDir, ...
    'day04_lms_results.mat');

fprintf('===== DAY 10 INPUT CHECK =====\n');

%% STEP 2 - CHECK INPUT FILES

assert(isfile(fileDay02), ...
    'Missing file: day02_imu_data.mat');

assert(isfile(fileDay04), ...
    'Missing file: day04_lms_results.mat');

fprintf('\n===== DAY 02 VARIABLES =====\n');
whos('-file', fileDay02);

fprintf('\n===== DAY 04 VARIABLES =====\n');
whos('-file', fileDay04);

%% STEP 3 - LOAD DATA

A = load(fileDay02);
B = load(fileDay04);

requiredA = {'Fs', 't', 's', 'd', ...
    'v_motor', 'v_random'};

requiredB = {'x', 'M', 'mu'};

for i = 1:numel(requiredA)

    assert(isfield(A, requiredA{i}), ...
        ['Missing Day 02 variable: ', requiredA{i}]);

end

for i = 1:numel(requiredB)

    assert(isfield(B, requiredB{i}), ...
        ['Missing Day 04 variable: ', requiredB{i}]);

end

%% STEP 4 - PREPARE SIGNALS

Fs = A.Fs;

t = A.t(:);
s = A.s(:);
d = A.d(:);

v_motor = A.v_motor(:);
v_random = A.v_random(:);

x = B.x(:);

M = B.M;
mu = B.mu;

N = numel(s);

%% STEP 5 - VALIDATE SIGNAL DIMENSIONS

assert(all([ ...
    numel(t), ...
    numel(d), ...
    numel(v_motor), ...
    numel(v_random), ...
    numel(x)] == N), ...
    'Signal lengths do not match');

assert(isfinite(Fs) && Fs > 0, ...
    'Invalid sampling frequency');

assert(all(isfinite([ ...
    t; s; d; v_motor; v_random; x])), ...
    'Signals contain NaN or Inf');

%% STEP 6 - CHECK SIGNAL MODEL

d_reconstructed = s + v_motor + v_random;

modelError = max(abs(d - d_reconstructed));

fprintf('\n===== SIGNAL CHECK =====\n');

fprintf('Fs = %.2f Hz\n', Fs);
fprintf('N = %d\n', N);
fprintf('Duration = %.2f s\n', N/Fs);
fprintf('Nyquist = %.2f Hz\n', Fs/2);

fprintf('Model error = %.3e\n', modelError);

assert(modelError < 1e-10, ...
    'Day 02 signal model is inconsistent');

%% STEP 7 - CHECK SAMPLING INTERVAL

dt = diff(t);

expectedDt = 1/Fs;

maxDtError = max(abs(dt - expectedDt));

fprintf('\n===== SAMPLING CHECK =====\n');

fprintf('Expected dt = %.6f s\n', expectedDt);

fprintf('Maximum dt error = %.3e s\n', ...
    maxDtError);

assert(maxDtError < 1e-8, ...
    'Sampling interval is inconsistent');

%% STEP 8 - CALCULATE CORRELATION
% Pearson correlation without corr() function

noiseTotal = d - s;

% Remove means
x0 = x - mean(x);

motor0 = v_motor - mean(v_motor);

noise0 = noiseTotal - mean(noiseTotal);

% Denominators
denMotor = sqrt( ...
    sum(x0.^2) * sum(motor0.^2));

denTotal = sqrt( ...
    sum(x0.^2) * sum(noise0.^2));

% Avoid division by zero
assert(denMotor > 0 && denTotal > 0, ...
    'Cannot calculate correlation: zero variance');

% Pearson correlation coefficients
rhoMotor = sum(x0 .* motor0) / denMotor;

rhoTotal = sum(x0 .* noise0) / denTotal;

fprintf('\n===== REFERENCE CHECK =====\n');

fprintf('corr(x, v_motor) = %.6f\n', ...
    rhoMotor);

fprintf('corr(x, total noise) = %.6f\n', ...
    rhoTotal);

%% STEP 9 - CHECK LMS PARAMETERS

fprintf('\n===== LMS PARAMETERS =====\n');

fprintf('Filter order M = %d\n', M);

fprintf('Step size mu = %.6f\n', mu);

%% STEP 10 - SIGNAL STATISTICS

rmsIdeal = sqrt(mean(s.^2));

rmsMotor = sqrt(mean(v_motor.^2));

rmsRandom = sqrt(mean(v_random.^2));

rmsRaw = sqrt(mean(d.^2));

rmsReference = sqrt(mean(x.^2));

fprintf('\n===== SIGNAL RMS =====\n');

fprintf('Ideal RMS = %.6f\n', rmsIdeal);

fprintf('Motor noise RMS = %.6f\n', rmsMotor);

fprintf('Random noise RMS = %.6f\n', rmsRandom);

fprintf('Raw RMS = %.6f\n', rmsRaw);

fprintf('Reference RMS = %.6f\n', rmsReference);

%% STEP 11 - PLOT INPUT SIGNALS

figure('Name', 'Day 10 Input Signal Check', ...
    'Color', 'w');

subplot(4,1,1);

plot(t, s, 'b');
grid on;

title('Ideal IMU Signal');
ylabel('m/s^2');

subplot(4,1,2);

plot(t, d, 'r');
grid on;

title('Raw IMU Signal');
ylabel('m/s^2');

subplot(4,1,3);

plot(t, v_motor, 'm');
grid on;

title('Motor Vibration Noise');
ylabel('m/s^2');

subplot(4,1,4);

plot(t, x, 'k');
grid on;

title('Reference Signal');
xlabel('Time (s)');
ylabel('m/s^2');

%% STEP 12 - SAVE CHECK RESULTS

outputFile = fullfile(resultDir, ...
    'day10_input_check.mat');

save(outputFile, ...
    'Fs', 'N', 't', 's', 'd', ...
    'v_motor', 'v_random', 'x', ...
    'M', 'mu', ...
    'rhoMotor', 'rhoTotal', ...
    'modelError', 'maxDtError');

figureFile = fullfile(resultDir, ...
    'day10_input_check.png');

saveas(gcf, figureFile);

%% STEP 13 - COMPLETION MESSAGE

fprintf('\n===== DAY 10 INPUT CHECK RESULTS =====\n');

fprintf('Model consistency: PASS\n');

fprintf('Sampling interval: PASS\n');

fprintf('Reference correlation: CALCULATED\n');

fprintf('\nSaved MAT file:\n%s\n', outputFile);

fprintf('\nSaved figure:\n%s\n', figureFile);

fprintf('\n===== DAY 10 INPUT CHECK COMPLETED =====\n');
