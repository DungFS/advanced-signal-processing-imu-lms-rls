
%% DAY 06 - COMPARISON OF LMS AND RLS
% Advanced Digital Signal Processing
% MATLAB R2023a

clear;
clc;
close all;

%% 1. PROJECT PATH

projectPath = ...
    'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';

resultPath = fullfile(projectPath,'06_RESULTS');

lmsFile = fullfile(resultPath,'day04_lms_results.mat');
rlsFile = fullfile(resultPath,'day05_rls_results.mat');

assert(isfile(lmsFile),'LMS result file not found');
assert(isfile(rlsFile),'RLS result file not found');

%% 2. LOAD RESULTS

L = load(lmsFile);
R = load(rlsFile);

disp('===== AVAILABLE LMS VARIABLES =====');
disp(fieldnames(L));

disp('===== AVAILABLE RLS VARIABLES =====');
disp(fieldnames(R));

% Required signals
required = {'t','s','d','e','Fs'};

for k = 1:numel(required)
    assert(isfield(L,required{k}), ...
        ['Missing LMS variable: ' required{k}]);
    assert(isfield(R,required{k}), ...
        ['Missing RLS variable: ' required{k}]);
end

t = L.t(:);
s = L.s(:);
d = L.d(:);
lms = L.e(:);
rls = R.e(:);

Fs = L.Fs;
N = numel(t);

%% 3. VERIFY DATA CONSISTENCY

assert(N == numel(s) && N == numel(d), ...
    'LMS signal length mismatch');

assert(N == numel(lms) && N == numel(rls), ...
    'Filtered signal length mismatch');

assert(numel(R.t) == N, ...
    'RLS time length mismatch');

assert(abs(L.Fs-R.Fs) < 1e-10, ...
    'Sampling frequencies are different');

assert(max(abs(t-R.t(:))) < 1e-10, ...
    'Time vectors are different');

assert(max(abs(s-R.s(:))) < 1e-10, ...
    'Ideal signals are different');

assert(max(abs(d-R.d(:))) < 1e-10, ...
    'Raw signals are different');

assert(all(isfinite([t;s;d;lms;rls])), ...
    'Signal contains NaN or Inf');

fprintf('\n===== DATA CHECK =====\n');
fprintf('Fs: %.2f Hz\n',Fs);
fprintf('N: %d samples\n',N);
fprintf('Data consistency: PASSED\n');

%% 4. TIME DOMAIN COMPARISON

fig1 = figure('Name','Day 06 Time Comparison');

subplot(2,1,1);

plot(t,s,'k','LineWidth',1.5);
hold on;
plot(t,d,'Color',[0.75 0.75 0.75]);
plot(t,lms,'b','LineWidth',1);
plot(t,rls,'r','LineWidth',1);

grid on;
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
title('Raw vs LMS vs RLS');
legend('Ideal','Raw','LMS','RLS');

subplot(2,1,2);

idxZoom = t >= 3 & t <= 4;

plot(t(idxZoom),s(idxZoom),'k','LineWidth',1.5);
hold on;
plot(t(idxZoom),d(idxZoom),'Color',[0.7 0.7 0.7]);
plot(t(idxZoom),lms(idxZoom),'b');
plot(t(idxZoom),rls(idxZoom),'r');

grid on;
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
title('Zoom: 3 to 4 seconds');
legend('Ideal','Raw','LMS','RLS');

saveas(fig1,fullfile(resultPath, ...
    'day06_time_comparison.png'));

%% 5. RMSE COMPARISON

rmse = @(y) sqrt(mean((y-s).^2));

rmseRaw = rmse(d);
rmseLMS = rmse(lms);
rmseRLS = rmse(rls);

improveLMS = 100*(1-rmseLMS/rmseRaw);
improveRLS = 100*(1-rmseRLS/rmseRaw);

idxSteady = t >= 3;

rmseRawSteady = sqrt(mean( ...
    (d(idxSteady)-s(idxSteady)).^2));

rmseLMSSteady = sqrt(mean( ...
    (lms(idxSteady)-s(idxSteady)).^2));

rmseRLSSteady = sqrt(mean( ...
    (rls(idxSteady)-s(idxSteady)).^2));

