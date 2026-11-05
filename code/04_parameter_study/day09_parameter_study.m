
%% =========================================================
% DAY 09 - LMS/RLS PARAMETER STUDY
% MATLAB R2023a
%
% Project:
% Adaptive LMS/RLS for IMU Vibration Noise Reduction
%
% Input:
% day02_imu_data.mat
% day04_lms_results.mat
%
% Output:
% CSV, MAT and PNG figures in results/simulation
%% =========================================================

clc;
clear;
close all;

%% 1. PROJECT PATHS

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
resultDir = fullfile(rootDir, 'results', 'simulation');

day02File = fullfile(resultDir, 'day02_imu_data.mat');
day04File = fullfile(resultDir, 'day04_lms_results.mat');

assert(isfile(day02File), ...
    'Cannot find day02_imu_data.mat');

assert(isfile(day04File), ...
    'Cannot find day04_lms_results.mat');

%% 2. LOAD DATA

D = load(day02File);
L = load(day04File);

requiredD = {'Fs','t','s','d'};
requiredL = {'Fs','t','s','d','x'};

for k = 1:numel(requiredD)
    assert(isfield(D,requiredD{k}), ...
        'Day 02 missing variable: %s',requiredD{k});
end

for k = 1:numel(requiredL)
    assert(isfield(L,requiredL{k}), ...
        'Day 04 missing variable: %s',requiredL{k});
end

Fs = D.Fs;
t = D.t(:);
s = D.s(:);
d = D.d(:);
x = L.x(:);

N = numel(d);

%% 3. DATA VALIDATION

assert(isscalar(Fs) && isfinite(Fs) && Fs > 0, ...
    'Invalid sampling frequency');

assert(numel(t)==N && numel(s)==N && numel(x)==N, ...
    'Signal lengths do not match');

assert(all(isfinite([t;s;d;x])), ...
    'Input contains NaN or Inf');

assert(isequal(D.Fs,L.Fs), ...
    'Sampling frequencies do not match');

assert(numel(D.t)==numel(L.t), ...
    'Time vector lengths do not match');

assert(numel(D.d)==numel(L.d), ...
    'Raw signal lengths do not match');

assert(numel(D.s)==numel(L.s), ...
    'Ideal signal lengths do not match');

% Floating-point tolerance for time vectors
timeTolerance = 1e-12;

maxTimeDifference = max(abs(D.t(:)-L.t(:)));

assert(maxTimeDifference < timeTolerance, ...
    'Day 02 and Day 04 time vectors differ significantly');

% Raw and ideal signals must match
assert(isequal(D.d(:),L.d(:)), ...
    'Raw signals do not match');

assert(isequal(D.s(:),L.s(:)), ...
    'Ideal signals do not match');

assert(all(diff(t)>0), ...
    'Time vector must be increasing');

dtError = max(abs(diff(t)-1/Fs));

assert(dtError < 1e-6/Fs, ...
    'Nonuniform sampling detected');

fprintf('\n===== DAY 09 DATA CHECK =====\n');

fprintf('Fs: %.2f Hz\n',Fs);
fprintf('Samples: %d\n',N);
fprintf('Nyquist: %.2f Hz\n',Fs/2);
fprintf('Maximum dt error: %.3e s\n',dtError);
fprintf('Maximum time difference: %.3e s\n', ...
    maxTimeDifference);

fprintf('Reference x loaded from Day 04.\n');
fprintf('Data consistency check passed.\n');

%% 4. COMMON PARAMETERS

M = 16;
delta = 0.01;

steadyIdx = t >= 3;

assert(any(steadyIdx), ...
    'No steady-state samples available');

rmseRaw = sqrt(mean((d-s).^2));

rmseRawSteady = sqrt( ...
    mean((d(steadyIdx)-s(steadyIdx)).^2));

fprintf('\n===== RAW BASELINE =====\n');

fprintf('Raw RMSE: %.6f\n',rmseRaw);
fprintf('Raw steady RMSE: %.6f\n',rmseRawSteady);

%% 5. LMS PARAMETER SWEEP

muValues = [0.001 0.005 0.010 0.020 0.050];

numLMS = numel(muValues);

lmsOutputs = NaN(N,numLMS);

