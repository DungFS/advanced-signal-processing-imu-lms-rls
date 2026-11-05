
%% =========================================================
% DAY 10 - RESIDUAL NOISE VALIDATION
% LMS/RLS - Four vibration levels
% MATLAB R2023a
% Signal Processing Toolbox: pwelch
%% =========================================================

clc;
clear;
close all;

%% 1. PATHS

rootDir = ...
 fileparts(fileparts(fileparts(mfilename('fullpath'))));

resultDir = fullfile(rootDir,'results', 'simulation');

inputFile = fullfile(resultDir, ...
 'day10_vibration_results.mat');

assert(isfile(inputFile), ...
 'Missing day10_vibration_results.mat');

A = load(inputFile);

%% 2. LOAD DATA

Fs = A.Fs;
t = A.t(:);
s = A.s(:);
levels = A.levels(:);

rawSignals = A.rawSignals;
lmsSignals = A.lmsSignals;
rlsSignals = A.rlsSignals;

rlsStable = A.rlsStable(:);

N = numel(s);
K = numel(levels);

assert(Fs > 0 && isfinite(Fs), ...
 'Invalid sampling frequency');

assert(numel(t)==N && ...
    size(rawSignals,1)==N && ...
    size(lmsSignals,1)==N && ...
    size(rlsSignals,1)==N, ...
 'Signal length mismatch');

assert(size(rawSignals,2)==K && ...
    size(lmsSignals,2)==K && ...
    size(rlsSignals,2)==K, ...
 'Level count mismatch');

%% 3. SETTINGS

targetFreq = 30;

steadyIdx = t >= 3;

Ns = sum(steadyIdx);

fFFT = (0:floor(Ns/2))'*Fs/Ns;

[~,idx30] = min(abs(fFFT-targetFreq));

fprintf('===== DAY 10 RESIDUAL VALIDATION =====\n');
fprintf('Fs: %.2f Hz\n',Fs);
fprintf('Steady samples: %d\n',Ns);
fprintf('FFT bin: %.4f Hz\n',fFFT(idx30));

%% 4. WELCH SETTINGS

windowLength = 256;
overlapLength = 128;
nfftWelch = 2048;

assert(Ns >= windowLength, ...
 'Not enough steady samples');

welchWindow = hamming(windowLength);

%% 5. RESULT ARRAYS

rawResidualRMSE = zeros(K,1);
lmsResidualRMSE = zeros(K,1);
rlsResidualRMSE = nan(K,1);

rawResidualFFT30 = zeros(K,1);
lmsResidualFFT30 = zeros(K,1);
rlsResidualFFT30 = nan(K,1);

rawResidualPSD30 = zeros(K,1);
lmsResidualPSD30 = zeros(K,1);
rlsResidualPSD30 = nan(K,1);

lmsFFTAtten = zeros(K,1);
rlsFFTAtten = nan(K,1);

lmsPSDAtten = zeros(K,1);
rlsPSDAtten = nan(K,1);

%% 6. PLOT FIGURES

figFFT = figure('Color','w', ...
 'Name','Residual FFT');

figPSD = figure('Color','w', ...
 'Name','Residual PSD');

%% 7. PROCESS EACH LEVEL

