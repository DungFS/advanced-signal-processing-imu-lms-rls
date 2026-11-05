
%% DAY 1 - MATLAB FIRST SIMULATION
% Project: LMS/RLS Adaptive Filtering for IMU
% MATLAB R2023a

%% STEP 1: Clear environment
clc;
clear;
close all;

%% STEP 2: Define signal parameters
fs = 500;       % Sampling frequency (Hz)
f = 10;         % Signal frequency (Hz)
T = 2;          % Duration (seconds)
A = 1;          % Signal amplitude

%% STEP 3: Generate time vector
t = 0:1/fs:T-1/fs;

%% STEP 4: Generate sine signal
s = A * sin(2*pi*f*t);

%% STEP 5: Display signal information
N = length(s);

fprintf('Sampling frequency: %d Hz\n', fs);
fprintf('Signal frequency: %d Hz\n', f);
fprintf('Duration: %.1f seconds\n', T);
fprintf('Number of samples: %d\n', N);
fprintf('Nyquist frequency: %.1f Hz\n', fs/2);

%% STEP 6: Plot the signal
figure('Name', 'Day 1 - Sine Signal');

plot(t, s, 'b', 'LineWidth', 1.5);

grid on;
xlabel('Time (seconds)');
ylabel('Amplitude');
title('Day 1 - Simulated Sine Signal');

xlim([0 T]);
ylim([-1.2 1.2]);

%% STEP 7: Save the figure
codeFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(fileparts(codeFolder));
resultFolder = fullfile(projectFolder, 'results', 'simulation');

if ~exist(resultFolder, 'dir')
    mkdir(resultFolder);
end

saveas(gcf, fullfile(resultFolder, 'day1_sine.png'));

%% STEP 8: Finish
disp('DAY 1 SIMULATION COMPLETED SUCCESSFULLY!');
