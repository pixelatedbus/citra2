function rows = run_partB(dataDir, outDir)
% Part B batch: ILPF, GLPF and BLPF over a range of D0 for every input, scored against the reference.
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
    rows = [rows; resultRow('B', files(k).name, 'input', '', mse, psnr)];

    psnrTable = NaN(numel(types), numel(D0s));
    for t = 1:numel(types)
        for j = 1:numel(D0s)
            g = applyFilter(f, lowpassH(M, N, types{t}, D0s(j), n));
            [mse, psnrTable(t, j)] = scoreAgainstReference(g, dataDir, inPath);
            params = sprintf('D0=%g', D0s(j));
            if strcmp(types{t}, 'butterworth')
                params = sprintf('%s; n=%d', params, n);
            end
            rows = [rows; resultRow('B', files(k).name, names{t}, params, mse, psnrTable(t, j))];
        end
    end
    saveFigure(f, dataDir, inPath, D0s, psnrTable, types, names, n, ...
        fullfile(outDir, [erase(files(k).name, '.png') '_B.png']));
end
end

function saveFigure(f, dataDir, inPath, D0s, psnrTable, types, names, n, outFile)
[M, N, ~] = size(f);
[~, best] = max(psnrTable(2, :));
if isnan(psnrTable(2, best))
    best = find(D0s == 40, 1);
end
D0 = D0s(best);
[~, inName, ext] = fileparts(inPath);

fig = figure('Visible', 'off', 'Position', [0 0 1600 800], 'Theme', 'light');
tiledlayout(fig, 2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(min(max(f, 0), 1)); title(['Input: ' inName ext], 'Interpreter', 'none');
nexttile;
refPath = findReference(dataDir, inPath);
if isempty(refPath)
    axis off; title('No reference');
else
    imshow(readImageFile(refPath)); title('Reference');
end
[~, ~, F] = applyFilter(f, ones(M, N));
nexttile; imshow(spectrumImage(F)); title('Input spectrum');
nexttile; plot(D0s, psnrTable', '-o'); grid on;
xlabel('D0'); ylabel('PSNR (dB)'); legend(names, 'Location', 'best'); title('PSNR vs D0');
for t = 1:numel(types)
    g = applyFilter(f, lowpassH(M, N, types{t}, D0, n));
    label = sprintf('%s, D0 = %g', names{t}, D0);
    if strcmp(types{t}, 'butterworth')
        label = sprintf('%s, n = %d', label, n);
    end
    nexttile; imshow(min(max(g, 0), 1)); title(sprintf('%s (%.2f dB)', label, psnrTable(t, best)));
end
exportgraphics(fig, outFile, 'Resolution', 120);
close(fig);
end