for k = 1:K

    fprintf('\n--- LEVEL %.2f ---\n',levels(k));

    raw = rawSignals(:,k);
    lms = lmsSignals(:,k);

    % Residual errors in steady state
    rRaw = raw(steadyIdx)-s(steadyIdx);
    rLMS = lms(steadyIdx)-s(steadyIdx);

    if rlsStable(k)
        rls = rlsSignals(:,k);
        rRLS = rls(steadyIdx)-s(steadyIdx);
    else
        rRLS = nan(Ns,1);
    end

    %% 7.1 RMSE

    rawResidualRMSE(k) = sqrt(mean(rRaw.^2));
    lmsResidualRMSE(k) = sqrt(mean(rLMS.^2));

    if rlsStable(k)
        rlsResidualRMSE(k) = ...
            sqrt(mean(rRLS.^2));
    end

    %% 7.2 FFT

    rRaw0 = rRaw-mean(rRaw);
    rLMS0 = rLMS-mean(rLMS);

    Yraw = fft(rRaw0);
    Ylms = fft(rLMS0);

    Araw = abs(Yraw(1:floor(Ns/2)+1))/Ns;
    Alms = abs(Ylms(1:floor(Ns/2)+1))/Ns;

    if rem(Ns,2)==0
        Araw(2:end-1) = 2*Araw(2:end-1);
        Alms(2:end-1) = 2*Alms(2:end-1);
    else
        Araw(2:end) = 2*Araw(2:end);
        Alms(2:end) = 2*Alms(2:end);
    end

    rawResidualFFT30(k) = Araw(idx30);
    lmsResidualFFT30(k) = Alms(idx30);

    lmsFFTAtten(k) = 20*log10( ...
        max(rawResidualFFT30(k),realmin)/ ...
        max(lmsResidualFFT30(k),realmin));

    if rlsStable(k)

        rRLS0 = rRLS-mean(rRLS);

        Yrls = fft(rRLS0);

        Arls = abs(Yrls(1:floor(Ns/2)+1))/Ns;

        if rem(Ns,2)==0
            Arls(2:end-1) = 2*Arls(2:end-1);
        else
            Arls(2:end) = 2*Arls(2:end);
        end

        rlsResidualFFT30(k) = Arls(idx30);

        rlsFFTAtten(k) = 20*log10( ...
            max(rawResidualFFT30(k),realmin)/ ...
            max(rlsResidualFFT30(k),realmin));

    else
        Arls = nan(size(Araw));
    end

    %% 7.3 PSD OF RESIDUALS

    [pRaw,fPSD] = pwelch(rRaw, ...
        welchWindow,overlapLength, ...
        nfftWelch,Fs);

    [pLMS,~] = pwelch(rLMS, ...
        welchWindow,overlapLength, ...
        nfftWelch,Fs);

    [~,idxPSD30] = min(abs(fPSD-targetFreq));

    rawResidualPSD30(k) = pRaw(idxPSD30);
    lmsResidualPSD30(k) = pLMS(idxPSD30);

    lmsPSDAtten(k) = 10*log10( ...
        max(rawResidualPSD30(k),realmin)/ ...
        max(lmsResidualPSD30(k),realmin));

    if rlsStable(k)

        [pRLS,~] = pwelch(rRLS, ...
            welchWindow,overlapLength, ...
            nfftWelch,Fs);

        rlsResidualPSD30(k) = pRLS(idxPSD30);

        rlsPSDAtten(k) = 10*log10( ...
            max(rawResidualPSD30(k),realmin)/ ...
            max(rlsResidualPSD30(k),realmin));

    else
        pRLS = nan(size(pRaw));
    end

    %% 7.4 FFT FIGURE

    figure(figFFT);
    subplot(K,1,k);

    plot(fFFT,Araw,'Color',[0.5 0.5 0.5]);
    hold on;

    plot(fFFT,Alms,'b');

    if rlsStable(k)
        plot(fFFT,Arls,'r');
    end

    xlim([0 60]);
    grid on;

    title(sprintf( ...
        'Residual FFT - Level %.2f',levels(k)));

    ylabel('m/s^2');

    if k==K
        xlabel('Frequency (Hz)');
    end

    %% 7.5 PSD FIGURE

    figure(figPSD);
    subplot(K,1,k);

    plot(fPSD,10*log10(max(pRaw,realmin)), ...
        'Color',[0.5 0.5 0.5]);
    hold on;

    plot(fPSD,10*log10(max(pLMS,realmin)),'b');

    if rlsStable(k)
        plot(fPSD,10*log10(max(pRLS,realmin)),'r');
    end

    xlim([0 60]);
    grid on;

    title(sprintf( ...
        'Residual PSD - Level %.2f',levels(k)));

    ylabel('dB/Hz');

    if k==K
        xlabel('Frequency (Hz)');
    end

    %% 7.6 PRINT

    fprintf('Raw steady RMSE: %.6f\n', ...
        rawResidualRMSE(k));

    fprintf('LMS steady RMSE: %.6f\n', ...
        lmsResidualRMSE(k));

    fprintf('LMS residual FFT attenuation: %.3f dB\n', ...
        lmsFFTAtten(k));

    fprintf('LMS residual PSD attenuation: %.3f dB\n', ...
        lmsPSDAtten(k));

    if rlsStable(k)

        fprintf('RLS steady RMSE: %.6f\n', ...
            rlsResidualRMSE(k));

        fprintf('RLS residual FFT attenuation: %.3f dB\n', ...
            rlsFFTAtten(k));

        fprintf('RLS residual PSD attenuation: %.3f dB\n', ...
            rlsPSDAtten(k));

    else
        fprintf('RLS: INVALID / UNSTABLE\n');
    end

end

%% 8. SUMMARY TABLE

validationTable = table( ...
    levels, ...
    rawResidualRMSE, ...
    lmsResidualRMSE, ...
    rlsResidualRMSE, ...
    rawResidualFFT30, ...
    lmsResidualFFT30, ...
    rlsResidualFFT30, ...
    lmsFFTAtten, ...
    rlsFFTAtten, ...
    rawResidualPSD30, ...
    lmsResidualPSD30, ...
    rlsResidualPSD30, ...
    lmsPSDAtten, ...
    rlsPSDAtten, ...
    rlsStable, ...
    'VariableNames',{ ...
    'Level', ...
    'Raw_RMSE_Steady', ...
    'LMS_RMSE_Steady', ...
    'RLS_RMSE_Steady', ...
    'Raw_Residual_FFT30', ...
    'LMS_Residual_FFT30', ...
    'RLS_Residual_FFT30', ...
    'LMS_FFT_Attenuation_dB', ...
    'RLS_FFT_Attenuation_dB', ...
    'Raw_Residual_PSD30', ...
    'LMS_Residual_PSD30', ...
    'RLS_Residual_PSD30', ...
    'LMS_PSD_Attenuation_dB', ...
    'RLS_PSD_Attenuation_dB', ...
    'RLS_Stable'});

fprintf('\n===== RESIDUAL VALIDATION TABLE =====\n');

disp(validationTable);

%% 9. SAVE RESULTS

csvFile = fullfile(resultDir, ...
 'day10_residual_validation.csv');

matFile = fullfile(resultDir, ...
 'day10_residual_validation.mat');

writetable(validationTable,csvFile);

save(matFile, ...
    'validationTable','Fs','levels', ...
    'targetFreq','fFFT','fPSD');

saveas(figFFT,fullfile(resultDir, ...
 'day10_residual_fft.png'));

saveas(figPSD,fullfile(resultDir, ...
 'day10_residual_psd.png'));

fprintf('\n===== DAY 10 RESIDUAL VALIDATION COMPLETED =====\n');
fprintf('CSV: %s\n',csvFile);
fprintf('MAT: %s\n',matFile);
