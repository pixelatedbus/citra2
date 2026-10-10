function rows = run_partE(dataDir, outDir)
% Part E batch: notch shape x radius sweep at the analysed spike positions, plus brick/hubble/rocket comparisons.
shapes = {'ideal', 'gaussian', 'butterworth'};
radii = [1 2 3 5 8];
n = 2;

rows = resultRow();
files = dir(fullfile(dataDir, 'input', '*.png'));
for k = 1:numel(files)
    name = files(k).name;
    inPath = fullfile(files(k).folder, name);
    f = readImageFile(inPath);
    [mse, psnr] = scoreAgainstReference(f, dataDir, inPath);
    rows = [rows; resultRow('E', name, 'input', '', mse, psnr)];

    spec = knownSpikes(name);
    if isempty(spec)
        fprintf('  %s: no analysed spike positions, baseline row only\n', name);
        continue;
    end
    for s = 1:numel(shapes)
        for r = radii
            rows = [rows; scoreConfig(f, notchConfig(spec.spikes, shapes{s}, r, n, ''), dataDir, inPath, name)];
        end
    end

    main = notchConfig(spec.spikes, 'gaussian', spec.radius, n, '');
    saveMainFigure(f, main, dataDir, inPath, fullfile(outDir, [erase(name, '.png') '_E.png']));

    compare = comparisonConfigs(spec, n);
    for c = 1:numel(compare)
        if compare(c).extraRow
            rows = [rows; scoreConfig(f, compare(c), dataDir, inPath, name)];
        end
    end
    if ~isempty(compare)
        saveCompareFigure(f, compare, dataDir, inPath, fullfile(outDir, [erase(name, '.png') '_E_compare.png']));
    end
end
end

function spec = knownSpikes(fileName)
known = struct('prefix', {'brick_gray', 'grass_gray', 'hubble_color', 'rocket_color'}, ...
    'spikes', {[15.21 -35.98], [20.43 25.72], [0 38.26; 0 76.5; 0 114.8], [32 0]}, ...
    'radius', {5, 5, 5, 1});
spec = [];
for s = known
    if startsWith(fileName, [s.prefix '_'])
        spec = s;
    end
end
end

function cfg = notchConfig(spikes, shape, r, n, suffix)
spots = arrayfun(@(k) sprintf('(%g,%g)', spikes(k, :)), 1:size(spikes, 1), 'UniformOutput', false);
cfg = struct('filter', 'notch', 'shape', shape, 'notches', [spikes, r * ones(size(spikes, 1), 1)], ...
    'n', n, 'D0', NaN, 'W', NaN, 'method', ['notch-' shape suffix], ...
    'params', sprintf('notches=%s; r=%g', strjoin(spots, ''), r), 'extraRow', false);
if strcmp(shape, 'butterworth')
    cfg.params = sprintf('%s; n=%d', cfg.params, n);
end
end

function cfg = bandConfig(shape, D0, W, n)
cfg = struct('filter', 'band', 'shape', shape, 'notches', zeros(0, 3), 'n', n, 'D0', D0, 'W', W, ...
    'method', ['band-' shape], 'params', sprintf('D0=%g; W=%g', D0, W), 'extraRow', true);
if strcmp(shape, 'butterworth')
    cfg.params = sprintf('%s; n=%d', cfg.params, n);
end
end

function list = comparisonConfigs(spec, n)
switch spec.prefix
    case 'brick_gray'
        list = [notchConfig(spec.spikes, 'gaussian', 1, n, '')
                notchConfig(spec.spikes, 'gaussian', 5, n, '')
                notchConfig(spec.spikes, 'gaussian', 8, n, '')];
    case 'hubble_color'
        first = notchConfig(spec.spikes(1, :), 'gaussian', 5, n, '-fundamental-only');
        first.extraRow = true;
        list = [first; notchConfig(spec.spikes, 'gaussian', 5, n, '')];
    case 'rocket_color'
        D0 = hypot(spec.spikes(1, 1), spec.spikes(1, 2));
        list = [notchConfig(spec.spikes, 'gaussian', 1, n, '')
                bandConfig('ideal', D0, 4, n)
                bandConfig('butterworth', D0, 4, n)
                bandConfig('gaussian', D0, 4, n)];
    otherwise
        list = [];
end
end

function [g, H, G, F] = runConfig(f, cfg)
[M, N, ~] = size(f);
if strcmp(cfg.filter, 'notch')
    H = notchRejectH(M, N, cfg.shape, cfg.notches, cfg.n);
else
    H = bandrejectH(M, N, cfg.shape, cfg.D0, cfg.W, cfg.n);
end
[g, G, F] = applyFilter(f, H);
end

function row = scoreConfig(f, cfg, dataDir, inPath, name)
[mse, psnr] = scoreAgainstReference(runConfig(f, cfg), dataDir, inPath);
row = resultRow('E', name, cfg.method, cfg.params, mse, psnr);
end

function saveMainFigure(f, cfg, dataDir, inPath, outFile)
[g, H, G, F] = runConfig(f, cfg);
[~, before] = scoreAgainstReference(f, dataDir, inPath);
[~, after] = scoreAgainstReference(g, dataDir, inPath);
[~, inName, ext] = fileparts(inPath);

fig = figure('Visible', 'off', 'Position', [0 0 1500 950], 'Theme', 'light');
tl = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('%s%s  |  %s, %s', inName, ext, cfg.method, cfg.params), 'Interpreter', 'none');
nexttile(tl); imshow(f); title(sprintf('Degraded (%.2f dB)', before));
nexttile(tl); imshow(spectrumImage(F)); title('Spectrum before');
nexttile(tl); showMask(H, 'Mask H(u,v)');
nexttile(tl); imshow(spectrumImage(G)); title('Spectrum after');
nexttile(tl); imshow(min(max(g, 0), 1)); title(sprintf('Restored (%.2f dB)', after));
nexttile(tl);
refPath = findReference(dataDir, inPath);
if isempty(refPath)
    axis off;
else
    imshow(readImageFile(refPath)); title('Reference');
end
exportgraphics(fig, outFile, 'Resolution', 110);
close(fig);
end

function saveCompareFigure(f, list, dataDir, inPath, outFile)
K = numel(list);
[M, N, ~] = size(f);
tileHeight = round(420 * M / N);
fig = figure('Visible', 'off', 'Position', [0 0 420 * K 2 * tileHeight + 260], 'Theme', 'light');
tl = tiledlayout(fig, 2, K, 'TileSpacing', 'compact', 'Padding', 'compact');
[~, inName, ext] = fileparts(inPath);
heading = repmat({' '}, 1, K);
heading{1} = [inName ext ': filter comparison'];
for c = 1:K
    [g, H] = runConfig(f, list(c));
    [~, p] = scoreAgainstReference(g, dataDir, inPath);
    nexttile(tl, c);
    imshow(min(max(g, 0), 1));
    title({heading{c}, list(c).method, sprintf('%s  (%.2f dB)', list(c).params, p)}, 'Interpreter', 'none');
    nexttile(tl, K + c);
    showMask(H, 'Mask');
end
exportgraphics(fig, outFile, 'Resolution', 100);
close(fig);
end

function showMask(H, titleText)
imshow(H);
axis on;
set(gca, 'XTick', [], 'YTick', [], 'Box', 'on');
title(titleText);
end
