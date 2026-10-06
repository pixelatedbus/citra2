function varargout = run_all(parts, dataRoot, resultsRoot)
% RUN_ALL  Process every input image of the chosen parts and write results/params.csv.
%
%   For each part letter X it finds the data folder data/X_*/, calls
%   run_partX(dataDir, outDir) with outDir = results/X/, and stacks the
%   returned rows. The rows are merged into results/params.csv: rows of the
%   parts that were run are replaced, rows of other parts are kept. So each
%   member can run only their own parts. Report tables come from that CSV.
%
%   Usage from the project root:
%       matlab -batch "addpath('scripts'); run_all"         all parts
%       matlab -batch "addpath('scripts'); run_all('BCE')"  only B, C, E
%
%   INPUT
%     parts        optional, part letters to run (text, default 'BCDEF')
%     dataRoot     optional, folder holding the X_* data folders
%                  (default: data/ in the project root)
%     resultsRoot  optional, output folder (default: results/ in the project root)
%
%   OUTPUT
%     rows         optional, table of all rows written to the CSV
%                  (not printed when called without output)

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    parts = 'BCDEF';
end
if nargin < 2
    dataRoot = fullfile(projectRoot, 'data');
end
if nargin < 3
    resultsRoot = fullfile(projectRoot, 'results');
end
addpath(genpath(fullfile(projectRoot, 'src')));

parts = upper(char(parts));
rows = resultRow();
for p = parts
    folder = dir(fullfile(dataRoot, [p '_*']));
    folder = folder([folder.isdir]);
    if isempty(folder)
        error('run_all:noData', 'No data folder %s_* in %s.', p, dataRoot);
    end
    dataDir = fullfile(dataRoot, folder(1).name);
    outDir = fullfile(resultsRoot, p);
    if ~isfolder(outDir)
        mkdir(outDir);
    end

    fprintf('Part %s: %s\n', p, folder(1).name);
    partRows = feval(['run_part' p], dataDir, outDir);
    if ~isequal(partRows.Properties.VariableNames, rows.Properties.VariableNames)
        error('run_all:badRows', 'run_part%s must return a table made with resultRow.', p);
    end
    fprintf('  %d rows\n', height(partRows));
    rows = [rows; partRows]; %#ok<AGROW>
end

csvPath = fullfile(resultsRoot, 'params.csv');
allRows = writeResultsCsv(rows, csvPath, parts);
fprintf('Wrote %d rows (%d from this run) to %s\n', height(allRows), height(rows), csvPath);

if nargout > 0
    varargout{1} = allRows;
end
end
