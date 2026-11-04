
clc;
clear;

fprintf('===== DAY 14 RESULT INSPECTION =====\n\n');

projectRoot = ...
    'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';

resultDir = fullfile(projectRoot,'06_RESULTS');

assert(isfolder(resultDir), ...
    'Cannot find results directory.');

%% 1. CHECK DAY 06-13 MAT FILES

fprintf('===== MAT FILE STRUCTURES =====\n');

for day = 6:13

    pattern = sprintf('day%02d*.mat',day);
    files = dir(fullfile(resultDir,pattern));

    fprintf('\n===== DAY %02d =====\n',day);

    if isempty(files)
        fprintf('[WARNING] No MAT files found.\n');
        continue;
    end

    for k = 1:numel(files)

        fprintf('\nFILE: %s\n',files(k).name);

        filePath = fullfile(resultDir,files(k).name);

        try
            info = whos('-file',filePath);

            for j = 1:numel(info)
                fprintf('  %-32s [%s] %s\n', ...
                    info(j).name, ...
                    num2str(info(j).size), ...
                    info(j).class);
            end

        catch ME
            fprintf('[ERROR] %s\n',ME.message);
        end
    end
end

%% 2. INSPECT DAY 13 CSV FILES

fprintf('\n===== DAY 13 CSV INSPECTION =====\n');

csvFiles = dir(fullfile(resultDir,'day13*.csv'));

for k = 1:numel(csvFiles)

    filePath = fullfile(resultDir,csvFiles(k).name);

    fprintf('\nFILE: %s\n',csvFiles(k).name);

    try
        T = readtable(filePath, ...
            'VariableNamingRule','preserve');

        fprintf('Rows: %d\n',height(T));
        fprintf('Columns: %d\n',width(T));

        fprintf('Column names:\n');
        disp(T.Properties.VariableNames');

        fprintf('First rows:\n');
        disp(head(T,min(5,height(T))));

    catch ME
        fprintf('[ERROR] %s\n',ME.message);
    end
end

fprintf('\n===== DAY 14 STEP 2 INSPECTION COMPLETED =====\n');
