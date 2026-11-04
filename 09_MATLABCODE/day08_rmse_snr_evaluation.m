
%% DAY 08 - RMSE, SNR AND CONVERGENCE EVALUATION
% MATLAB R2023a
% Project: Adaptive LMS/RLS IMU noise reduction
% Data source: Day 06 simulation results

clear;
clc;
close all;

%% 1. Define folders
rootDir = 'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';
resultDir = fullfile(rootDir, '06_RESULTS');

inputFile = fullfile(resultDir, ...
    'day06_comparison_results.mat');

if ~isfile(inputFile)
    error('Cannot find Day 06 result file.');
end

%% 2. Load and validate data
R = load(inputFile);

required = {'Fs','t','s','d','lms','rls'};

for k = 1:numel(required)
    if ~isfield(R, required{k})
        error('Missing variable: %s', required{k});
    end
end

Fs = R.Fs;
t = R.t(:);
s = R.s(:);
d = R.d(:);
lms = R.lms(:);
rls = R.rls(:);

N = numel(t);

assert(Fs > 0 && isfinite(Fs), 'Invalid Fs.');
assert(all([numel(s),numel(d), ...
    numel(lms),numel(rls)] == N), ...
    'Signal lengths do not match.');

assert(all(isfinite([t;s;d;lms;rls])), ...
    'Signals contain NaN or Inf.');

assert(all(diff(t) > 0), ...
    'Time vector must be increasing.');

dtError = max(abs(diff(t) - 1/Fs));

fprintf('\n===== DAY 08 DATA CHECK =====\n');
fprintf('Fs: %.2f Hz\n', Fs);
fprintf('Samples: %d\n', N);
fprintf('Nyquist: %.2f Hz\n', Fs/2);
fprintf('Maximum dt error: %.3e s\n', dtError);

if dtError > 1e-6/Fs
    warning('Sampling intervals are not uniform.');
end

%% 3. Define evaluation periods
idxAll = true(N,1);
idxSteady = t >= 3;

assert(any(idxSteady), ...
    'No samples in steady-state interval.');

signals = [d, lms, rls];
names = {'Raw';'LMS';'RLS'};

%% 4. Compute RMSE and SNR
rmseAll = zeros(3,1);
rmseSteady = zeros(3,1);

snrAll = zeros(3,1);
snrSteady = zeros(3,1);

for k = 1:3

    err = signals(:,k) - s;

    rmseAll(k) = sqrt(mean(err(idxAll).^2));
    rmseSteady(k) = ...
        sqrt(mean(err(idxSteady).^2));

    signalPowerAll = mean(s(idxAll).^2);
    noisePowerAll = mean(err(idxAll).^2);

    signalPowerSteady = ...
        mean(s(idxSteady).^2);
    noisePowerSteady = ...
        mean(err(idxSteady).^2);

    snrAll(k) = 10*log10( ...
        signalPowerAll/noisePowerAll);

    snrSteady(k) = 10*log10( ...
        signalPowerSteady/noisePowerSteady);
end

%% 5. Calculate improvements
rmseReductionAll = ...
    100*(1-rmseAll/rmseAll(1));

rmseReductionSteady = ...
    100*(1-rmseSteady/rmseSteady(1));

snrGainAll = snrAll - snrAll(1);
snrGainSteady = snrSteady - snrSteady(1);

%% 6. Create comparison table
comparisonTable = table( ...
    names, ...
    rmseAll, ...
    rmseSteady, ...
    rmseReductionAll, ...
    rmseReductionSteady, ...
    snrAll, ...
    snrSteady, ...
    snrGainAll, ...
    snrGainSteady, ...
    'VariableNames', { ...
    'Method', ...
    'RMSE_All', ...
    'RMSE_Steady', ...
    'RMSE_Reduction_All_Pct', ...
    'RMSE_Reduction_Steady_Pct', ...
    'SNR_All_dB', ...
    'SNR_Steady_dB', ...
    'SNR_Gain_All_dB', ...
    'SNR_Gain_Steady_dB'});

fprintf('\n===== DAY 08 RESULTS =====\n');
disp(comparisonTable);

%% 7. Plot RMSE comparison
fig1 = figure('Color','w');

bar([rmseAll,rmseSteady]);
grid on;

set(gca,'XTick',1:3, ...
    'XTickLabel',names);

ylabel('RMSE (m/s^2)');
title('Day 08 - RMSE Comparison');
legend('Full signal','3-10 s', ...
    'Location','best');

saveas(fig1,fullfile(resultDir, ...
    'day08_rmse_comparison.png'));

%% 8. Plot SNR comparison
fig2 = figure('Color','w');

bar([snrAll,snrSteady]);
grid on;

set(gca,'XTick',1:3, ...
    'XTickLabel',names);

ylabel('SNR (dB)');
title('Day 08 - SNR Comparison');
legend('Full signal','3-10 s', ...
    'Location','best');

saveas(fig2,fullfile(resultDir, ...
    'day08_snr_comparison.png'));

%% 9. Moving mean squared error
windowLength = round(0.5*Fs);
windowLength = max(windowLength,1);

mseRaw = movmean((d-s).^2,windowLength);
mseLMS = movmean((lms-s).^2,windowLength);
mseRLS = movmean((rls-s).^2,windowLength);

fig3 = figure('Color','w');

plot(t,10*log10(max(mseRaw,eps)), ...
    'k','LineWidth',1);
hold on;

plot(t,10*log10(max(mseLMS,eps)), ...
    'b','LineWidth',1.2);

plot(t,10*log10(max(mseRLS,eps)), ...
    'r','LineWidth',1.2);

xline(3,'--','3 s');

grid on;
xlabel('Time (s)');
ylabel('Moving MSE (dB re (m/s^2)^2)');
title('Day 08 - Error Evolution');
legend('Raw','LMS','RLS', ...
    'Location','best');

saveas(fig3,fullfile(resultDir, ...
    'day08_error_convergence.png'));

%% 10. Save all results
save(fullfile(resultDir, ...
    'day08_evaluation_results.mat'), ...
    'Fs','t','s','d','lms','rls', ...
    'comparisonTable', ...
    'rmseAll','rmseSteady', ...
    'snrAll','snrSteady', ...
    'snrGainAll','snrGainSteady', ...
    'mseRaw','mseLMS','mseRLS', ...
    'windowLength','dtError');

writetable(comparisonTable, ...
    fullfile(resultDir, ...
    'day08_evaluation.csv'));

fprintf('\n===== DAY 08 COMPLETED =====\n');
fprintf('Results saved to 06_RESULTS.\n');
