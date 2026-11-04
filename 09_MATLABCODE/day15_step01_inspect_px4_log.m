%% DAY 15 - STEP 01: INSPECT PX4 ULOG
% MATLAB R2023a. ulogreader requires UAV Toolbox.
clear; clc; close all;

baseDir = 'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';
resultDir = fullfile(baseDir, '06_RESULTS');
logFile = fullfile(resultDir, 'log_4_2026-10-25-17-24-42.ulg');

fprintf('===== PX4 LOG INSPECTION =====\n');
if ~isfile(logFile)
    error('Log not found: %s\nCopy the .ulg file to 06_RESULTS.', logFile);
end
fprintf('Log: %s\n', logFile);
fileInfo = dir(logFile);
fprintf('File size: %.2f MB\n', fileInfo.bytes / 1024^2);

if exist('ulogreader', 'file') ~= 2
    fprintf('\nulogreader is not available.\n');
    fprintf('Check MATLAB add-ons / UAV Toolbox installation and license.\n');
    fprintf('Do not rename .ulg to .mat or .csv.\n');
    return;
end

try
    logObj = ulogreader(logFile);
catch ME
    fprintf(2, 'Failed to read ULog: %s\n', ME.message);
    rethrow(ME);
end

fprintf('\n===== LOG OBJECT =====\n');
disp(logObj);

fprintf('\n===== AVAILABLE TOPICS =====\n');
topics = logObj.AvailableTopics;
disp(topics);

if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end
save(fullfile(resultDir, 'day15_step01_log_index.mat'), 'topics', 'logFile');
try
    writetable(topics, fullfile(resultDir, 'day15_step01_topics.csv'));
    fprintf('Topic list saved to CSV.\n');
catch ME
    fprintf('CSV export skipped: %s\n', ME.message);
end

fprintf('\n===== RELEVANT TOPICS =====\n');
keywords = {'sensor_combined', 'sensor_accel', 'sensor_gyro', ...
    'vehicle_imu', 'vehicle_acceleration', 'vehicle_angular_velocity', ...
    'actuator_motors'};
for k = 1:numel(keywords)
    fprintf('%-28s : ', keywords{k});
    if any(contains(string(topics{:,:}), keywords{k}))
        fprintf('FOUND\n');
    else
        fprintf('NOT FOUND\n');
    end
end
fprintf('\n===== STEP 01 COMPLETE =====\n');
