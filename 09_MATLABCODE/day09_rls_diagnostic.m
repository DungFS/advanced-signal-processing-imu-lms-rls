
%% =========================================================
% DAY 09 - RLS NUMERICAL DIAGNOSTIC
% MATLAB R2023a
%
% Diagnose lambda = 0.950, 0.970, 0.980
% No modification of existing results
%% =========================================================

clc;
clear;
close all;

%% 1. PROJECT PATHS

rootDir = 'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';
resultDir = fullfile(rootDir,'06_RESULTS');

inputFile = fullfile(resultDir, ...
    'day09_parameter_results.mat');

assert(isfile(inputFile), ...
    'Day 09 MAT file not found');

% New diagnostic output files
csvFile = fullfile(resultDir, ...
    'day09_rls_diagnostic_summary.csv');

matFile = fullfile(resultDir, ...
    'day09_rls_diagnostic_results.mat');

pngFile = fullfile(resultDir, ...
    'day09_rls_diagnostic_weights.png');

% Prevent accidental overwriting
assert(~isfile(csvFile) && ...
       ~isfile(matFile) && ...
       ~isfile(pngFile), ...
       ['Diagnostic output already exists. ' ...
        'Move or rename existing diagnostic files first.']);

%% 2. LOAD ORIGINAL DATA

D = load(inputFile);

required = {'Fs','t','s','d','x','M','delta'};

for k = 1:numel(required)
    assert(isfield(D,required{k}), ...
        'Missing variable: %s',required{k});
end

Fs = D.Fs;
t = D.t(:);
s = D.s(:);
d = D.d(:);
x = D.x(:);

M = D.M;
delta = D.delta;
N = numel(d);

assert(numel(x)==N && numel(s)==N && ...
       numel(t)==N, 'Signal length mismatch');

assert(all(isfinite([x;d;s;t])), ...
    'Input contains NaN or Inf');

assert(Fs>0 && M>=1 && M==floor(M) && delta>0, ...
    'Invalid parameters');

fprintf('\n===== RLS DIAGNOSTIC DATA =====\n');
fprintf('Fs: %.2f Hz\n',Fs);
fprintf('Samples: %d\n',N);
fprintf('Filter order M: %d\n',M);
fprintf('Delta: %.6f\n',delta);

%% 3. DIAGNOSTIC CONFIGURATION

lambdaValues = [0.950 0.970 0.980];

numCases = numel(lambdaValues);

% Same numerical threshold as Day 09
weightLimit = 1e8;

% Store results for each case
failureSample = NaN(numCases,1);
failureTime = NaN(numCases,1);
failureReason = cell(numCases,1);

lastMaxWeight = NaN(numCases,1);
lastMaxP = NaN(numCases,1);
lastDenominator = NaN(numCases,1);
lastError = NaN(numCases,1);

completed = false(numCases,1);

weightHistory = NaN(N,numCases);
pHistory = NaN(N,numCases);
errorHistory = NaN(N,numCases);
denominatorHistory = NaN(N,numCases);

%% 4. RUN RLS DIAGNOSTIC

fprintf('\n===== RLS DIAGNOSTIC START =====\n');

for k = 1:numCases

    lambda = lambdaValues(k);

    fprintf('\n--- lambda = %.3f ---\n',lambda);

    w = zeros(M,1);
    P = eye(M)/delta;

    reason = 'Completed all samples';
    failIdx = NaN;

    for n = 1:N

        %% Build reference vector

        u = zeros(M,1);

        available = min(M,n);

        u(1:available) = ...
            x(n:-1:n-available+1);

        %% Calculate filter output

        y = w.'*u;

        e = d(n)-y;

        %% RLS gain calculation

        Pu = P*u;

        denominator = lambda + u.'*Pu;

        % Check denominator
        if ~isfinite(denominator)

            reason = 'Nonfinite denominator';
            failIdx = n;
            break;

        end

        if denominator <= 0

            reason = 'Nonpositive denominator';
            failIdx = n;
            break;

        end

        gain = Pu/denominator;

        %% Update weights and P

        w = w + gain*e;

        P = (P-gain*(u.'*P))/lambda;

        P = (P+P.')/2;

        %% Record numerical values

        maxW = max(abs(w));
        maxP = max(abs(P(:)));

        weightHistory(n,k) = maxW;
        pHistory(n,k) = maxP;
        errorHistory(n,k) = e;
        denominatorHistory(n,k) = denominator;

        lastMaxWeight(k) = maxW;
        lastMaxP(k) = maxP;
        lastDenominator(k) = denominator;
        lastError(k) = e;

        %% Check numerical failure

        if ~isfinite(e)

            reason = 'Nonfinite error';
            failIdx = n;
            break;

        end

        if ~all(isfinite(w))

            reason = 'Nonfinite weights';
            failIdx = n;
            break;

        end

        if ~all(isfinite(P(:)))

            reason = 'Nonfinite P matrix';
            failIdx = n;
            break;

        end

        if maxW > weightLimit

            reason = 'Weight threshold exceeded';
            failIdx = n;
            break;

        end

    end

    %% Record diagnostic result

    if isnan(failIdx)

        completed(k) = true;

        fprintf('Completed all %d samples.\n',N);

    else

        failureSample(k) = failIdx;
        failureTime(k) = t(failIdx);

        fprintf('Failure sample: %d\n',failIdx);
        fprintf('Failure time: %.6f s\n',t(failIdx));

    end

    failureReason{k} = reason;

    fprintf('Reason: %s\n',reason);
    fprintf('Last max|w|: %.6e\n',lastMaxWeight(k));
    fprintf('Last max|P|: %.6e\n',lastMaxP(k));
    fprintf('Last denominator: %.6e\n', ...
        lastDenominator(k));
    fprintf('Last error: %.6e\n',lastError(k));

end

%% 5. CREATE DIAGNOSTIC SUMMARY

summaryTable = table( ...
    lambdaValues(:), ...
    completed, ...
    failureSample, ...
    failureTime, ...
    failureReason, ...
    lastMaxWeight, ...
    lastMaxP, ...
    lastDenominator, ...
    lastError, ...
    'VariableNames', ...
    {'Lambda','Completed','FailureSample', ...
     'FailureTime_s','FailureReason', ...
     'MaxWeight','MaxP','Denominator','Error'});

fprintf('\n===== DIAGNOSTIC SUMMARY =====\n');

disp(summaryTable);

%% 6. PLOT WEIGHT GROWTH

fig = figure('Name','RLS Diagnostic - Weight Growth');

hold on;

for k = 1:numCases

    valid = isfinite(weightHistory(:,k));

    semilogy(t(valid),weightHistory(valid,k), ...
        'LineWidth',1.5);

end

yline(weightLimit,'k--','Weight threshold');

grid on;

xlabel('Time (s)');
ylabel('Maximum absolute weight');
title('RLS Numerical Diagnostic');

legend('lambda=0.950', ...
       'lambda=0.970', ...
       'lambda=0.980', ...
       'Threshold', ...
       'Location','best');

%% 7. SAVE NEW DIAGNOSTIC RESULTS

writetable(summaryTable,csvFile);

save(matFile, ...
    'Fs','t','M','delta', ...
    'lambdaValues','weightLimit', ...
    'summaryTable','weightHistory', ...
    'pHistory','errorHistory', ...
    'denominatorHistory', ...
    'failureSample','failureTime', ...
    'failureReason','completed');

saveas(fig,pngFile);

fprintf('\nDiagnostic results saved.\n');
fprintf('Original Day 09 files were not modified.\n');
fprintf('===== DAY 09 RLS DIAGNOSTIC COMPLETED =====\n');
