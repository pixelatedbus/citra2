function rows = run_partC(dataDir, outDir) %#ok<INUSD>
% RUN_PARTC  Batch run of part C (high-pass filtering) over every input image.
%
%   PLACEHOLDER from the shared foundation; owner: Member 1, who adds the real
%   processing: one row per method / parameter set via resultRow, scores via
%   scoreAgainstReference, and figures saved to outDir.
%   For now every input gets one baseline row, method "input": the
%   unprocessed input scored against its reference. Keep that row, since the
%   report compares results with the score before processing.
%
%   INPUT
%     dataDir  part folder holding input/ (and reference/ if any), text
%     outDir   folder for this part's figures, text (exists already)
%
%   OUTPUT
%     rows     table in the resultRow format, one or more rows per input

rows = resultRow();
files = dir(fullfile(dataDir, 'input', '*.png'));
for k = 1:numel(files)
    inPath = fullfile(files(k).folder, files(k).name);
    f = readImageFile(inPath);
    [mse, psnr] = scoreAgainstReference(f, dataDir, inPath);
    rows = [rows; resultRow('C', files(k).name, 'input', '', mse, psnr)]; %#ok<AGROW>
end
end
