
%% DAY 02 - SIMULATED IMU SIGNAL
% Project: Adaptive LMS/RLS vibration noise reduction
% Data type: SIMULATION ONLY

clear;
clc;
close all;

%% STEP 1: Sampling parameters
Fs = 200;           % Sampling frequency (Hz)
T = 10;             % Signal duration (seconds)
t = (0:1/Fs:T-1/Fs)';
N = length(t);      % Number of samples

fprintf('Sampling frequency: %d Hz\n', Fs);
fprintf('Duration: %.1f seconds\n', T);
fprintf('Number of samples: %d\n', N);
fprintf('Nyquist frequency: %.1f Hz\n', Fs/2);

%% STEP 2: Ideal IMU signal
% Simulated acceleration along X axis (m/s^2)
s = 0.5*sin(2*pi*1*t) ...
  + 0.2*sin(2*pi*3*t);

%% STEP 3: Motor vibration noise
% Example motor vibration at 30 Hz and 60 Hz
rng(10);  % Reproducible simulation

v_motor = 0.8*sin(2*pi*30*t) ...
        + 0.3*sin(2*pi*60*t);

% Additional random sensor noise
v_random = 0.1*randn(N,1);

% Total disturbance
v = v_motor + v_random;

%% STEP 4: Raw IMU measurement
d = s + v;

%% STEP 5: Display basic statistics
fprintf('\n--- SIGNAL STATISTICS ---\n');
fprintf('Ideal signal RMS: %.4f m/s^2\n', rms(s));
fprintf('Noise RMS: %.4f m/s^2\n', rms(v));
fprintf('Raw signal RMS: %.4f m/s^2\n', rms(d));

%% STEP 6: Plot time-domain signals
figure('Name','Day 02 - IMU Simulation', ...
       'Color','w');

subplot(3,1,1);
plot(t,s,'b','LineWidth',1);
grid on;
title('Ideal IMU Signal s(n)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');

subplot(3,1,2);
plot(t,v,'r');
grid on;
title('Simulated Vibration Noise v(n)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');

subplot(3,1,3);
plot(t,d,'k');
grid on;
title('Raw IMU Signal d(n) = s(n) + v(n)');
xlabel('Time (s)');
ylabel('Acceleration (m/s^2)');

%% STEP 7: Save simulation data
% Save to results/simulation, outside the code directory
codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(fileparts(codeFolder));
resultFolder = fullfile(projectFolder,'results', 'simulation');

if ~exist(resultFolder,'dir')
    mkdir(resultFolder);
end

save(fullfile(resultFolder,'day02_imu_data.mat'), ...
     'Fs','T','t','N','s','v','v_motor', ...
     'v_random','d');

saveas(gcf,fullfile(resultFolder, ...
       'day02_time_domain.png'));

fprintf('\nSimulation data saved successfully.\n');
