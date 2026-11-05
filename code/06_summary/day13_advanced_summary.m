
%% =========================================================
% DAY 13 - ADVANCED RESULTS SUMMARY
% LMS/RLS Adaptive Filtering for IMU Noise Reduction
% MATLAB R2023a
%
% Input: Day 07, 09, 10, 11, 12 MAT files
% Output: Summary CSV and MAT files
%% =========================================================

clc;
clear;
close all;

%% STEP 1 - PATHS

projectDir = ...
    fileparts(fileparts(fileparts(mfilename('fullpath'))));

resultDir = fullfile(projectDir,'results', 'simulation');

file07 = fullfile(resultDir, ...
    'day07_frequency_results.mat');

file09 = fullfile(resultDir, ...
    'day09_parameter_results.mat');

file09diag = fullfile(resultDir, ...
    'day09_rls_diagnostic_results.mat');

file10 = fullfile(resultDir, ...
    'day10_frequency_levels.mat');

file11 = fullfile(resultDir, ...
    'day11_convergence_results.mat');

file12 = fullfile(resultDir, ...
    'day12_sensitivity_results.mat');

allFiles = {file07,file09,file09diag, ...
            file10,file11,file12};

for k = 1:numel(allFiles)
    if ~isfile(allFiles{k})
        error('Missing file: %s',allFiles{k});
    end
end

%% STEP 2 - LOAD DATA

F = load(file07);
P = load(file09);
D = load(file09diag);
V = load(file10);
C = load(file11);
S = load(file12);

fprintf('===== DAY 13 ADVANCED SUMMARY =====\n');

%% STEP 3 - FREQUENCY RESULTS

frequencyMethod = {'LMS';'RLS'};

fftAttenuation = [F.attenLMS; F.attenRLS];

psdAttenuation = [ ...
    F.psdReductionLMS;
    F.psdReductionRLS
];

frequencySummary = table( ...
    frequencyMethod, ...
    fftAttenuation, ...
    psdAttenuation, ...
    'VariableNames', ...
    {'Method','FFT_Attenuation_dB', ...
     'PSD_Attenuation_dB'});

fprintf('\n===== FREQUENCY SUMMARY =====\n');
disp(frequencySummary);

%% STEP 4 - CONVERGENCE RESULTS

Method = {'Raw';'LMS';'RLS'};

Steady_RMSE = [ ...
    C.steadyRaw;
    C.steadyLMS;
    C.steadyRLS
];

Convergence_Time_s = [ ...
    NaN;
    C.convLMS;
    C.convRLS
];

Steady_CV_Pct = [ ...
    100*std(C.segmentRaw)/mean(C.segmentRaw);
    C.cvLMS;
    C.cvRLS
];

convergenceSummary = table( ...
    Method, ...
    Steady_RMSE, ...
    Convergence_Time_s, ...
    Steady_CV_Pct);

fprintf('\n===== CONVERGENCE SUMMARY =====\n');
disp(convergenceSummary);

%% STEP 5 - LMS PARAMETER SENSITIVITY

Mu = S.muValues(:);
LMS_RMSE = S.lmsRMSE(:);
LMS_Stable = logical(S.lmsStable(:));

lmsSensitivity = table( ...
    Mu,LMS_RMSE,LMS_Stable);

fprintf('\n===== LMS SENSITIVITY =====\n');
disp(lmsSensitivity);

%% STEP 6 - RLS PARAMETER SENSITIVITY

Lambda = S.lambdaValues(:);
RLS_RMSE = S.rlsRMSE(:);
RLS_Stable = logical(S.rlsStable(:));

rlsSensitivity = table( ...
    Lambda,RLS_RMSE,RLS_Stable);

fprintf('\n===== RLS SENSITIVITY =====\n');
disp(rlsSensitivity);

%% STEP 7 - RLS DIAGNOSTICS

diagnosticLambda = D.lambdaValues(:);
failureSample = D.failureSample(:);
failureTime = D.failureTime(:);
completed = logical(D.completed(:));

rlsDiagnosticSummary = table( ...
    diagnosticLambda, ...
    failureSample, ...
    failureTime, ...
    completed, ...
    'VariableNames', ...
    {'Lambda','Failure_Sample', ...
     'Failure_Time_s','Completed'});

fprintf('\n===== RLS DIAGNOSTICS =====\n');
disp(rlsDiagnosticSummary);

%% STEP 8 - VIBRATION LEVEL RESULTS

levels = V.levels(:);

fftLMS = V.fftLMSAtten(:);
fftRLS = V.fftRLSAtten(:);

psdLMS = V.psdLMSAtten(:);
psdRLS = V.psdRLSAtten(:);

vibrationSummary = table( ...
    levels,fftLMS,fftRLS,psdLMS,psdRLS, ...
    'VariableNames', ...
    {'Vibration_Level', ...
     'LMS_FFT_Attenuation_dB', ...
     'RLS_FFT_Attenuation_dB', ...
     'LMS_PSD_Attenuation_dB', ...
     'RLS_PSD_Attenuation_dB'});

fprintf('\n===== VIBRATION LEVEL SUMMARY =====\n');
disp(vibrationSummary);

%% STEP 9 - RUNTIME FROM DAY 09

lmsRuntime = P.lmsRuntime(:);
rlsRuntime = P.rlsRuntime(:);

lmsRuntimeSummary = table( ...
    P.muValues(:),lmsRuntime, ...
    'VariableNames',{'Mu','Runtime_s'});

rlsRuntimeSummary = table( ...
    P.lambdaValues(:),rlsRuntime, ...
    'VariableNames',{'Lambda','Runtime_s'});

fprintf('\n===== LMS RUNTIME =====\n');
disp(lmsRuntimeSummary);

fprintf('\n===== RLS RUNTIME =====\n');
disp(rlsRuntimeSummary);

%% STEP 10 - SAVE TABLES

writetable(frequencySummary, ...
    fullfile(resultDir,'day13_frequency_summary.csv'));

writetable(convergenceSummary, ...
    fullfile(resultDir,'day13_convergence_summary.csv'));

writetable(lmsSensitivity, ...
    fullfile(resultDir,'day13_lms_sensitivity.csv'));

writetable(rlsSensitivity, ...
    fullfile(resultDir,'day13_rls_sensitivity.csv'));

writetable(rlsDiagnosticSummary, ...
    fullfile(resultDir,'day13_rls_diagnostics.csv'));

writetable(vibrationSummary, ...
    fullfile(resultDir,'day13_vibration_summary.csv'));

writetable(lmsRuntimeSummary, ...
    fullfile(resultDir,'day13_lms_runtime.csv'));

writetable(rlsRuntimeSummary, ...
    fullfile(resultDir,'day13_rls_runtime.csv'));

save(fullfile(resultDir, ...
    'day13_advanced_summary.mat'), ...
    'frequencySummary', ...
    'convergenceSummary', ...
    'lmsSensitivity', ...
    'rlsSensitivity', ...
    'rlsDiagnosticSummary', ...
    'vibrationSummary', ...
    'lmsRuntimeSummary', ...
    'rlsRuntimeSummary');

fprintf('\n===== DAY 13 ADVANCED SUMMARY COMPLETED =====\n');
fprintf('All summary files saved.\n');