lmsRMSE = NaN(numLMS,1);
lmsRMSESteady = NaN(numLMS,1);
lmsRuntime = NaN(numLMS,1);
lmsStable = false(numLMS,1);

fprintf('\n===== LMS PARAMETER SWEEP =====\n');

for k = 1:numLMS

    mu = muValues(k);

    w = zeros(M,1);
    e = NaN(N,1);

    stable = true;

    timerStart = tic;

    for n = 1:N

        u = zeros(M,1);

        available = min(M,n);

        u(1:available) = ...
            x(n:-1:n-available+1);

        y = w.'*u;

        e(n) = d(n)-y;

        w = w + mu*e(n)*u;

        if ~isfinite(e(n)) || ...
                ~all(isfinite(w)) || ...
                max(abs(w)) > 1e8

            stable = false;
            break;

        end

    end

    runtime = toc(timerStart);

    lmsRuntime(k) = runtime;

    if stable

        lmsOutputs(:,k) = e;

        lmsRMSE(k) = sqrt(mean((e-s).^2));

        lmsRMSESteady(k) = sqrt( ...
            mean((e(steadyIdx)-s(steadyIdx)).^2));

        lmsStable(k) = true;

        fprintf(['mu=%.4f | RMSE=%.6f | ' ...
                 'Steady=%.6f | Runtime=%.6f s\n'], ...
                 mu,lmsRMSE(k), ...
                 lmsRMSESteady(k),runtime);

    else

        fprintf('mu=%.4f | Numerical divergence detected\n',mu);

    end

end

%% 6. RLS PARAMETER SWEEP

lambdaValues = [0.950 0.970 0.980 ...
                0.990 0.995 0.999];

numRLS = numel(lambdaValues);

rlsOutputs = NaN(N,numRLS);

rlsRMSE = NaN(numRLS,1);
rlsRMSESteady = NaN(numRLS,1);
rlsRuntime = NaN(numRLS,1);
rlsStable = false(numRLS,1);

fprintf('\n===== RLS PARAMETER SWEEP =====\n');

