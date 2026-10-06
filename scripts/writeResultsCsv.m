function allRows = writeResultsCsv(rows, csvPath, partsRun)
% WRITERESULTSCSV  Merge new result rows into the results CSV.
%
%   Running only some parts (e.g. run_all('BE')) must not wipe the other
%   member's rows. So the existing CSV is read, its rows for the parts that
%   were just run are dropped, the new rows are added, and the result is
%   sorted by part, image and method and written back. Inf (identical to
%   the reference) and NaN (no reference) survive the round trip.
%
%   INPUT
%     rows      new rows, table in the resultRow format
%     csvPath   path of the CSV, e.g. results/params.csv (text)
%     partsRun  part letters that were just run, e.g. 'BE' (text)
%
%   OUTPUT
%     allRows   the full table that was written

allRows = rows;
if isfile(csvPath)
    old = readResults(csvPath);
    keep = ~ismember(old.part, string(num2cell(char(partsRun))));
    allRows = [old(keep, :); rows];
end
allRows = sortrows(allRows, {'part', 'image', 'method'});
writetable(allRows, csvPath);
end

function T = readResults(csvPath)
% Read the CSV back with the exact resultRow types.
opts = detectImportOptions(csvPath);
textCols = {'part', 'image', 'method', 'params'};
opts = setvartype(opts, textCols, 'string');
opts = setvaropts(opts, textCols, 'FillValue', "");
opts = setvartype(opts, {'mse', 'psnr'}, 'double');
T = readtable(csvPath, opts);
end
