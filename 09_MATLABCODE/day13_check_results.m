
clc;
clear;
close all;

%% DAY 13 - CHECK RESULT FILES

projectDir = ...
    'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';

resultDir = fullfile(projectDir, '06_RESULTS');

if ~isfolder(resultDir)
    error('Result folder does not exist.');
end

fprintf('===== DAY 13 FILE CHECK =====\n');

files = dir(fullfile(resultDir, '*.mat'));

fprintf('Total MAT files: %d\n\n', numel(files));

for k = 1:numel(files)
    filePath = fullfile(resultDir, files(k).name);

    fprintf('FILE %02d: %s\n', k, files(k).name);

    info = whos('-file', filePath);

    for j = 1:numel(info)
        fprintf('   %-25s %s\n', ...
            info(j).name, mat2str(info(j).size));
    end

    fprintf('\n');
end

fprintf('===== DAY 13 CHECK COMPLETED =====\n');
