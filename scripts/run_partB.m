function rows = run_partB(dataDir, outDir)
% RUN_PARTB  Batch run of part B (low-pass smoothing) over every input image.
%
%   For each input image, applies ILPF, GLPF and BLPF (n = 2) for a sweep
%   of cutoffs D0 and scores every result against the reference (PSNR,
%   MSE). Writes one CSV row per filter and D0, plus the baseline row
%   "input" (the noisy input itself), so the report can show how much each
%   filter gains and which D0 works best.
%
%   One figure per input, saved as <outDir>/<input>_B.png:
%     row 1: input, reference, input spectrum, PSNR vs D0 for the 3 types
%     row 2: ILPF, GLPF, BLPF results at the same D0 (the D0 where GLPF
%            scores best), so ringing and sharpness compare at equal cutoff
%
%   INPUT
%     dataDir  part folder holding input/ and reference/ (text)
%     outDir   folder for the figures (text, must exist)
%
%   OUTPUT
%     rows     table in the resultRow format

D0s = [10 20 30 40 60 80 100 120 160 200 240 280];
n = 2;
types = {'ideal', 'gaussian', 'butterworth'};
names = {'ILPF', 'GLPF', 'BLPF'};

rows = resultRow();
files = dir(fullfile(dataDir, 'input', '*.png'));
for k = 1:numel(files)
    inPath = fullfile(files(k).folder, files(k).name);
    f = readImageFile(inPath);
    [M, N, ~] = size(f);

    [mse, psnr] = scoreAgainstReference(f, dataDir, inPath);
    rows = [rows; resultRow('B', files(k).name, 'input', '', mse, psnr)]; %#ok<AGROW>

    psnrTable = NaN(numel(types), numel(D0s));   % type x D0
    for t = 1:numel(types)
        for j = 1:numel(D0s)
            g = applyFilter(f, lowpassH(M, N, types{t}, D0s(j), n));
            [mse, psnr] = scoreAgainstReference(g, dataDir, inPath);
            psnrTable(t, j) = psnr;
            params = sprintf('D0=%g', D0s(j));
            if strcmp(types{t}, 'butterworth')
                params = sprintf('%s; n=%d', params, n);
            end
            rows = [rows; resultRow('B', files(k).name, names{t}, params, mse, psnr)]; %#ok<AGROW>
        end
    end

    saveFigure(f, dataDir, inPath, D0s, psnrTable, types, names, n, ...
        fullfile(outDir, [erase(files(k).name, '.png') '_B.png']));
end
end

function saveFigure(f, dataDir, inPath, D0s, psnrTable, types, names, n, outFile)
% Input / reference / spectrum / PSNR curve, then the three filters at one D0.
[M, N, ~] = size(f);
[~, bestJ] = max(psnrTable(2, :));      % D0 where GLPF is best
if isnan(psnrTable(2, bestJ))
    bestJ = find(D0s == 40, 1);         % no reference: fall back to D0 = 40
end
D0 = D0s(bestJ);

fig = figure('Visible', 'off', 'Position', [0 0 1600 800], 'Theme', 'light');   % white background for the report
tiledlayout(fig, 2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
[~, inName, ext] = fileparts(inPath);

nexttile; imshow(min(max(f, 0), 1)); title(['Input: ' inName ext], 'Interpreter', 'none');
nexttile;
refPath = findReference(dataDir, inPath);
if ~isempty(refPath)
    imshow(readImageFile(refPath)); title('Reference');
else
    axis off; title('No reference');
end
[~, ~, F] = applyFilter(f, ones(M, N));
nexttile; imshow(spectrumImage(F)); title('Input spectrum');
nexttile; plot(D0s, psnrTable', '-o'); grid on;
xlabel('D0'); ylabel('PSNR (dB)'); legend(names, 'Location', 'best');
title('PSNR vs D0');

for t = 1:numel(types)
    g = applyFilter(f, lowpassH(M, N, types{t}, D0, n));
    nexttile; imshow(min(max(g, 0), 1));
    label = sprintf('%s, D0 = %g', names{t}, D0);
    if strcmp(types{t}, 'butterworth')
        label = sprintf('%s, n = %d', label, n);
    end
    title(sprintf('%s (%.2f dB)', label, psnrTable(t, bestJ)));
end

exportgraphics(fig, outFile, 'Resolution', 120);
close(fig);
end
