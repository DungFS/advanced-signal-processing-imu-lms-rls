
%% DAY 07 - FFT AND PSD COMPARISON
% Advanced Digital Signal Processing
% Compare Raw, LMS and RLS in frequency domain

clear;
clc;
close all;

%% 1. PROJECT PATHS

baseDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
resultDir = fullfile(baseDir, 'results', 'simulation');

inputFile = fullfile(resultDir, ...
    'day06_comparison_results.mat');

if ~isfile(inputFile)
    error('Day 06 result file not found.');
end

%% 2. LOAD DATA

D = load(inputFile);

disp('===== AVAILABLE DAY 06 VARIABLES =====');
disp(fieldnames(D));

% Required signals
required = {'Fs','t','s','d'};

for k = 1:numel(required)
    if ~isfield(D, required{k})
        error('Missing variable: %s', required{k});
    end
end

Fs = D.Fs;
t = D.t(:);
s = D.s(:);
d = D.d(:);

% Day 06 may store filtered signals under
% different variable names.
if isfield(D, 'eLMS')
    lms = D.eLMS(:);
elseif isfield(D, 'lms')
    lms = D.lms(:);
elseif isfield(D, 'e_lms')
    lms = D.e_lms(:);
else
    error(['LMS output not found. ', ...
        'Check Day 06 variable names.']);
end

if isfield(D, 'eRLS')
    rls = D.eRLS(:);
elseif isfield(D, 'rls')
    rls = D.rls(:);
elseif isfield(D, 'e_rls')
    rls = D.e_rls(:);
else
    error(['RLS output not found. ', ...
        'Check Day 06 variable names.']);
end

N = numel(d);

assert(numel(s)==N && numel(lms)==N && ...
    numel(rls)==N && numel(t)==N, ...
    'Signal lengths do not match.');

assert(Fs > 0, 'Invalid sampling frequency.');

assert(all(isfinite([s;d;lms;rls])), ...
    'Signals contain NaN or Inf.');

fprintf('\n===== DAY 07 DATA =====\n');
fprintf('Fs: %.2f Hz\n', Fs);
fprintf('Samples: %d\n', N);
fprintf('Nyquist: %.2f Hz\n', Fs/2);

%% 3. CHECK SAMPLING

dt = diff(t);
expectedDt = 1/Fs;

maxDtError = max(abs(dt - expectedDt));

fprintf('Max sampling interval error: %.3e s\n', ...
    maxDtError);

if maxDtError > 1e-6
    warning('Sampling time is not uniform.');
end

%% 4. FFT ANALYSIS

% Remove DC offset before spectral comparison
signals = [d, lms, rls, s];
signalsAC = signals - mean(signals, 1);

% One-sided amplitude spectrum
nfft = N;
freq = (0:floor(N/2))' * Fs/N;

fftData = fft(signalsAC, nfft, 1);
amplitude = abs(fftData(1:numel(freq),:))/N;

if rem(N,2)==0
    amplitude(2:end-1,:) = ...
        2*amplitude(2:end-1,:);
else
    amplitude(2:end,:) = ...
        2*amplitude(2:end,:);
end

figure('Name','Day 07 FFT','Color','w');

plot(freq, amplitude(:,1), 'k', 'LineWidth',1.2);
hold on;
plot(freq, amplitude(:,2), 'b', 'LineWidth',1.2);
plot(freq, amplitude(:,3), 'r', 'LineWidth',1.2);
plot(freq, amplitude(:,4), 'g--', 'LineWidth',1.2);

grid on;
xlabel('Frequency (Hz)');
ylabel('Amplitude (m/s^2)');
title('FFT Comparison: Raw vs LMS vs RLS vs Ideal');
legend('Raw','LMS','RLS','Ideal');
xlim([0 Fs/2]);

saveas(gcf, fullfile(resultDir, ...
    'day07_fft_comparison.png'));

%% 5. PSD ANALYSIS USING WELCH

windowLength = min(256,N);
overlap = floor(windowLength/2);
nfftPSD = max(1024,windowLength);