fprintf('\n===== RMSE COMPARISON =====\n');
fprintf('Raw RMSE: %.6f\n',rmseRaw);
fprintf('LMS RMSE: %.6f\n',rmseLMS);
fprintf('RLS RMSE: %.6f\n',rmseRLS);

fprintf('LMS improvement: %.2f %%\n',improveLMS);
fprintf('RLS improvement: %.2f %%\n',improveRLS);

fprintf('\n===== STEADY STATE RMSE =====\n');
fprintf('Raw: %.6f\n',rmseRawSteady);
fprintf('LMS: %.6f\n',rmseLMSSteady);
fprintf('RLS: %.6f\n',rmseRLSSteady);

%% 6. RMSE BAR CHART

fig2 = figure('Name','RMSE Comparison');

bar([rmseRaw rmseLMS rmseRLS]);

set(gca,'XTickLabel',{'Raw','LMS','RLS'});

ylabel('RMSE (m/s^2)');
title('RMSE Comparison');
grid on;

saveas(fig2,fullfile(resultPath, ...
    'day06_rmse_comparison.png'));

%% 7. PSD OF ESTIMATION ERRORS

% In this simulation, ideal signal s is known.
% Therefore, y-s represents estimation error.

errRaw = d-s;
errLMS = lms-s;
errRLS = rls-s;

windowLength = 256;
overlapLength = 128;
nfft = 1024;

[pRaw,f] = pwelch(errRaw, ...
    hamming(windowLength),overlapLength,nfft,Fs);

[pLMS,~] = pwelch(errLMS, ...
    hamming(windowLength),overlapLength,nfft,Fs);

[pRLS,~] = pwelch(errRLS, ...
    hamming(windowLength),overlapLength,nfft,Fs);

fig3 = figure('Name','Error PSD Comparison');

plot(f,10*log10(max(pRaw,realmin)),'k');
hold on;

plot(f,10*log10(max(pLMS,realmin)),'b');
plot(f,10*log10(max(pRLS,realmin)),'r');

grid on;
xlabel('Frequency (Hz)');
ylabel('PSD (dB/Hz)');
title('PSD of Estimation Errors');
legend('Raw Error','LMS Error','RLS Error');

xlim([0 100]);

saveas(fig3,fullfile(resultPath, ...
    'day06_psd_comparison.png'));

%% 8. PSD COMPARISON NEAR 30 HZ

[~,idx30] = min(abs(f-30));

psdRaw30 = 10*log10(max(pRaw(idx30),realmin));
psdLMS30 = 10*log10(max(pLMS(idx30),realmin));
psdRLS30 = 10*log10(max(pRLS(idx30),realmin));

fprintf('\n===== PSD NEAR 30 HZ =====\n');

fprintf('Frequency bin: %.4f Hz\n',f(idx30));
fprintf('Raw: %.4f dB/Hz\n',psdRaw30);
fprintf('LMS: %.4f dB/Hz\n',psdLMS30);
fprintf('RLS: %.4f dB/Hz\n',psdRLS30);

fprintf('LMS reduction: %.4f dB\n', ...
    psdRaw30-psdLMS30);

fprintf('RLS reduction: %.4f dB\n', ...
    psdRaw30-psdRLS30);

%% 9. SAVE RESULTS

comparisonTable = table( ...
    ["Raw";"LMS";"RLS"], ...
    [rmseRaw;rmseLMS;rmseRLS], ...
    [rmseRawSteady;rmseLMSSteady;rmseRLSSteady], ...
    [0;improveLMS;improveRLS], ...
    'VariableNames', ...
    {'Method','RMSE','SteadyRMSE','ImprovementPercent'});

disp('===== COMPARISON TABLE =====');
disp(comparisonTable);

writetable(comparisonTable, ...
    fullfile(resultPath,'day06_comparison.csv'));

save(fullfile(resultPath, ...
    'day06_comparison_results.mat'), ...
    't','s','d','lms','rls','Fs', ...
    'comparisonTable','f','pRaw','pLMS','pRLS', ...
    'psdRaw30','psdLMS30','psdRLS30');

disp('===== DAY 06 COMPLETED =====');
disp('All comparison results saved.');
