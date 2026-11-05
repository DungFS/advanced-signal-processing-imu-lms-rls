
%% DAY 05 - RLS ADAPTIVE FILTER
% Project: IMU vibration noise reduction
% MATLAB R2023a
% Data: Simulation from Day 02

clear;
clc;
close all;

%% 1. PROJECT PATHS

projectRoot = ...
    fileparts(fileparts(fileparts(mfilename('fullpath'))));

resultFolder = fullfile(projectRoot, 'results', 'simulation');

dataFile = fullfile(resultFolder, 'day02_imu_data.mat');

if ~isfile(dataFile)
    error('Cannot find day02_imu_data.mat');
end

%% 2. LOAD SIMULATION DATA

D = load(dataFile);

Fs = D.Fs;
d = D.d(:);
s = D.s(:);
t = D.t(:);

% Same reference signal used in Day 04
x = D.v_motor(:);

N = length(d);

assert(length(x)==N && length(s)==N && length(t)==N, ...
    'Signal lengths do not match.');

assert(all(isfinite([d; s; x])), ...
    'Signals contain NaN or Inf.');

fprintf('\n===== DAY 05 RLS =====\n');
fprintf('Sampling frequency: %.2f Hz\n', Fs);
fprintf('Number of samples: %d\n', N);

%% 3. RLS PARAMETERS

M = 16;
lambda = 0.99;
delta = 0.01;

% Initial filter weights
w = zeros(M,1);

% Initial inverse correlation matrix
P = (1/delta)*eye(M);

% Output arrays
y = zeros(N,1);
e = zeros(N,1);

weightHistory = zeros(M,N);

%% 4. RLS ADAPTIVE FILTER

tic;

for n = 1:N

    % Build reference input vector
    xVec = zeros(M,1);

    for k = 1:M
        idx = n-k+1;

        if idx >= 1
            xVec(k) = x(idx);
        end
    end

    % Estimate noise
    y(n) = w.' * xVec;

    % Error signal / filtered output
    e(n) = d(n) - y(n);

    % RLS gain vector
    Px = P*xVec;

    denominator = lambda + xVec.'*Px;

    if ~isfinite(denominator) || denominator <= 0
        error('RLS numerical instability at sample %d', n);
    end

    K = Px/denominator;

    % Update filter coefficients
    w = w + K*e(n);

    % Update inverse correlation matrix
    P = (P - K*(xVec.'*P))/lambda;

    % Reduce floating-point asymmetry
    P = (P + P.')/2;

    if any(~isfinite(w)) || any(~isfinite(P(:)))
        error('RLS produced non-finite values at sample %d', n);
    end

    weightHistory(:,n) = w;

end

runtimeRLS = toc;

%% 5. RMSE EVALUATION

rmseRaw = sqrt(mean((d-s).^2));
rmseRLS = sqrt(mean((e-s).^2));

improvement = ...
    100*(rmseRaw-rmseRLS)/rmseRaw;

% Steady-state evaluation: 3 to 10 seconds
steadyIdx = t >= 3;

rmseRawSteady = ...
    sqrt(mean((d(steadyIdx)-s(steadyIdx)).^2));

rmseRLSSteady = ...
    sqrt(mean((e(steadyIdx)-s(steadyIdx)).^2));

improvementSteady = ...
    100*(rmseRawSteady-rmseRLSSteady)/rmseRawSteady;

%% 6. PRINT RESULTS

fprintf('\n===== RLS PARAMETERS =====\n');
fprintf('Filter length M: %d\n', M);
fprintf('Forgetting factor lambda: %.4f\n', lambda);
fprintf('Initialization delta: %.4f\n', delta);

fprintf('\n===== RLS RESULTS =====\n');
fprintf('Raw RMSE: %.6f m/s^2\n', rmseRaw);
fprintf('RLS RMSE: %.6f m/s^2\n', rmseRLS);
fprintf('RMSE improvement: %.2f %%\n', improvement);

fprintf('\n===== STEADY-STATE (3-10s) =====\n');
fprintf('Raw steady RMSE: %.6f\n', rmseRawSteady);
fprintf('RLS steady RMSE: %.6f\n', rmseRLSSteady);
fprintf('Steady improvement: %.2f %%\n', improvementSteady);

fprintf('\nRLS runtime: %.6f seconds\n', runtimeRLS);

%% 7. TIME DOMAIN PLOTS

fig1 = figure('Name','Day 05 - RLS Time Domain');

subplot(3,1,1);
plot(t,d,'r');
hold on;
plot(t,s,'k','LineWidth',1);
grid on;
title('Raw IMU vs Ideal');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
legend('Raw','Ideal');

subplot(3,1,2);
plot(t,e,'b');
hold on;
plot(t,s,'k','LineWidth',1);
grid on;
title('RLS Output vs Ideal');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');
legend('RLS','Ideal');

subplot(3,1,3);
plot(t,d-s,'r');
hold on;
plot(t,e-s,'b');
grid on;
title('Estimation Error Comparison');
xlabel('Time (s)');
ylabel('Error (m/s^2)');
legend('Raw Error','RLS Error');

%% 8. WEIGHT CONVERGENCE

fig2 = figure('Name','Day 05 - RLS Convergence');

plot(t,weightHistory.');
grid on;
title('RLS Filter Coefficient Evolution');
xlabel('Time (s)');
ylabel('Coefficient Value');

%% 9. SAVE RESULTS

save(fullfile(resultFolder,'day05_rls_results.mat'), ...
    'Fs','N','t','d','s','x','y','e', ...
    'M','lambda','delta','weightHistory', ...
    'rmseRaw','rmseRLS','improvement', ...
    'rmseRawSteady','rmseRLSSteady', ...
    'improvementSteady','runtimeRLS');

saveas(fig1,fullfile(resultFolder, ...
    'day05_rls_time_domain.png'));

saveas(fig2,fullfile(resultFolder, ...
    'day05_rls_convergence.png'));

fprintf('\nResults saved successfully.\n');
fprintf('===== DAY 05 RLS COMPLETED =====\n');
