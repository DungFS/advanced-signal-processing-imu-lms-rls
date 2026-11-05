
%% =========================================================
% DAY 10 - FFT AND PSD ANALYSIS
% Multiple vibration levels - LMS/RLS
% MATLAB R2023a
% Requires Signal Processing Toolbox for pwelch
%% =========================================================

clc;
clear;
close all;

%% STEP 1 - PROJECT PATHS

rootDir = ...
 fileparts(fileparts(fileparts(mfilename('fullpath'))));

resultDir = fullfile(rootDir,'results', 'simulation');

inputFile = fullfile(resultDir, ...
 'day10_vibration_results.mat');

assert(isfile(inputFile), ...
 'Missing day10_vibration_results.mat');

A = load(inputFile);

%% STEP 2 - LOAD DATA

Fs = A.Fs;
t = A.t(:);
s = A.s(:);

levels = A.levels(:);

rawSignals = A.rawSignals;
lmsSignals = A.lmsSignals;
rlsSignals = A.rlsSignals;

rlsStable = A.rlsStable(:);

N = numel(t);
K = numel(levels);

assert(Fs > 0 && isfinite(Fs), ...
 'Invalid sampling frequency');

assert(size(rawSignals,1) == N && ...
       size(lmsSignals,1) == N && ...
       size(rlsSignals,1) == N, ...
 'Signal length mismatch');

assert(size(rawSignals,2) == K && ...
       size(lmsSignals,2) == K && ...
       size(rlsSignals,2) == K, ...
 'Level count mismatch');

fprintf('===== DAY 10 FREQUENCY ANALYSIS =====\n');

fprintf('Fs: %.2f Hz\n',Fs);
fprintf('N: %d\n',N);
fprintf('Nyquist: %.2f Hz\n',Fs/2);

%% STEP 3 - ANALYSIS SETTINGS

targetFreq = 30;

assert(targetFreq < Fs/2, ...
 'Target frequency exceeds Nyquist');

steadyIdx = t >= 3;

% Welch PSD settings
windowLength = 256;
overlapLength = 128;
nfftWelch = 2048;

assert(sum(steadyIdx) >= windowLength, ...
 'Steady segment is too short');

welchWindow = hamming(windowLength);

%% STEP 4 - INITIALIZE RESULTS

fftRaw30 = zeros(K,1);
fftLMS30 = zeros(K,1);
fftRLS30 = nan(K,1);

fftLMSAtten = zeros(K,1);
fftRLSAtten = nan(K,1);

fftRaw30Steady = zeros(K,1);
fftLMS30Steady = zeros(K,1);
fftRLS30Steady = nan(K,1);

psdRaw30 = zeros(K,1);
psdLMS30 = zeros(K,1);
psdRLS30 = nan(K,1);

psdLMSAtten = zeros(K,1);
psdRLSAtten = nan(K,1);

%% STEP 5 - FREQUENCY AXES

fFFT = (0:floor(N/2))' * Fs/N;

Nsteady = sum(steadyIdx);

fSteady = (0:floor(Nsteady/2))' ...
    * Fs/Nsteady;

[~,idx30] = min(abs(fFFT-targetFreq));

[~,idx30Steady] = ...
    min(abs(fSteady-targetFreq));

fprintf('FFT bin: %.4f Hz\n',fFFT(idx30));

%% STEP 6 - FIGURES

figFFT = figure('Color','w', ...
 'Name','Day 10 FFT Comparison');

figPSD = figure('Color','w', ...
 'Name','Day 10 PSD Comparison');

%% STEP 7 - LOOP THROUGH VIBRATION LEVELS

