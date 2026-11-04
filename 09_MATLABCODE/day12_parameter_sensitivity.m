
%% DAY 12 - LMS/RLS PARAMETER SENSITIVITY
clear; clc; close all;

rootDir = 'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';
resultDir = fullfile(rootDir,'06_RESULTS');

%% 1. LOAD ORIGINAL DATA
dataFile = fullfile(resultDir,'day02_imu_data.mat');
assert(isfile(dataFile),'Day 02 data file not found.');

D = load(dataFile);
required = {'Fs','t','s','d','x'};
% Reference x may be stored in a later result file.
if ~isfield(D,'x')
    L = load(fullfile(resultDir,'day04_lms_results.mat'));
    assert(isfield(L,'x'),'Reference x not found.');
    D.x = L.x;
end

Fs = D.Fs;
t = D.t(:);
s = D.s(:);
d = D.d(:);
x = D.x(:);
N = numel(d);

assert(all([numel(t),numel(s),numel(x)] == N), ...
    'Signal lengths are inconsistent.');
assert(all(isfinite([d;s;x])),'Nonfinite input detected.');
assert(max(abs(diff(t)-1/Fs)) < 1e-8, ...
    'Sampling interval mismatch.');

M = 16;
steadyIdx = t >= 3;
delta = 0.01;

muValues = [0.001 0.003 0.005 0.010 0.020];
lambdaValues = [0.950 0.970 0.980 0.990 0.995 0.999];

fprintf('===== DAY 12 DATA CHECK =====\n');
fprintf('Fs: %.2f Hz\n',Fs);
fprintf('Samples: %d\n',N);
fprintf('Filter order M: %d\n',M);

%% 2. LMS PARAMETER SWEEP
lmsRMSE = nan(numel(muValues),1);
lmsStable = false(numel(muValues),1);
lmsRuntime = nan(numel(muValues),1);

for k = 1:numel(muValues)
    mu = muValues(k);
    w = zeros(M,1);
    e = nan(N,1);
    stable = true;

    tic;
    for n = 1:N
        u = zeros(M,1);
        len = min(n,M);
        u(1:len) = x(n:-1:n-len+1);

        y = w.'*u;
        e(n) = d(n)-y;
        w = w + mu*e(n)*u;

        if any(~isfinite(w)) || ...
                any(abs(w)>1e8) || ~isfinite(e(n))
            stable = false;
            break;
        end
    end
    elapsed = toc;

    if stable
        lmsRMSE(k) = sqrt(mean((e(steadyIdx)-s(steadyIdx)).^2));
        lmsRuntime(k) = elapsed;
        lmsStable(k) = true;
    end
end

lmsTable = table(muValues(:),lmsRMSE,lmsStable,lmsRuntime, ...
    'VariableNames',{'Mu','Steady_RMSE','Stable','Runtime_s'});

disp('===== LMS PARAMETER SWEEP =====');
disp(lmsTable);

%% 3. RLS PARAMETER SWEEP
rlsRMSE = nan(numel(lambdaValues),1);
rlsStable = false(numel(lambdaValues),1);
rlsRuntime = nan(numel(lambdaValues),1);
rlsFailureSample = nan(numel(lambdaValues),1);

for k = 1:numel(lambdaValues)
    lambda = lambdaValues(k);
    w = zeros(M,1);
    P = eye(M)/delta;
    e = nan(N,1);
    stable = true;

    tic;
    for n = 1:N
        u = zeros(M,1);
        len = min(n,M);
        u(1:len) = x(n:-1:n-len+1);

        Pu = P*u;
        denom = lambda + u.'*Pu;

        if ~isfinite(denom) || denom <= 0
            stable = false;
            rlsFailureSample(k) = n;
            break;
        end

        gain = Pu/denom;
        e(n) = d(n)-w.'*u;
        w = w + gain*e(n);
        P = (P-gain*(u.'*P))/lambda;
        P = (P+P.')/2;

        if any(~isfinite(w)) || ...
                any(~isfinite(P(:))) || ...
                max(abs(w))>1e8 || ...
                max(abs(P(:)))>1e14 || ...
                ~isfinite(e(n))
            stable = false;
            rlsFailureSample(k) = n;
            break;
        end
    end
    elapsed = toc;

    if stable
        rlsRMSE(k) = sqrt(mean((e(steadyIdx)-s(steadyIdx)).^2));
        rlsRuntime(k) = elapsed;
        rlsStable(k) = true;
    end
end

rlsTable = table(lambdaValues(:),rlsRMSE,rlsStable, ...
    rlsRuntime,rlsFailureSample, ...
    'VariableNames',{'Lambda','Steady_RMSE', ...
    'Stable','Runtime_s','Failure_Sample'});

disp('===== RLS PARAMETER SWEEP =====');
disp(rlsTable);

%% 4. BEST VALID CONFIGURATION
validLMS = find(lmsStable & isfinite(lmsRMSE));
validRLS = find(rlsStable & isfinite(rlsRMSE));

if ~isempty(validLMS)
    [~,i] = min(lmsRMSE(validLMS));
    bestLMS = validLMS(i);
    fprintf('Best tested LMS mu: %.4f\n',muValues(bestLMS));
    fprintf('LMS steady RMSE: %.6f\n',lmsRMSE(bestLMS));
end

if ~isempty(validRLS)
    [~,i] = min(rlsRMSE(validRLS));
    bestRLS = validRLS(i);
    fprintf('Best tested RLS lambda: %.4f\n',lambdaValues(bestRLS));
    fprintf('RLS steady RMSE: %.6f\n',rlsRMSE(bestRLS));
end

%% 5. PLOTS
fig = figure('Color','w','Position',[100 100 1050 420]);

subplot(1,2,1);
plot(muValues,lmsRMSE,'-o','LineWidth',1.5);
grid on;
xlabel('LMS step size \mu');
ylabel('Steady RMSE (m/s^2)');
title('LMS Parameter Sensitivity');

subplot(1,2,2);
plot(lambdaValues,rlsRMSE,'-o','LineWidth',1.5);
grid on;
xlabel('RLS forgetting factor \lambda');
ylabel('Steady RMSE (m/s^2)');
title('RLS Parameter Sensitivity');

%% 6. SAVE RESULTS
writetable(lmsTable,fullfile(resultDir, ...
    'day12_lms_sensitivity.csv'));
writetable(rlsTable,fullfile(resultDir, ...
    'day12_rls_sensitivity.csv'));

save(fullfile(resultDir,'day12_sensitivity_results.mat'), ...
    'Fs','M','muValues','lambdaValues', ...
    'lmsTable','rlsTable','lmsRMSE','rlsRMSE', ...
    'lmsStable','rlsStable');

saveas(fig,fullfile(resultDir, ...
    'day12_parameter_sensitivity.png'));

fprintf('\n===== DAY 12 COMPLETED =====\n');
fprintf('Results saved to 06_RESULTS.\n');
