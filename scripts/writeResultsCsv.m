function allRows = writeResultsCsv(rows, csvPath, partsRun)
% Writes rows to the CSV, replacing only the rows of the parts that were just run.
allRows = rows;
if isfile(csvPath)
    opts = detectImportOptions(csvPath);
    textCols = {'part', 'image', 'method', 'params'};
    opts = setvartype(opts, textCols, 'string');
    opts = setvaropts(opts, textCols, 'FillValue', "");
    opts = setvartype(opts, {'mse', 'psnr'}, 'double');
    old = readtable(csvPath, opts);
    keep = ~ismember(old.part, string(num2cell(char(partsRun))));
    allRows = [old(keep, :); rows];
end
allRows = sortrows(allRows, {'part', 'image', 'method'});
writetable(allRows, csvPath);
end
