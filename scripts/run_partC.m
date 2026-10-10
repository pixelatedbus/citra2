function rows = run_partC(dataDir, outDir)
% RUN_PARTC  Batch run of part C (high-pass filtering) over every input image.
%
%   For each input image, applies IHPF, GHPF and BHPF (n = 2) at three
%   cutoffs D0, so the report can compare the filters at equal cutoff and
%   see how D0 changes what survives (small D0: edges and texture; large
%   D0: only the finest detail and noise). Part C has no reference images,
%   so MSE and PSNR are NaN. One CSV row per filter and D0, plus the
%   baseline row "input".
%
%   One figure per input, saved as <outDir>/<input>_C.png, 3 x 4 tiles:
%     columns 1-3: IHPF, GHPF, BHPF; rows: D0 = 10, 30, 60;
%                  shown as |g| normalised (highpassDisplay 'abs-normalized')
%     column 4:    input, input spectrum, and GHPF D0 = 30 shown with
%                  'rescale' (keeps the sign of g)
%
%   INPUT
%     dataDir  part folder holding input/ (text)
%     outDir   folder for the figures (text, must exist)
%
%   OUTPUT
%     rows     table in the resultRow format

D0s = [10 30 60];
n = 2;
types = {'ideal', 'gaussian', 'butterworth'};
names = {'IHPF', 'GHPF', 'BHPF'};
mode = 'abs-normalized';

rows = resultRow();
files = dir(fullfile(dataDir, 'input', '*.png'));
for k = 1:numel(files)
    inPath = fullfile(files(k).folder, files(k).name);
    f = readImageFile(inPath);
    [M, N, ~] = size(f);

    [mse, psnr] = scoreAgainstReference(f, dataDir, inPath);
    rows = [rows; resultRow('C', files(k).name, 'input', '', mse, psnr)]; %#ok<AGROW>

    tileHeight = round(400 * M / N);   % keep tiles close to the image's aspect ratio
    fig = figure('Visible', 'off', 'Position', [0 0 1600 3 * tileHeight + 120], 'Theme', 'light');
    tl = tiledlayout(fig, numel(D0s), 4, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('%s  (columns 1-3 displayed as |g| normalised)', files(k).name), ...
        'Interpreter', 'none');

    for j = 1:numel(D0s)
        for t = 1:numel(types)
            g = applyFilter(f, highpassH(M, N, types{t}, D0s(j), n));
            [mse, psnr] = scoreAgainstReference(g, dataDir, inPath);
            params = sprintf('D0=%g', D0s(j));
            if strcmp(types{t}, 'butterworth')
                params = sprintf('%s; n=%d', params, n);
            end
            rows = [rows; resultRow('C', files(k).name, names{t}, params, mse, psnr)]; %#ok<AGROW>

            nexttile(tl, (j - 1) * 4 + t);
            imshow(min(max(highpassDisplay(g, mode), 0), 1));
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
