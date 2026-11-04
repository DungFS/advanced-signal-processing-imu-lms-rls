
%% =========================================================
% DAY 10 - MULTIPLE VIBRATION LEVELS
% LMS / RLS Adaptive Noise Cancellation
% MATLAB R2023a
% Simulation only
%% =========================================================

clc;
clear;
close all;

%% 1. PROJECT PATHS

rootDir = ...
 'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';

resultDir = fullfile(rootDir,'06_RESULTS');

inputFile = fullfile(resultDir, ...
 'day10_input_check.mat');

assert(isfile(inputFile), ...
 'Day 10 input check file not found');

A = load(inputFile);

Fs = A.Fs;
t = A.t(:);
s = A.s(:);
v_motor = A.v_motor(:);
v_random = A.v_random(:);
xBase = A.x(:);

N = length(s);

assert(all(isfinite([s;v_motor;v_random;xBase])), ...
 'Input contains NaN or Inf');

%% 2. FILTER PARAMETERS

M = 16;
mu = 0.01;

lambda = 0.99;
delta = 0.01;

levels = [0.25 0.50 1.00 1.50];

numLevels = length(levels);

steadyIdx = t >= 3;

%% 3. INITIALIZE RESULTS

rawRMSE = zeros(numLevels,1);
lmsRMSE = zeros(numLevels,1);
rlsRMSE = nan(numLevels,1);

rawSNR = zeros(numLevels,1);
lmsSNR = zeros(numLevels,1);
rlsSNR = nan(numLevels,1);

lmsRuntime = zeros(numLevels,1);
rlsRuntime = nan(numLevels,1);

rlsStable = false(numLevels,1);
rlsFailureSample = nan(numLevels,1);

rawRMSESteady = zeros(numLevels,1);
lmsRMSESteady = zeros(numLevels,1);
rlsRMSESteady = nan(numLevels,1);

rawSignals = zeros(N,numLevels);
lmsSignals = zeros(N,numLevels);
rlsSignals = nan(N,numLevels);
referenceSignals = zeros(N,numLevels);

signalPower = mean(s.^2);

assert(signalPower > 0, ...
 'Ideal signal has zero power');

%% 4. RUN EXPERIMENTS

fprintf('\n===== DAY 10 VIBRATION EXPERIMENT =====\n');

