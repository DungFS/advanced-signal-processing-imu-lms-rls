
clc;
clear;
close all;

fprintf('===== DAY 14 FINAL VALIDATION =====\n\n');

%% 1. PROJECT PATH
projectRoot = ...
    'C:\Users\viet1\Desktop\master\XLTHSNC\MATLAB';

resultDir = fullfile(projectRoot, '06_RESULTS');

assert(isfolder(resultDir), ...
    'Cannot find 06_RESULTS directory.');

%% 2. REQUIRED DATA FILES
requiredFiles = {
    'day02_imu_data.mat'
    'day04_lms_results.mat'
    'day05_rls_results.mat'
    'day06_comparison_results.mat'
    'day07_frequency_results.mat'
    'day08_evaluation_results.mat'
};

fprintf('===== REQUIRED FILE CHECK =====\n');

missingFiles = {};

for k = 1:numel(requiredFiles)
    filePath = fullfile(resultDir, requiredFiles{k});

    if isfile(filePath)
        try
            info = whos('-file', filePath);
            fprintf('[OK] %s (%d variables)\n', ...
                requiredFiles{k}, numel(info));
        catch ME
            fprintf('[ERROR] %s: %s\n', ...
                requiredFiles{k}, ME.message);
            missingFiles{end+1} = requiredFiles{k};
        end
    else
        fprintf('[MISSING] %s\n', requiredFiles{k});
        missingFiles{end+1} = requiredFiles{k};
    end
end

%% 3. INVENTORY ALL RESULTS
matFiles = dir(fullfile(resultDir, '*.mat'));
csvFiles = dir(fullfile(resultDir, '*.csv'));

fprintf('\n===== FILE INVENTORY =====\n');
fprintf('MAT files: %d\n', numel(matFiles));
fprintf('CSV files: %d\n', numel(csvFiles));

%% 4. VERIFY SIMULATION DATA
dataPath = fullfile(resultDir, ...
    'day02_imu_data.mat');

if isfile(dataPath)
    D = load(dataPath);

    requiredVars = {'Fs','N','t','s','d'};

    for k = 1:numel(requiredVars)
        assert(isfield(D,requiredVars{k}), ...
            'Missing variable: %s', requiredVars{k});
    end

    Fs = D.Fs;
    N = D.N;

    assert(isnumeric(Fs) && isscalar(Fs) && Fs > 0, ...
        'Invalid sampling frequency.');

    assert(isnumeric(N) && isscalar(N) && N > 1, ...
        'Invalid sample count.');

    assert(numel(D.t) == N && ...
           numel(D.s) == N && ...
           numel(D.d) == N, ...
           'Signal length mismatch.');

    assert(all(isfinite(D.t(:))) && ...
           all(isfinite(D.s(:))) && ...
           all(isfinite(D.d(:))), ...
           'Signals contain NaN or Inf.');

    dt = diff(D.t(:));
    expectedDt = 1/Fs;

    maxDtError = max(abs(dt-expectedDt));

    fprintf('\n===== SIGNAL VALIDATION =====\n');
    fprintf('Fs: %.2f Hz\n', Fs);
    fprintf('N: %d\n', N);
    fprintf('Nyquist: %.2f Hz\n', Fs/2);
    fprintf('Max dt error: %.3e s\n', maxDtError);

    if maxDtError < 1e-9
        fprintf('[OK] Uniform sampling\n');
    else
        fprintf('[WARNING] Sampling interval mismatch\n');
    end

    if isfield(D,'v')
        relationError = max(abs( ...
            D.d(:)-D.s(:)-D.v(:)));

        fprintf('Signal relation error: %.3e\n', ...
            relationError);
    end
end

%% 5. SAVE FILE INVENTORY
names = [{matFiles.name}'; {csvFiles.name}'];
types = [repmat({'MAT'},numel(matFiles),1); ...
         repmat({'CSV'},numel(csvFiles),1)];

inventoryTable = table(names,types, ...
    'VariableNames',{'FileName','FileType'});

writetable(inventoryTable, ...
    fullfile(resultDir,'day14_file_inventory.csv'));

%% 6. FINAL STATUS
fprintf('\n===== FINAL STATUS =====\n');

if isempty(missingFiles)
    fprintf('[PASS] Required files available\n');
else
    fprintf('[CHECK] %d required files missing/unreadable\n', ...
        numel(missingFiles));
end

fprintf('File inventory saved.\n');
fprintf('===== DAY 14 STEP 1 COMPLETED =====\n');