for k = 1:numRLS

    lambda = lambdaValues(k);

    w = zeros(M,1);
    P = eye(M)/delta;

    e = NaN(N,1);

    stable = true;

    timerStart = tic;

    for n = 1:N

        u = zeros(M,1);

        available = min(M,n);

        u(1:available) = ...
            x(n:-1:n-available+1);

        y = w.'*u;

        e(n) = d(n)-y;

        Pu = P*u;

        denominator = lambda + u.'*Pu;

        if ~isfinite(denominator) || denominator <= 0

            stable = false;
            break;

        end

        gain = Pu/denominator;

        w = w + gain*e(n);

        P = (P-gain*(u.'*P))/lambda;

        % Reduce numerical asymmetry
        P = (P+P.')/2;

        if ~isfinite(e(n)) || ...
                ~all(isfinite(w)) || ...
                ~all(isfinite(P(:))) || ...
                max(abs(w)) > 1e8

            stable = false;
            break;

        end

    end

    runtime = toc(timerStart);

    rlsRuntime(k) = runtime;

    if stable

        rlsOutputs(:,k) = e;

        rlsRMSE(k) = sqrt(mean((e-s).^2));

        rlsRMSESteady(k) = sqrt( ...
            mean((e(steadyIdx)-s(steadyIdx)).^2));

        rlsStable(k) = true;

        fprintf(['lambda=%.3f | RMSE=%.6f | ' ...
                 'Steady=%.6f | Runtime=%.6f s\n'], ...
                 lambda,rlsRMSE(k), ...
                 rlsRMSESteady(k),runtime);

    else

        fprintf('lambda=%.3f | Numerical divergence detected\n', ...
            lambda);

    end

end

%% 7. CREATE RESULTS TABLE

Method = [repmat({'LMS'},numLMS,1); ...
          repmat({'RLS'},numRLS,1)];

Parameter = [muValues(:);lambdaValues(:)];

RMSE_All = [lmsRMSE;rlsRMSE];

RMSE_Steady = [lmsRMSESteady;rlsRMSESteady];

Runtime_s = [lmsRuntime;rlsRuntime];

NumericallyStable = [lmsStable;rlsStable];

Improvement_All_Pct = ...
    100*(1-RMSE_All/rmseRaw);

Improvement_Steady_Pct = ...
    100*(1-RMSE_Steady/rmseRawSteady);

resultTable = table( ...
    Method,Parameter,RMSE_All,RMSE_Steady, ...
    Improvement_All_Pct,Improvement_Steady_Pct, ...
    Runtime_s,NumericallyStable);

fprintf('\n===== DAY 09 RESULTS =====\n');

disp(resultTable);

%% 8. FIND BEST TESTED PARAMETERS

validLMS = find(lmsStable & isfinite(lmsRMSESteady));

validRLS = find(rlsStable & isfinite(rlsRMSESteady));

assert(~isempty(validLMS), ...
    'No valid LMS configuration');

assert(~isempty(validRLS), ...
    'No valid RLS configuration');

[~,posLMS] = min(lmsRMSESteady(validLMS));

[~,posRLS] = min(rlsRMSESteady(validRLS));

bestLMSIdx = validLMS(posLMS);
bestRLSIdx = validRLS(posRLS);

bestMu = muValues(bestLMSIdx);
bestLambda = lambdaValues(bestRLSIdx);

bestLMSOutput = lmsOutputs(:,bestLMSIdx);
bestRLSOutput = rlsOutputs(:,bestRLSIdx);

fprintf('\n===== BEST TESTED PARAMETERS =====\n');

fprintf('Best LMS mu: %.5f\n',bestMu);

fprintf('Best LMS steady RMSE: %.6f\n', ...
    lmsRMSESteady(bestLMSIdx));

fprintf('Best RLS lambda: %.5f\n',bestLambda);

fprintf('Best RLS steady RMSE: %.6f\n', ...
    rlsRMSESteady(bestRLSIdx));

%% 9. LMS PARAMETER PLOT

figure('Name','Day 09 - LMS Parameters');

plot(muValues,lmsRMSESteady,'-o', ...
    'LineWidth',1.5,'MarkerSize',7);

grid on;

xlabel('LMS Step Size \mu');

ylabel('Steady-state RMSE (m/s^2)');

title('LMS Parameter Study');

saveas(gcf,fullfile(resultDir, ...
    'day09_lms_parameter_study.png'));

%% 10. RLS PARAMETER PLOT

figure('Name','Day 09 - RLS Parameters');

plot(lambdaValues,rlsRMSESteady,'-o', ...
    'LineWidth',1.5,'MarkerSize',7);

grid on;

xlabel('RLS Forgetting Factor \lambda');

ylabel('Steady-state RMSE (m/s^2)');

title('RLS Parameter Study');

saveas(gcf,fullfile(resultDir, ...
    'day09_rls_parameter_study.png'));

%% 11. BEST CONFIGURATION COMPARISON

figure('Name','Day 09 - Best Configurations');

plot(t,s,'k','LineWidth',1.5);

hold on;

plot(t,d,'Color',[0.7 0.7 0.7]);

plot(t,bestLMSOutput,'b','LineWidth',1);

plot(t,bestRLSOutput,'r','LineWidth',1);

grid on;

xlabel('Time (s)');

ylabel('Acceleration (m/s^2)');

title('Best Tested LMS/RLS Configurations');

legend('Ideal','Raw','LMS','RLS', ...
    'Location','best');

saveas(gcf,fullfile(resultDir, ...
    'day09_best_configuration_comparison.png'));

%% 12. SAVE RESULTS

csvFile = fullfile(resultDir, ...
    'day09_parameter_study.csv');

matFile = fullfile(resultDir, ...
    'day09_parameter_results.mat');

writetable(resultTable,csvFile);

save(matFile, ...
    'Fs','t','s','d','x','N','M','delta', ...
    'muValues','lambdaValues', ...
    'lmsOutputs','rlsOutputs', ...
    'lmsRMSE','rlsRMSE', ...
    'lmsRMSESteady','rlsRMSESteady', ...
    'lmsRuntime','rlsRuntime', ...
    'lmsStable','rlsStable', ...
    'resultTable', ...
    'bestMu','bestLambda', ...
    'bestLMSOutput','bestRLSOutput', ...
    'rmseRaw','rmseRawSteady');

fprintf('\nResults saved successfully.\n');

fprintf('===== DAY 09 COMPLETED =====\n');
