
%% =========================================================
% DAY 13 - FINAL SUMMARY OF LMS / RLS
% Project: Adaptive LMS/RLS for IMU vibration noise reduction
% MATLAB R2023a
%
% Input:
%   day06_comparison_results.mat
%
% Output:
%   day13_final_summary.csv
%   day13_final_summary.mat
%% =========================================================

clc;
clear;
close all;

fprintf('\n============================================\n');
fprintf('       DAY 13 - FINAL SUMMARY\n');
fprintf('============================================\n\n');

%% STEP 1 - PROJECT PATH

projectDir = ...
    'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';

resultDir = fullfile(projectDir, '06_RESULTS');

dataFile = fullfile(resultDir, ...
    'day06_comparison_results.mat');

if ~isfolder(resultDir)
    error('Result directory does not exist.');
end

if ~isfile(dataFile)
    error('Day 06 comparison file not found.');
end

fprintf('Result directory: %s\n\n', resultDir);

%% STEP 2 - LOAD DATA

D = load(dataFile);

requiredVariables = {'Fs','t','s','d','lms','rls'};

for k = 1:numel(requiredVariables)

    variableName = requiredVariables{k};

    if ~isfield(D, variableName)
        error('Missing variable: %s', variableName);
    end

end

Fs = D.Fs;

t = D.t(:);
s = D.s(:);
d = D.d(:);

% Day 06 stores LMS and RLS as numeric vectors.
% These must represent the denoised outputs.

eLMS = D.lms(:);
eRLS = D.rls(:);

N = numel(t);

fprintf('===== DAY 13 DATA CHECK =====\n');

fprintf('Sampling frequency: %.2f Hz\n', Fs);
fprintf('Number of samples: %d\n', N);

%% STEP 3 - VALIDATE DATA

if ~isnumeric(Fs) || ~isscalar(Fs) || ...
        ~isfinite(Fs) || Fs <= 0
    error('Invalid sampling frequency.');
end

signals = {t, s, d, eLMS, eRLS};

signalNames = {'t','s','d','LMS','RLS'};

for k = 1:numel(signals)

    currentSignal = signals{k};

    if ~isnumeric(currentSignal) || ...
            ~isvector(currentSignal)
        error('Invalid signal format: %s', ...
            signalNames{k});
    end

    if numel(currentSignal) ~= N
        error('Signal length mismatch: %s', ...
            signalNames{k});
    end

    if any(~isfinite(currentSignal))
        error('NaN or Inf found in: %s', ...
            signalNames{k});
    end

end

if N < 2
    error('Not enough samples.');
end

dt = diff(t);

maxDtError = max(abs(dt - 1/Fs));

fprintf('Nyquist frequency: %.2f Hz\n', Fs/2);

fprintf('Max sampling interval error: %.3e s\n', ...
    maxDtError);

samplingTolerance = 1e-6 / Fs;

if maxDtError > samplingTolerance
    error('Sampling intervals are not uniform.');
end

if Fs/2 <= 30
    warning('30 Hz is not below Nyquist frequency.');
end

%% STEP 4 - STEADY-STATE WINDOW

steadyStart = 3.0;

idx = t >= steadyStart;

if ~any(idx)
    error('Steady-state window is empty.');
end

fprintf('\n===== STEADY-STATE WINDOW =====\n');

fprintf('Start time: %.2f s\n', steadyStart);

fprintf('End sample time: %.4f s\n', t(end));

fprintf('Steady samples: %d\n', sum(idx));

%% STEP 5 - CALCULATE ERRORS

errorRaw = d - s;

errorLMS = eLMS - s;

errorRLS = eRLS - s;

%% STEP 6 - CALCULATE RMSE

rmseRaw = sqrt(mean(errorRaw(idx).^2));

rmseLMS = sqrt(mean(errorLMS(idx).^2));

rmseRLS = sqrt(mean(errorRLS(idx).^2));

fprintf('\n===== STEADY-STATE RMSE =====\n');

fprintf('Raw RMSE: %.6f m/s^2\n', rmseRaw);

fprintf('LMS RMSE: %.6f m/s^2\n', rmseLMS);

fprintf('RLS RMSE: %.6f m/s^2\n', rmseRLS);

%% STEP 7 - CALCULATE SNR

signalPower = mean(s(idx).^2);

if signalPower <= 0
    error('Ideal signal power must be positive.');
end

