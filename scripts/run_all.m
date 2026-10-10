function varargout = run_all(parts, dataRoot, resultsRoot)
% Runs run_partX for the chosen parts (default 'BCDEF') and merges their rows into results/params.csv.
projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1, parts = 'BCDEF'; end
if nargin < 2, dataRoot = fullfile(projectRoot, 'data'); end
if nargin < 3, resultsRoot = fullfile(projectRoot, 'results'); end
addpath(genpath(fullfile(projectRoot, 'src')));

parts = upper(char(parts));
rows = resultRow();
for p = parts
    folder = dir(fullfile(dataRoot, [p '_*']));
    folder = folder([folder.isdir]);
    if isempty(folder)
        error('run_all:noData', 'No data folder %s_* in %s.', p, dataRoot);
    end
    outDir = fullfile(resultsRoot, p);
    if ~isfolder(outDir)
        mkdir(outDir);
    end
    fprintf('Part %s: %s\n', p, folder(1).name);
    partRows = feval(['run_part' p], fullfile(dataRoot, folder(1).name), outDir);
    if ~isequal(partRows.Properties.VariableNames, rows.Properties.VariableNames)
        error('run_all:badRows', 'run_part%s must return a table made with resultRow.', p);
    end
    fprintf('  %d rows\n', height(partRows));
    rows = [rows; partRows];
end

csvPath = fullfile(resultsRoot, 'params.csv');
allRows = writeResultsCsv(rows, csvPath, parts);
fprintf('Wrote %d rows (%d from this run) to %s\n', height(allRows), height(rows), csvPath);
if nargout > 0
    varargout{1} = allRows;
end
end
