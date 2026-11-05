
%% DAY 13 - CHECK ADVANCED RESULTS

clc;
clear;

projectDir = ...
    fileparts(fileparts(fileparts(mfilename('fullpath'))));

resultDir = fullfile(projectDir,'results', 'simulation');

fprintf('===== DAY 13 ADVANCED DATA CHECK =====\n\n');

for day = 7:12

    pattern = sprintf('day%02d*.mat',day);

    files = dir(fullfile(resultDir,pattern));

    fprintf('===== DAY %02d =====\n',day);

    if isempty(files)
        fprintf('No MAT files found.\n\n');
        continue;
    end

    for k = 1:numel(files)

        fprintf('\nFILE: %s\n',files(k).name);

        filePath = fullfile(resultDir,files(k).name);

        info = whos('-file',filePath);

        for j = 1:numel(info)
            fprintf('  %-30s %s\n', ...
                info(j).name, ...
                mat2str(info(j).size));
        end
    end

    fprintf('\n');
end

fprintf('===== ADVANCED CHECK COMPLETED =====\n');
