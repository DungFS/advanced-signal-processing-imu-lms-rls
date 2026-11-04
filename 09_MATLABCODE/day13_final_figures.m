
%% =========================================================
% DAY 13 - FINAL COMPARISON FIGURES
% Project: LMS/RLS IMU Noise Reduction
% MATLAB R2023a
%% =========================================================

clc;
clear;
close all;

%% STEP 1 - PROJECT PATH

projectDir = ...
    'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';

resultDir = fullfile(projectDir,'06_RESULTS');

dataFile = fullfile(resultDir, ...
    'day13_final_summary.mat');

if ~isfile(dataFile)
    error('Day 13 summary file not found.');
end

%% STEP 2 - LOAD DATA

R = load(dataFile);

required = {'Fs','t','s','d','eLMS','eRLS', ...
            'summaryTable','consistencyPassed'};

for k = 1:numel(required)
    if ~isfield(R,required{k})
        error('Missing variable: %s',required{k});
    end
end

if ~R.consistencyPassed
    error('Day 13 summary validation did not pass.');
end

Fs = R.Fs;
t = R.t(:);
s = R.s(:);
d = R.d(:);
eLMS = R.eLMS(:);
eRLS = R.eRLS(:);

T = R.summaryTable;

N = numel(t);

if any([numel(s),numel(d), ...
        numel(eLMS),numel(eRLS)] ~= N)
    error('Signal lengths do not match.');
end

fprintf('===== DAY 13 FIGURE DATA CHECK =====\n');
fprintf('Fs: %.2f Hz\n',Fs);
fprintf('Samples: %d\n',N);

%% STEP 3 - TIME DOMAIN COMPARISON

fig1 = figure('Color','w', ...
    'Position',[100 100 1200 650]);

plot(t,s,'k','LineWidth',1.7);
hold on;

plot(t,d,'Color',[0.65 0.65 0.65], ...
    'LineWidth',0.8);

plot(t,eLMS,'b','LineWidth',1.0);

plot(t,eRLS,'r','LineWidth',1.0);

xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');

title('Time-Domain Comparison: Ideal, Raw, LMS, RLS');

legend('Ideal','Raw','LMS','RLS', ...
    'Location','best');

grid on;
xlim([t(1) t(end)]);

exportgraphics(fig1,fullfile(resultDir, ...
    'day13_time_comparison.png'), ...
    'Resolution',300);

fprintf('Figure 1 saved.\n');

%% STEP 4 - STEADY-STATE DETAIL

idxZoom = t >= 5 & t <= 6;

if ~any(idxZoom)
    error('Zoom window 5-6 s is unavailable.');
end

fig2 = figure('Color','w', ...
    'Position',[120 120 1200 650]);

plot(t(idxZoom),s(idxZoom), ...
    'k','LineWidth',2);
hold on;

plot(t(idxZoom),d(idxZoom), ...
    'Color',[0.65 0.65 0.65]);

plot(t(idxZoom),eLMS(idxZoom), ...
    'b','LineWidth',1.3);

plot(t(idxZoom),eRLS(idxZoom), ...
    'r','LineWidth',1.3);

xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');

title('Steady-State Signal Comparison (5-6 s)');

legend('Ideal','Raw','LMS','RLS', ...
    'Location','best');

grid on;

exportgraphics(fig2,fullfile(resultDir, ...
    'day13_steady_zoom.png'), ...
    'Resolution',300);

fprintf('Figure 2 saved.\n');

%% STEP 5 - RMSE COMPARISON

fig3 = figure('Color','w', ...
    'Position',[150 150 900 600]);

bar(T.RMSE_Steady);

set(gca,'XTick',1:height(T), ...
    'XTickLabel',T.Method);

ylabel('RMSE (m/s^2)');
title('Steady-State RMSE Comparison');

grid on;

for k = 1:height(T)
    text(k,T.RMSE_Steady(k), ...
        sprintf('%.6f',T.RMSE_Steady(k)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom');
end

ylim([0 max(T.RMSE_Steady)*1.18]);

exportgraphics(fig3,fullfile(resultDir, ...
    'day13_rmse_comparison.png'), ...
    'Resolution',300);

fprintf('Figure 3 saved.\n');

%% STEP 6 - SNR COMPARISON

fig4 = figure('Color','w', ...
    'Position',[180 180 900 600]);

bar(T.SNR_dB);

set(gca,'XTick',1:height(T), ...
    'XTickLabel',T.Method);

ylabel('SNR (dB)');
title('Steady-State SNR Comparison');

grid on;
yline(0,'k-');

exportgraphics(fig4,fullfile(resultDir, ...
    'day13_snr_comparison.png'), ...
    'Resolution',300);

fprintf('Figure 4 saved.\n');

%% STEP 7 - RMSE REDUCTION

fig5 = figure('Color','w', ...
    'Position',[200 200 900 600]);

reduction = T.RMSE_Reduction_Pct(2:3);

bar(reduction);

set(gca,'XTick',1:2, ...
    'XTickLabel',T.Method(2:3));

ylabel('RMSE Reduction (%)');

title('RMSE Reduction Relative to Raw Signal');

grid on;

for k = 1:2
    text(k,reduction(k), ...
        sprintf('%.2f%%',reduction(k)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom');
end

ylim([min(0,min(reduction)*1.1), ...
      max(1,max(reduction)*1.18)]);

exportgraphics(fig5,fullfile(resultDir, ...
    'day13_rmse_reduction.png'), ...
    'Resolution',300);

fprintf('Figure 5 saved.\n');

%% STEP 8 - COMPLETION

fprintf('\n===== DAY 13 FIGURES COMPLETED =====\n');

fprintf('Saved 5 figures to:\n%s\n',resultDir);
