function varargout = run_tests(testDir, logDir)
% RUN_TESTS  Run every test and write a report to tests/log.
%
%   The one way to run the test suite. It runs all test_*.m files, prints
%   a short report and saves it as tests/log/test_report_<date>_<time>.txt,
%   so every run leaves a record tied to the code version it tested.
%
%   It also catches a trap of runtests: a test file with a syntax error is
%   skipped with only a warning, and the run still looks green. Here, every
%   test_*.m file on disk must produce results, or the run is a FAIL and
%   the file is listed under "Files that did not run".
%
%   The report has: date, MATLAB version, git commit (and whether there
%   are uncommitted changes), PASS/FAIL, counts, one line per test file,
%   and the full diagnostic of every failed test. The function ends with
%   an error when the run fails, so `matlab -batch` exits non-zero.
%
%   Usage from the project root:
%       matlab -batch "addpath('scripts'); run_tests"
%
%   INPUT
%     testDir  optional, folder with the test_*.m files (default: tests/
%              in the project root)
%     logDir   optional, folder for the report (default: tests/log/);
%              created if missing
%
%   OUTPUT
%     results  optional, matlab.unittest.TestResult array of the run
%              (not printed when the function is called without output)

projectRoot = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1
    testDir = fullfile(projectRoot, 'tests');
end
if nargin < 2
    logDir = fullfile(testDir, 'log');
end
addpath(genpath(fullfile(projectRoot, 'src')));

% Run
onDisk = dir(fullfile(testDir, 'test_*.m'));
onDisk = sort(erase({onDisk.name}, '.m'));
startTime = datetime('now');
results = runtests(testDir);

% Which files produced results, and which silently did not
names = string({results.Name});
fileOfTest = extractBefore(names + "/", "/");
ran = unique(fileOfTest);
notRun = setdiff(onDisk, ran);

nFailed = nnz([results.Failed]);
nIncomplete = nnz([results.Incomplete]);
passed = nFailed == 0 && nIncomplete == 0 && isempty(notRun) && ~isempty(results);

% Report text
lines = {
    'Test report - IF4073 Tugas 2'
    sprintf('Date:     %s', char(startTime, 'yyyy-MM-dd HH:mm:ss'))
    sprintf('MATLAB:   %s', version)
    sprintf('Commit:   %s', gitState(projectRoot))
    sprintf('Result:   %s', ternary(passed, 'PASS', 'FAIL'))
    sprintf('Summary:  %d run, %d passed, %d failed, %d incomplete; %d of %d test files ran; %.1f s', ...
        numel(results), nnz([results.Passed]), nFailed, nIncomplete, ...
        numel(ran), numel(onDisk), sum([results.Duration]))
    ''
    'Per file:'
    };
for f = ran
    inFile = fileOfTest == f;
    lines{end+1, 1} = sprintf('  %-26s %3d/%-3d passed  %6.2f s', f, ...
        nnz([results(inFile).Passed]), nnz(inFile), sum([results(inFile).Duration])); %#ok<AGROW>
end

lines{end+1, 1} = '';
if isempty(notRun)
    lines{end+1, 1} = 'Files that did not run: none';
else
    lines{end+1, 1} = 'Files that did not run (syntax error or no tests?):';
    lines = [lines; strcat({'  '}, notRun(:))];
end

failed = results([results.Failed] | [results.Incomplete]);
lines{end+1, 1} = '';
if isempty(failed)
    lines{end+1, 1} = 'Failures: none';
else
    lines{end+1, 1} = 'Failures:';
    for r = failed
        lines{end+1, 1} = ['  ' r.Name]; %#ok<AGROW>
        for d = r.Details.DiagnosticRecord
            lines{end+1, 1} = indent(d.Report); %#ok<AGROW>
        end
    end
end
report = strjoin(lines, newline);

% Save and show
if ~isfolder(logDir)
    mkdir(logDir);
end
logFile = fullfile(logDir, ['test_report_' char(startTime, 'yyyy-MM-dd_HHmmss') '.txt']);
fid = fopen(logFile, 'w');
fprintf(fid, '%s\n', report);
fclose(fid);

fprintf('\n%s\n\nReport saved to %s\n', report, logFile);
if nargout > 0
    varargout{1} = results;
end
if ~passed
    error('run_tests:failed', 'Test run FAILED. See %s', logFile);
end
end

function s = gitState(projectRoot)
% Short commit hash, plus a note when the working tree has changes.
[status, hash] = system(sprintf('git -C "%s" rev-parse --short HEAD', projectRoot));
if status ~= 0
    s = 'unknown (not a git repository?)';
    return;
end
[~, changes] = system(sprintf('git -C "%s" status --porcelain', projectRoot));
s = strtrim(hash);
if ~isempty(strtrim(changes))
    s = [s ' + uncommitted changes'];
end
end

function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end

function out = indent(text)
% Indent every line of a diagnostic by four spaces.
out = ['    ' strrep(strtrim(char(text)), newline, [newline '    '])];
end