for k = 1:numLevels

    level = levels(k);

    fprintf('\n--- LEVEL %.2f ---\n',level);

    % Scale motor vibration and reference together
    motorNoise = level * v_motor;
    x = level * xBase;

    % Keep random noise unchanged
    d = s + motorNoise + v_random;

    rawSignals(:,k) = d;
    referenceSignals(:,k) = x;

    %% LMS

    wLMS = zeros(M,1);
    eLMS = zeros(N,1);
    xBuffer = zeros(M,1);

    tic;

    for n = 1:N

        xBuffer = [x(n);xBuffer(1:end-1)];

        y = wLMS.' * xBuffer;

        eLMS(n) = d(n) - y;

        wLMS = wLMS + ...
            mu * eLMS(n) * xBuffer;

    end

    lmsRuntime(k) = toc;

    assert(all(isfinite(eLMS)) && ...
           all(isfinite(wLMS)), ...
           'LMS numerical failure');

    lmsSignals(:,k) = eLMS;

    %% RLS

    wRLS = zeros(M,1);

    % Conventional initialization P(0) = I/delta
    P = eye(M)/delta;

    eRLS = nan(N,1);
    xBuffer = zeros(M,1);

    stable = true;
    failureSample = NaN;

    tic;

    for n = 1:N

        xBuffer = [x(n);xBuffer(1:end-1)];

        Px = P*xBuffer;

        denominator = lambda + xBuffer.'*Px;

        if ~isfinite(denominator) || ...
                denominator <= 0

            stable = false;
            failureSample = n;
            break;

        end

        gain = Px/denominator;

        y = wRLS.'*xBuffer;

        eCurrent = d(n)-y;

        wNew = wRLS + gain*eCurrent;

        PNew = (P-gain*Px.')/lambda;

        % Reduce floating-point asymmetry
        PNew = (PNew+PNew.')/2;

        if any(~isfinite(PNew(:))) || ...
           any(~isfinite(wNew)) || ...
           ~isfinite(eCurrent)

            stable = false;
            failureSample = n;
            break;

        end

        % Numerical safety checks
        if max(abs(PNew(:))) > 1e12 || ...
           max(abs(wNew)) > 1e6

            stable = false;
            failureSample = n;
            break;

        end

        P = PNew;
        wRLS = wNew;
        eRLS(n) = eCurrent;

    end

    rlsRuntime(k) = toc;
    rlsStable(k) = stable;
    rlsFailureSample(k) = failureSample;

    if stable
        rlsSignals(:,k) = eRLS;
    end

    %% RMSE

    rawError = d-s;
    lmsError = eLMS-s;

    rawRMSE(k) = sqrt(mean(rawError.^2));
    lmsRMSE(k) = sqrt(mean(lmsError.^2));

    rawRMSESteady(k) = ...
        sqrt(mean(rawError(steadyIdx).^2));

    lmsRMSESteady(k) = ...
        sqrt(mean(lmsError(steadyIdx).^2));

    if stable

        rlsError = eRLS-s;

        rlsRMSE(k) = sqrt(mean(rlsError.^2));

        rlsRMSESteady(k) = ...
          sqrt(mean(rlsError(steadyIdx).^2));

    end

    %% SNR (known ideal signal in simulation)

    rawSNR(k) = 10*log10( ...
        signalPower/mean(rawError.^2));

    lmsSNR(k) = 10*log10( ...
        signalPower/mean(lmsError.^2));

    if stable

        rlsSNR(k) = 10*log10( ...
            signalPower/mean(rlsError.^2));

    end

    %% PRINT RESULTS

    fprintf('Raw RMSE: %.6f\n',rawRMSE(k));
    fprintf('LMS RMSE: %.6f\n',lmsRMSE(k));

    if stable
        fprintf('RLS RMSE: %.6f\n',rlsRMSE(k));
        fprintf('RLS status: STABLE\n');
    else
        fprintf('RLS status: FAILED at n=%d\n', ...
            failureSample);
    end

end

%% 5. CALCULATE IMPROVEMENTS

lmsReduction = ...
    100*(rawRMSE-lmsRMSE)./rawRMSE;

rlsReduction = ...
    100*(rawRMSE-rlsRMSE)./rawRMSE;

lmsSNRGain = lmsSNR-rawSNR;
rlsSNRGain = rlsSNR-rawSNR;

%% 6. CREATE RESULTS TABLE

resultsTable = table( ...
    levels(:), ...
    rawRMSE, ...
    lmsRMSE, ...
    rlsRMSE, ...
    rawRMSESteady, ...
    lmsRMSESteady, ...
    rlsRMSESteady, ...
    lmsReduction, ...
    rlsReduction, ...
    rawSNR, ...
    lmsSNR, ...
    rlsSNR, ...
    lmsSNRGain, ...
    rlsSNRGain, ...
    lmsRuntime, ...
    rlsRuntime, ...
    rlsStable, ...
    rlsFailureSample, ...
    'VariableNames', { ...
    'Level', ...
    'Raw_RMSE', ...
    'LMS_RMSE', ...
    'RLS_RMSE', ...
    'Raw_RMSE_Steady', ...
    'LMS_RMSE_Steady', ...
    'RLS_RMSE_Steady', ...
    'LMS_Reduction_Pct', ...
    'RLS_Reduction_Pct', ...
    'Raw_SNR_dB', ...
    'LMS_SNR_dB', ...
    'RLS_SNR_dB', ...
    'LMS_SNR_Gain_dB', ...
    'RLS_SNR_Gain_dB', ...
    'LMS_Runtime_s', ...
    'RLS_Runtime_s', ...
    'RLS_Stable', ...
    'RLS_Failure_Sample'});

disp('===== DAY 10 RESULTS TABLE =====');
disp(resultsTable);

%% 7. PLOT RMSE COMPARISON

fig1 = figure('Color','w');

plot(levels,rawRMSE,'o-','LineWidth',1.5);
hold on;

plot(levels,lmsRMSE,'s-','LineWidth',1.5);

plot(levels,rlsRMSE,'^-','LineWidth',1.5);

grid on;

xlabel('Vibration amplitude scale');
ylabel('RMSE (m/s^2)');

title('Day 10 - RMSE vs Vibration Level');

legend('Raw','LMS','RLS', ...
    'Location','best');

saveas(fig1,fullfile(resultDir, ...
    'day10_rmse_levels.png'));

%% 8. PLOT SNR COMPARISON

fig2 = figure('Color','w');

plot(levels,rawSNR,'o-','LineWidth',1.5);
hold on;

plot(levels,lmsSNR,'s-','LineWidth',1.5);

plot(levels,rlsSNR,'^-','LineWidth',1.5);

grid on;

xlabel('Vibration amplitude scale');
ylabel('SNR (dB)');

title('Day 10 - SNR vs Vibration Level');

legend('Raw','LMS','RLS', ...
    'Location','best');

saveas(fig2,fullfile(resultDir, ...
    'day10_snr_levels.png'));

%% 9. PLOT TIME DOMAIN

fig3 = figure('Color','w');

for k = 1:numLevels

    subplot(numLevels,1,k);

    plot(t,rawSignals(:,k),'Color',[0.7 0.7 0.7]);
    hold on;

    plot(t,lmsSignals(:,k),'b');

    if rlsStable(k)
        plot(t,rlsSignals(:,k),'r');
    end

    plot(t,s,'k--');

    grid on;

    title(sprintf('Vibration Level %.2f',levels(k)));
    ylabel('m/s^2');

    if k == numLevels
        xlabel('Time (s)');
    end

end

saveas(fig3,fullfile(resultDir, ...
    'day10_time_levels.png'));

%% 10. SAVE RESULTS

csvFile = fullfile(resultDir, ...
    'day10_vibration_results.csv');

matFile = fullfile(resultDir, ...
    'day10_vibration_results.mat');

writetable(resultsTable,csvFile);

save(matFile, ...
    'Fs','t','s','levels', ...
    'M','mu','lambda','delta', ...
    'resultsTable', ...
    'rawSignals','lmsSignals', ...
    'rlsSignals','referenceSignals', ...
    'rlsStable','rlsFailureSample');

fprintf('\n===== DAY 10 COMPLETED =====\n');
fprintf('CSV saved: %s\n',csvFile);
fprintf('MAT saved: %s\n',matFile);
