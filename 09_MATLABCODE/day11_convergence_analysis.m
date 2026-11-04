
%% DAY 11 - LMS/RLS CONVERGENCE AND STABILITY
clear; clc; close all;

%% 1. PROJECT PATH
root = 'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';
resultDir = fullfile(root, '06_RESULTS');

lmsFile = fullfile(resultDir, 'day04_lms_results.mat');
rlsFile = fullfile(resultDir, 'day05_rls_results.mat');

assert(isfile(lmsFile), 'Missing Day 04 LMS file');
assert(isfile(rlsFile), 'Missing Day 05 RLS file');

L = load(lmsFile);
R = load(rlsFile);

%% 2. VALIDATE INPUTS
required = {'Fs','t','s','d','e'};

for k = 1:numel(required)
    assert(isfield(L,required{k}), ...
        'LMS missing variable: %s', required{k});
    assert(isfield(R,required{k}), ...
        'RLS missing variable: %s', required{k});
end

Fs = L.Fs;
t = L.t(:);
s = L.s(:);
d = L.d(:);
eLMS = L.e(:);
eRLS = R.e(:);
N = numel(t);

assert(abs(Fs-R.Fs)<1e-9, 'Fs mismatch');
assert(all([numel(s),numel(d),numel(eLMS), ...
    numel(eRLS),numel(R.t)]==N), ...
    'Signal length mismatch');

assert(max(abs(t-R.t(:)))<1e-9, ...
    'Time vectors mismatch');

assert(max(abs(s-R.s(:)))<1e-9, ...
    'Ideal signals mismatch');

assert(max(abs(d-R.d(:)))<1e-9, ...
    'Raw signals mismatch');

assert(all(isfinite([s;d;eLMS;eRLS])), ...
    'NaN or Inf detected');

dtError = max(abs(diff(t)-1/Fs));
assert(dtError<1e-6, 'Sampling interval error');

fprintf('===== DAY 11 DATA CHECK =====\n');
fprintf('Fs: %.2f Hz\n', Fs);
fprintf('Samples: %d\n', N);
fprintf('Duration: %.2f s\n', N/Fs);
fprintf('Max dt error: %.3e s\n', dtError);

%% 3. CALCULATE RESIDUAL ERROR
errRaw = d-s;
errLMS = eLMS-s;
errRLS = eRLS-s;

%% 4. SLIDING RMSE
window = round(0.5*Fs);

rmseRaw = sqrt(movmean(errRaw.^2, ...
    [window-1 0]));
rmseLMS = sqrt(movmean(errLMS.^2, ...
    [window-1 0]));
rmseRLS = sqrt(movmean(errRLS.^2, ...
    [window-1 0]));

% Exclude incomplete initial windows
rmseRaw(1:window-1) = NaN;
rmseLMS(1:window-1) = NaN;
rmseRLS(1:window-1) = NaN;

%% 5. STEADY-STATE REFERENCE
steadyIdx = t>=3;

steadyRaw = sqrt(mean(errRaw(steadyIdx).^2));
steadyLMS = sqrt(mean(errLMS(steadyIdx).^2));
steadyRLS = sqrt(mean(errRLS(steadyIdx).^2));

%% 6. CONVERGENCE DETECTION
% Threshold: 110% of steady-state RMSE
% Hold time: 1 second

thresholdFactor = 1.10;
holdSamples = round(Fs*1.0);

thresholdLMS = thresholdFactor*steadyLMS;
thresholdRLS = thresholdFactor*steadyRLS;

% Search only after full sliding window exists.
% A qualifying interval must remain below threshold.

convLMS = NaN;
convRLS = NaN;

for k = window:(N-holdSamples+1)
    segmentLMS = rmseLMS(k:k+holdSamples-1);

    if all(isfinite(segmentLMS)) && ...
            all(segmentLMS<=thresholdLMS)
        convLMS = t(k);
        break;
    end
end

for k = window:(N-holdSamples+1)
    segmentRLS = rmseRLS(k:k+holdSamples-1);

    if all(isfinite(segmentRLS)) && ...
            all(segmentRLS<=thresholdRLS)
        convRLS = t(k);
        break;
    end
end

%% 7. STEADY-STATE STABILITY
% Compare residual RMSE across nonoverlapping
% one-second windows from 3s onward.

segmentLength = round(Fs);
steadyStart = find(steadyIdx,1,'first');

numSegments = floor((N-steadyStart+1)/segmentLength);