[Pxx, fPSD] = pwelch(signalsAC, ...
    hamming(windowLength), overlap, ...
    nfftPSD, Fs);

figure('Name','Day 07 PSD','Color','w');

plot(fPSD,10*log10(max(Pxx(:,1),realmin)), ...
    'k','LineWidth',1.2);
hold on;

plot(fPSD,10*log10(max(Pxx(:,2),realmin)), ...
    'b','LineWidth',1.2);

plot(fPSD,10*log10(max(Pxx(:,3),realmin)), ...
    'r','LineWidth',1.2);

plot(fPSD,10*log10(max(Pxx(:,4),realmin)), ...
    'g--','LineWidth',1.2);

grid on;
xlabel('Frequency (Hz)');
ylabel('PSD (dB re (m/s^2)^2/Hz)');
title('Welch PSD Comparison');
legend('Raw','LMS','RLS','Ideal');
xlim([0 Fs/2]);

saveas(gcf, fullfile(resultDir, ...
    'day07_psd_comparison.png'));

%% 6. ANALYZE VIBRATION AT 30 HZ

targetFreq = 30;

% Find nearest FFT frequency bin
[~, idxFFT] = min(abs(freq-targetFreq));

rawAmp = amplitude(idxFFT,1);
lmsAmp = amplitude(idxFFT,2);
rlsAmp = amplitude(idxFFT,3);

% Amplitude attenuation in dB
attenLMS = 20*log10(max(rawAmp,realmin) / ...
    max(lmsAmp,realmin));

attenRLS = 20*log10(max(rawAmp,realmin) / ...
    max(rlsAmp,realmin));

fprintf('\n===== FFT AT 30 HZ =====\n');
fprintf('Actual FFT bin: %.4f Hz\n',freq(idxFFT));
fprintf('Raw amplitude: %.6f\n',rawAmp);
fprintf('LMS amplitude: %.6f\n',lmsAmp);
fprintf('RLS amplitude: %.6f\n',rlsAmp);
fprintf('LMS attenuation: %.3f dB\n',attenLMS);
fprintf('RLS attenuation: %.3f dB\n',attenRLS);

%% 7. PSD AT 30 HZ

[~, idxPSD] = min(abs(fPSD-targetFreq));

psdRaw = Pxx(idxPSD,1);
psdLMS = Pxx(idxPSD,2);
psdRLS = Pxx(idxPSD,3);

psdReductionLMS = 10*log10( ...
    max(psdRaw,realmin)/max(psdLMS,realmin));

psdReductionRLS = 10*log10( ...
    max(psdRaw,realmin)/max(psdRLS,realmin));

fprintf('\n===== PSD AT 30 HZ =====\n');
fprintf('Actual PSD bin: %.4f Hz\n',fPSD(idxPSD));
fprintf('Raw PSD: %.6e\n',psdRaw);
fprintf('LMS PSD: %.6e\n',psdLMS);
fprintf('RLS PSD: %.6e\n',psdRLS);
fprintf('LMS PSD reduction: %.3f dB\n', ...
    psdReductionLMS);
fprintf('RLS PSD reduction: %.3f dB\n', ...
    psdReductionRLS);

%% 8. SAVE RESULTS

algorithm = {'LMS';'RLS'};

fftAttenuation_dB = [attenLMS;attenRLS];
psdReduction_dB = ...
    [psdReductionLMS;psdReductionRLS];

resultTable = table(algorithm, ...
    fftAttenuation_dB, psdReduction_dB);

disp('===== DAY 07 COMPARISON =====');
disp(resultTable);

writetable(resultTable, fullfile(resultDir, ...
    'day07_frequency_comparison.csv'));

save(fullfile(resultDir, ...
    'day07_frequency_results.mat'), ...
    'Fs','N','freq','amplitude','fPSD','Pxx', ...
    'targetFreq','resultTable', ...
    'attenLMS','attenRLS', ...
    'psdReductionLMS','psdReductionRLS', ...
    'maxDtError');

fprintf('\n===== DAY 07 COMPLETED =====\n');
fprintf('Results saved successfully.\n');