noisePowerRaw = mean(errorRaw(idx).^2);

noisePowerLMS = mean(errorLMS(idx).^2);

noisePowerRLS = mean(errorRLS(idx).^2);

snrRaw = 10*log10(signalPower/noisePowerRaw);

snrLMS = 10*log10(signalPower/noisePowerLMS);

snrRLS = 10*log10(signalPower/noisePowerRLS);

fprintf('\n===== STEADY-STATE SNR =====\n');

fprintf('Raw SNR: %.4f dB\n', snrRaw);

fprintf('LMS SNR: %.4f dB\n', snrLMS);

fprintf('RLS SNR: %.4f dB\n', snrRLS);

%% STEP 8 - RMSE REDUCTION

rmseReductionRaw = 0;

rmseReductionLMS = ...
    (rmseRaw-rmseLMS)/rmseRaw*100;

rmseReductionRLS = ...
    (rmseRaw-rmseRLS)/rmseRaw*100;

%% STEP 9 - SNR IMPROVEMENT

snrGainRaw = 0;

snrGainLMS = snrLMS-snrRaw;

snrGainRLS = snrRLS-snrRaw;

fprintf('\n===== IMPROVEMENT =====\n');

fprintf('LMS RMSE reduction: %.2f %%\n', ...
    rmseReductionLMS);

fprintf('RLS RMSE reduction: %.2f %%\n', ...
    rmseReductionRLS);

fprintf('LMS SNR gain: %.4f dB\n', snrGainLMS);

fprintf('RLS SNR gain: %.4f dB\n', snrGainRLS);

%% STEP 10 - CREATE SUMMARY TABLE

Method = {'Raw'; 'LMS'; 'RLS'};

RMSE_Steady = [ ...
    rmseRaw;
    rmseLMS;
    rmseRLS
];

RMSE_Reduction_Pct = [ ...
    rmseReductionRaw;
    rmseReductionLMS;
    rmseReductionRLS
];

SNR_dB = [ ...
    snrRaw;
    snrLMS;
    snrRLS
];

SNR_Gain_dB = [ ...
    snrGainRaw;
    snrGainLMS;
    snrGainRLS
];

summaryTable = table( ...
    Method, ...
    RMSE_Steady, ...
    RMSE_Reduction_Pct, ...
    SNR_dB, ...
    SNR_Gain_dB);

fprintf('\n===== DAY 13 FINAL SUMMARY =====\n');

disp(summaryTable);

%% STEP 11 - COMPARE WITH DAY 11

% Reference values reported from Day 11.
% These are used for verification only.

referenceRMSE = [ ...
    0.613629;
    0.105373;
    0.104201
];

calculatedRMSE = RMSE_Steady;

differenceRMSE = abs( ...
    calculatedRMSE-referenceRMSE);

tolerance = 1e-4;

fprintf('\n===== DAY 11 CONSISTENCY CHECK =====\n');

for k = 1:3

    fprintf('%s difference: %.8f\n', ...
        Method{k}, differenceRMSE(k));

end

consistencyPassed = all(differenceRMSE < tolerance);

if consistencyPassed

    fprintf('PASS: RMSE matches Day 11 results.\n');

else

    warning(['RMSE differs from Day 11. ', ...
        'Check the output signal definitions ', ...
        'and evaluation window.']);

end

%% STEP 12 - SAVE RESULTS

if consistencyPassed

    csvFile = fullfile(resultDir, ...
        'day13_final_summary.csv');

    matFile = fullfile(resultDir, ...
        'day13_final_summary.mat');

    writetable(summaryTable, csvFile);

    save(matFile, ...
        'summaryTable', ...
        'Fs', 'N', 't', 's', 'd', ...
        'eLMS', 'eRLS', ...
        'idx', 'steadyStart', ...
        'rmseRaw', 'rmseLMS', 'rmseRLS', ...
        'snrRaw', 'snrLMS', 'snrRLS', ...
        'maxDtError', ...
        'consistencyPassed');

    fprintf('\n===== FILES SAVED =====\n');

    fprintf('%s\n', csvFile);
    fprintf('%s\n', matFile);

    fprintf('\n===== DAY 13 SUMMARY COMPLETED =====\n');

else

    fprintf('\n===== VALIDATION NOT PASSED =====\n');

    fprintf(['Summary files were not saved. ', ...
        'Please inspect the data first.\n']);

end
