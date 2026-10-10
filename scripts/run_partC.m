function rows = run_partC(dataDir, outDir)
% Part C batch: IHPF, GHPF and BHPF at D0 = 10, 30, 60 for every input (no reference, so no PSNR).
D0s = [10 30 60];
n = 2;
types = {'ideal', 'gaussian', 'butterworth'};
names = {'IHPF', 'GHPF', 'BHPF'};

rows = resultRow();
files = dir(fullfile(dataDir, 'input', '*.png'));
for k = 1:numel(files)
    inPath = fullfile(files(k).folder, files(k).name);
    f = readImageFile(inPath);
    [M, N, ~] = size(f);
    [mse, psnr] = scoreAgainstReference(f, dataDir, inPath);
    rows = [rows; resultRow('C', files(k).name, 'input', '', mse, psnr)];

    tileHeight = round(400 * M / N);
    fig = figure('Visible', 'off', 'Position', [0 0 1600 3 * tileHeight + 120], 'Theme', 'light');
    tl = tiledlayout(fig, numel(D0s), 4, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('%s  (columns 1-3 displayed as |g| normalised)', files(k).name), 'Interpreter', 'none');
    for j = 1:numel(D0s)
        for t = 1:numel(types)
            g = applyFilter(f, highpassH(M, N, types{t}, D0s(j), n));
            [mse, psnr] = scoreAgainstReference(g, dataDir, inPath);
            params = sprintf('D0=%g', D0s(j));
            if strcmp(types{t}, 'butterworth')
                params = sprintf('%s; n=%d', params, n);
            end
            rows = [rows; resultRow('C', files(k).name, names{t}, params, mse, psnr)];
            nexttile(tl, (j - 1) * 4 + t);
            imshow(min(max(highpassDisplay(g, 'abs-normalized'), 0), 1));
            title(sprintf('%s, %s', names{t}, strrep(params, ';', ',')));
        end
    end
    [~, ~, F] = applyFilter(f, ones(M, N));
    nexttile(tl, 4);  imshow(f); title('Input');
    nexttile(tl, 8);  imshow(spectrumImage(F)); title('Input spectrum');
    g = applyFilter(f, highpassH(M, N, 'gaussian', 30, n));
    nexttile(tl, 12); imshow(highpassDisplay(g, 'rescale')); title('GHPF, D0=30, rescale');
    exportgraphics(fig, fullfile(outDir, [erase(files(k).name, '.png') '_C.png']), 'Resolution', 120);
    close(fig);
end
end
