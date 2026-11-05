
%% DAY 04 - LMS ADAPTIVE FILTER
clear; clc; close all;

%% 1. LOAD SIMULATION DATA
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
resultsFolder = fullfile(projectRoot,'results', 'simulation');

dataFile = fullfile(resultsFolder,'day02_imu_data.mat');

if ~isfile(dataFile)
    error('Data file not found!');
end

D = load(dataFile);

Fs = D.Fs;
d = D.d(:);
s = D.s(:);
x = D.v_motor(:);

N = length(d);
t = (0:N-1)'/Fs;

assert(length(s)==N && length(x)==N, ...
    'Signal lengths do not match');

%% 2. LMS PARAMETERS
M = 16;
mu = 0.01;

w = zeros(M,1);

y = zeros(N,1);
e = d;
weightHistory = zeros(M,N);

%% 3. LMS FILTER
for n = M:N

    % Reference input vector
    xVec = x(n:-1:n-M+1);

    % Estimate vibration noise
    y(n) = w' * xVec;

    % Filtered output
    e(n) = d(n) - y(n);

    % Update LMS weights
    w = w + mu * e(n) * xVec;

    weightHistory(:,n) = w;

end

%% 4. RMSE EVALUATION
rmseRaw = sqrt(mean((d-s).^2));
rmseLMS = sqrt(mean((e-s).^2));

improvement = 100*(rmseRaw-rmseLMS)/rmseRaw;

fprintf('\n===== DAY 04 LMS RESULTS =====\n');
fprintf('Sampling frequency: %.2f Hz\n',Fs);
fprintf('Number of samples: %d\n',N);
fprintf('Filter length M: %d\n',M);
fprintf('Step size mu: %.5f\n',mu);

fprintf('\nRaw RMSE: %.6f m/s^2\n',rmseRaw);
fprintf('LMS RMSE: %.6f m/s^2\n',rmseLMS);
fprintf('RMSE improvement: %.2f %%\n',improvement);

%% 5. TIME DOMAIN COMPARISON
fig1 = figure('Name','Day 04 - Raw LMS Ideal');

subplot(3,1,1);
plot(t,d,'Color',[0.5 0.5 0.5]);
title('Raw IMU Signal');
xlabel('Time (s)');
ylabel('m/s^2');
grid on;

subplot(3,1,2);
plot(t,s,'k','LineWidth',1);
hold on;
plot(t,e,'r');
title('Ideal vs LMS');
legend('Ideal','LMS');
xlabel('Time (s)');
ylabel('m/s^2');
grid on;

subplot(3,1,3);
plot(t,d-s,'Color',[0.5 0.5 0.5]);
hold on;
plot(t,e-s,'b');
title('Error Comparison');
legend('Raw Error','LMS Error');
xlabel('Time (s)');
ylabel('m/s^2');
grid on;

%% 6. LMS CONVERGENCE
fig2 = figure('Name','Day 04 - LMS Convergence');

plot(t,weightHistory');
title('LMS Coefficient Evolution');
xlabel('Time (s)');
ylabel('Weight Value');
grid on;

%% 7. SAVE RESULTS
save(fullfile(resultsFolder,'day04_lms_results.mat'), ...
    'Fs','N','t','d','s','x','y','e', ...
    'M','mu','weightHistory', ...
    'rmseRaw','rmseLMS','improvement');

saveas(fig1,fullfile(resultsFolder, ...
    'day04_lms_time_domain.png'));

saveas(fig2,fullfile(resultsFolder, ...
    'day04_lms_convergence.png'));

fprintf('\nResults saved successfully.\n');
fprintf('===== DAY 04 LMS COMPLETED =====\n');