for k = 1:K

    level = levels(k);

    raw = rawSignals(:,k);
    lms = lmsSignals(:,k);
    rls = rlsSignals(:,k);

    fprintf('\n--- LEVEL %.2f ---\n',level);

    %% 7.1 FFT FULL SIGNAL

    % Remove DC component
    raw0 = raw-mean(raw);
    lms0 = lms-mean(lms);

    Yraw = fft(raw0);
    Ylms = fft(lms0);

    Araw = abs(Yraw(1:floor(N/2)+1))/N;
    Alms = abs(Ylms(1:floor(N/2)+1))/N;

    % One-sided amplitude scaling
    if rem(N,2)==0
        Araw(2:end-1) = 2*Araw(2:end-1);
        Alms(2:end-1) = 2*Alms(2:end-1);
    else
        Araw(2:end) = 2*Araw(2:end);
        Alms(2:end) = 2*Alms(2:end);
    end

    fftRaw30(k) = Araw(idx30);
    fftLMS30(k) = Alms(idx30);

    fftLMSAtten(k) = 20*log10( ...
        max(fftRaw30(k),realmin) / ...
        max(fftLMS30(k),realmin));

    if rlsStable(k)

        rls0 = rls-mean(rls);

        Yrls = fft(rls0);

        Arls = abs(Yrls(1:floor(N/2)+1))/N;

        if rem(N,2)==0
            Arls(2:end-1) = 2*Arls(2:end-1);
        else
            Arls(2:end) = 2*Arls(2:end);
        end

        fftRLS30(k) = Arls(idx30);

        fftRLSAtten(k) = 20*log10( ...
            max(fftRaw30(k),realmin) / ...
            max(fftRLS30(k),realmin));

    else
        Arls = nan(size(Araw));
    end

    %% 7.2 FFT STEADY STATE

    rawS = raw(steadyIdx);
    lmsS = lms(steadyIdx);

    rawS = rawS-mean(rawS);
    lmsS = lmsS-mean(lmsS);

    YrS = fft(rawS);
    YlS = fft(lmsS);

    AsRaw = abs(YrS(1:floor(Nsteady/2)+1)) ...
        /Nsteady;

    AsLMS = abs(YlS(1:floor(Nsteady/2)+1)) ...
        /Nsteady;

    if rem(Nsteady,2)==0
        AsRaw(2:end-1) = 2*AsRaw(2:end-1);
        AsLMS(2:end-1) = 2*AsLMS(2:end-1);
    else
        AsRaw(2:end) = 2*AsRaw(2:end);
        AsLMS(2:end) = 2*AsLMS(2:end);
    end

    fftRaw30Steady(k) = AsRaw(idx30Steady);
    fftLMS30Steady(k) = AsLMS(idx30Steady);

    if rlsStable(k)

        rlsS = rls(steadyIdx);
        rlsS = rlsS-mean(rlsS);

        YsRLS = fft(rlsS);

        AsRLS = abs(YsRLS( ...
            1:floor(Nsteady/2)+1))/Nsteady;

        if rem(Nsteady,2)==0
            AsRLS(2:end-1) = 2*AsRLS(2:end-1);
        else
            AsRLS(2:end) = 2*AsRLS(2:end);
        end

        fftRLS30Steady(k) = ...
            AsRLS(idx30Steady);

    end

    %% 7.3 WELCH PSD - STEADY STATE

    [pRaw,fPSD] = pwelch(raw(steadyIdx), ...
        welchWindow,overlapLength, ...
        nfftWelch,Fs);

    [pLMS,~] = pwelch(lms(steadyIdx), ...
        welchWindow,overlapLength, ...
        nfftWelch,Fs);

    [~,idxPSD30] = min(abs(fPSD-targetFreq));

    psdRaw30(k) = pRaw(idxPSD30);
    psdLMS30(k) = pLMS(idxPSD30);

    psdLMSAtten(k) = 10*log10( ...
        max(psdRaw30(k),realmin) / ...
        max(psdLMS30(k),realmin));

    if rlsStable(k)

        [pRLS,~] = pwelch(rls(steadyIdx), ...
            welchWindow,overlapLength, ...
            nfftWelch,Fs);

        psdRLS30(k) = pRLS(idxPSD30);

        psdRLSAtten(k) = 10*log10( ...
            max(psdRaw30(k),realmin) / ...
            max(psdRLS30(k),realmin));

    else
        pRLS = nan(size(pRaw));
    end

    %% 7.4 PLOT FFT

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

    title(sprintf('FFT - Vibration Level %.2f', ...
        level));

    ylabel('Amplitude');

    if k==K
        xlabel('Frequency (Hz)');
    end

    %% 7.5 PLOT PSD

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

    title(sprintf('PSD - Vibration Level %.2f', ...
        level));

    ylabel('PSD (dB/Hz)');

    if k==K
        xlabel('Frequency (Hz)');
    end

    %% 7.6 PRINT RESULTS

    fprintf('Raw FFT 30 Hz: %.6f\n',fftRaw30(k));
    fprintf('LMS FFT 30 Hz: %.6f\n',fftLMS30(k));

    if rlsStable(k)
        fprintf('RLS FFT 30 Hz: %.6f\n',fftRLS30(k));
    end

    fprintf('LMS FFT attenuation: %.3f dB\n', ...
        fftLMSAtten(k));

    if rlsStable(k)
        fprintf('RLS FFT attenuation: %.3f dB\n', ...
            fftRLSAtten(k));
    end

end

%% STEP 8 - SUMMARY TABLE

frequencyTable = table( ...
    levels, ...
    fftRaw30,fftLMS30,fftRLS30, ...
    fftLMSAtten,fftRLSAtten, ...
    fftRaw30Steady, ...
    fftLMS30Steady, ...
    fftRLS30Steady, ...
    psdRaw30,psdLMS30,psdRLS30, ...
    psdLMSAtten,psdRLSAtten, ...
    rlsStable, ...
    'VariableNames',{ ...
    'Level', ...
    'FFT_Raw_30Hz', ...
    'FFT_LMS_30Hz', ...
    'FFT_RLS_30Hz', ...
    'FFT_LMS_Attenuation_dB', ...
    'FFT_RLS_Attenuation_dB', ...
    'FFT_Raw_Steady_30Hz', ...
    'FFT_LMS_Steady_30Hz', ...
    'FFT_RLS_Steady_30Hz', ...
    'PSD_Raw_30Hz', ...
    'PSD_LMS_30Hz', ...
    'PSD_RLS_30Hz', ...
    'PSD_LMS_Attenuation_dB', ...
    'PSD_RLS_Attenuation_dB', ...
    'RLS_Stable'});

fprintf('\n===== DAY 10 FREQUENCY TABLE =====\n');

disp(frequencyTable);

%% STEP 9 - SAVE FILES

csvFile = fullfile(resultDir, ...
 'day10_frequency_levels.csv');

matFile = fullfile(resultDir, ...
 'day10_frequency_levels.mat');

writetable(frequencyTable,csvFile);

save(matFile, ...
    'frequencyTable','Fs','levels', ...
    'targetFreq','fFFT','fSteady', ...
    'fftRaw30','fftLMS30','fftRLS30', ...
    'fftLMSAtten','fftRLSAtten', ...
    'psdRaw30','psdLMS30','psdRLS30', ...
    'psdLMSAtten','psdRLSAtten');

saveas(figFFT,fullfile(resultDir, ...
 'day10_fft_levels.png'));

saveas(figPSD,fullfile(resultDir, ...
 'day10_psd_levels.png'));

fprintf('\n===== DAY 10 FREQUENCY ANALYSIS COMPLETED =====\n');

fprintf('CSV: %s\n',csvFile);
fprintf('MAT: %s\n',matFile);