segmentTimes = zeros(numSegments,1);
segmentRaw = zeros(numSegments,1);
segmentLMS = zeros(numSegments,1);
segmentRLS = zeros(numSegments,1);

for j = 1:numSegments
    a = steadyStart+(j-1)*segmentLength;
    b = a+segmentLength-1;

    segmentTimes(j) = mean(t(a:b));
    segmentRaw(j) = sqrt(mean(errRaw(a:b).^2));
    segmentLMS(j) = sqrt(mean(errLMS(a:b).^2));
    segmentRLS(j) = sqrt(mean(errRLS(a:b).^2));
end

% Relative variation across steady-state windows
cvLMS = 100*std(segmentLMS)/mean(segmentLMS);
cvRLS = 100*std(segmentRLS)/mean(segmentRLS);

%% 8. DISPLAY RESULTS
fprintf('\n===== DAY 11 CONVERGENCE =====\n');
fprintf('Window: %d samples (%.2f s)\n', ...
    window,window/Fs);
fprintf('Threshold factor: %.2f\n',thresholdFactor);
fprintf('Hold duration: %.2f s\n',holdSamples/Fs);

fprintf('\nSteady Raw RMSE: %.6f\n',steadyRaw);
fprintf('Steady LMS RMSE: %.6f\n',steadyLMS);
fprintf('Steady RLS RMSE: %.6f\n',steadyRLS);

fprintf('\nLMS convergence time: %.4f s\n',convLMS);
fprintf('RLS convergence time: %.4f s\n',convRLS);

fprintf('\n===== STABILITY =====\n');
fprintf('LMS segment RMSE CV: %.3f %%\n',cvLMS);
fprintf('RLS segment RMSE CV: %.3f %%\n',cvRLS);

%% 9. FIGURE 1 - SLIDING RMSE
fig1 = figure('Color','w');
plot(t,rmseRaw,'Color',[0.5 0.5 0.5]); hold on;
plot(t,rmseLMS,'b','LineWidth',1.2);
plot(t,rmseRLS,'r','LineWidth',1.2);
yline(thresholdLMS,'b--','LMS threshold');
yline(thresholdRLS,'r--','RLS threshold');

if isfinite(convLMS)
    xline(convLMS,'b:','LMS convergence');
end

if isfinite(convRLS)
    xline(convRLS,'r:','RLS convergence');
end

xlabel('Time (s)');
ylabel('Sliding RMSE (m/s^2)');
title('Day 11 - LMS/RLS Convergence');
legend('Raw','LMS','RLS','Location','best');
grid on;

exportgraphics(fig1,fullfile(resultDir, ...
    'day11_convergence.png'),'Resolution',200);

%% 10. FIGURE 2 - STEADY STABILITY
fig2 = figure('Color','w');
plot(segmentTimes,segmentRaw,'-o','Color', ...
    [0.5 0.5 0.5]); hold on;
plot(segmentTimes,segmentLMS,'-ob');
plot(segmentTimes,segmentRLS,'-or');

xlabel('Time (s)');
ylabel('Segment RMSE (m/s^2)');
title('Day 11 - Steady-State Stability');
legend('Raw','LMS','RLS','Location','best');
grid on;

exportgraphics(fig2,fullfile(resultDir, ...
    'day11_stability.png'),'Resolution',200);

%% 11. SAVE SUMMARY
Method = {'Raw';'LMS';'RLS'};
Steady_RMSE = [steadyRaw;steadyLMS;steadyRLS];
Convergence_Time_s = [NaN;convLMS;convRLS];
Steady_CV_Pct = [ ...
    100*std(segmentRaw)/mean(segmentRaw); ...
    cvLMS;cvRLS];

summaryTable = table(Method,Steady_RMSE, ...
    Convergence_Time_s,Steady_CV_Pct);

disp(summaryTable);

writetable(summaryTable,fullfile(resultDir, ...
    'day11_convergence_summary.csv'));

save(fullfile(resultDir, ...
    'day11_convergence_results.mat'), ...
    'Fs','t','window','holdSamples', ...
    'thresholdFactor','rmseRaw','rmseLMS', ...
    'rmseRLS','steadyRaw','steadyLMS', ...
    'steadyRLS','convLMS','convRLS', ...
    'segmentTimes','segmentRaw','segmentLMS', ...
    'segmentRLS','cvLMS','cvRLS','summaryTable');

fprintf('\n===== DAY 11 COMPLETED =====\n');
fprintf('Results saved to 06_RESULTS\n');
