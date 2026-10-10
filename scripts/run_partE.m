function rows = run_partE(dataDir, outDir)
% RUN_PARTE  Batch run of part E (periodic noise restoration) over every input image.
%
%   The noise spike positions come from the spectrum analysis of each
%   official input (our spectrum analysis, summarised in knownSpikes below): spikes
%   found in |F_noisy| and confirmed with F_noisy - F_ref. For each image:
%     - a sweep of notch reject filters over the shape (ideal, gaussian,
%       butterworth n = 2) and the notch radius (1, 2, 3, 5): one CSV row
%       each, so the report can justify the chosen parameters with PSNR;
%     - extra comparisons where they teach something (the spec asks for at
%       least one image with two filters or parameter sets compared):
%         brick:  notch radius 1 vs 5 vs 8 (too small, best, too large)
%         hubble: fundamental only vs with its 2nd and 3rd harmonics
%         rocket: notch vs bandreject rings (ideal, butterworth, gaussian)
%   Figures, in outDir:
%     <input>_E.png          the 5 required views for the main filter
%                            (degraded, spectrum before, mask, spectrum
%                            after, restored) plus the reference
%     <input>_E_compare.png  restored image and mask of each compared filter
%   Inputs that are not one of the four official images get only the
%   baseline row "input" (their spikes have not been analysed).
%
%   INPUT
%     dataDir  part folder holding input/ and reference/ (text)
%     outDir   folder for the figures (text, must exist)
%
%   OUTPUT
%     rows     table in the resultRow format

shapes = {'ideal', 'gaussian', 'butterworth'};
radii = [1 2 3 5 8];
n = 2;

rows = resultRow();
files = dir(fullfile(dataDir, 'input', '*.png'));
for k = 1:numel(files)
    inPath = fullfile(files(k).folder, files(k).name);
    name = files(k).name;
    f = readImageFile(inPath);
    [M, N, ~] = size(f);

    [mse, psnr] = scoreAgainstReference(f, dataDir, inPath);
    rows = [rows; resultRow('E', name, 'input', '', mse, psnr)]; %#ok<AGROW>

    spec = knownSpikes(name);
    if isempty(spec)
        fprintf('  %s: no analysed spike positions, baseline row only\n', name);
        continue;
    end

    % Sweep: shape x radius, all spikes of this image
    for s = 1:numel(shapes)
        for r = radii
            cfg = notchConfig(spec.spikes, shapes{s}, r, n, '');
            rows = [rows; scoreConfig(f, cfg, dataDir, inPath, name)]; %#ok<AGROW>
        end
    end

    % Main filter: 5 required views
    main = notchConfig(spec.spikes, 'gaussian', spec.radius, n, '');
    saveMainFigure(f, main, dataDir, inPath, fullfile(outDir, [erase(name, '.png') '_E.png']));

    % Extra comparisons (rows for the ones the sweep does not already cover)
    compare = comparisonConfigs(spec, n, M, N);
    for c = 1:numel(compare)
        if compare(c).extraRow
            rows = [rows; scoreConfig(f, compare(c), dataDir, inPath, name)]; %#ok<AGROW>
        end
    end
    if ~isempty(compare)
        saveCompareFigure(f, compare, dataDir, inPath, ...
            fullfile(outDir, [erase(name, '.png') '_E_compare.png']));
    end
end
end

% ---------------------------------------------------------------------------
function spec = knownSpikes(fileName)
% Spike positions (du, dv) per official input, from the E0 spectrum analysis.
% Only one spike of each mirror pair is listed; notchRejectH adds the mirror.
%   brick:  one oblique sinusoid between samples, centroid (15.21, -35.98),
%           period 13.1 px; energy leaks to neighbours -> radius 5
%   grass:  one oblique sinusoid between samples, centroid (20.43, 25.72),
%           period 15.6 px -> radius 5
%   hubble: vertical stripes clipped at 0 on the dark sky -> fundamental
%           (0, 38.26) plus harmonics (0, 76.5) and (0, 114.8) -> radius 5
%   rocket: horizontal stripes exactly on a sample, (32, 0), 99.2 % of the
%           noise energy in this pair, on-grid -> radius 1
% Radius: the E0 energy table (a larger radius catches more leaked noise
% energy at a tiny cost in image energy) and the PSNR sweep here agree: the
% Gaussian notch peaks at r = 5 for the off-grid spikes (r = 8 is worse) and
% at r = 1 for the on-grid rocket spike.
table = struct( ...
    'prefix', {'brick_gray', 'grass_gray', 'hubble_color', 'rocket_color'}, ...
    'spikes', {[15.21 -35.98], [20.43 25.72], [0 38.26; 0 76.5; 0 114.8], [32 0]}, ...
    'radius', {5, 5, 5, 1});
spec = [];
for t = table
    if startsWith(fileName, [t.prefix '_'])
        spec = t;
    end
end
end

function cfg = notchConfig(spikes, shape, r, n, suffix)
% A notch reject configuration: every spike gets radius r.
cfg.filter = 'notch';
cfg.shape = shape;
cfg.notches = [spikes, r * ones(size(spikes, 1), 1)];
cfg.n = n;
cfg.D0 = NaN;
cfg.W = NaN;
cfg.method = ['notch-' shape suffix];
spots = arrayfun(@(k) sprintf('(%g,%g)', spikes(k, :)), 1:size(spikes, 1), 'UniformOutput', false);
cfg.params = sprintf('notches=%s; r=%g', strjoin(spots, ''), r);
if strcmp(shape, 'butterworth')
    cfg.params = sprintf('%s; n=%d', cfg.params, n);
end
cfg.extraRow = false;
end

function cfg = bandConfig(shape, D0, W, n)
% A bandreject ring configuration.
cfg.filter = 'band';
cfg.shape = shape;
cfg.notches = zeros(0, 3);
cfg.n = n;
cfg.D0 = D0;
cfg.W = W;
cfg.method = ['band-' shape];
cfg.params = sprintf('D0=%g; W=%g', D0, W);
if strcmp(shape, 'butterworth')
    cfg.params = sprintf('%s; n=%d', cfg.params, n);
end
cfg.extraRow = true;
end

function list = comparisonConfigs(spec, n, ~, ~)
% The filters compared in <input>_E_compare.png, per image.
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
g = runConfig(f, cfg);
[mse, psnr] = scoreAgainstReference(g, dataDir, inPath);
row = resultRow('E', name, cfg.method, cfg.params, mse, psnr);
end

function saveMainFigure(f, cfg, dataDir, inPath, outFile)
% Degraded, spectrum before, mask, spectrum after, restored, reference.
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
if ~isempty(refPath)
    imshow(readImageFile(refPath)); title('Reference');
else
    axis off;
end
exportgraphics(fig, outFile, 'Resolution', 110);
close(fig);
end

function saveCompareFigure(f, list, dataDir, inPath, outFile)
% One column per compared filter: restored image (top) and mask (bottom).
K = numel(list);
[M, N, ~] = size(f);
tileHeight = round(420 * M / N);   % keep tiles close to the image's aspect ratio
fig = figure('Visible', 'off', 'Position', [0 0 420 * K 2 * tileHeight + 260], 'Theme', 'light');   % room for 2-line titles
tl = tiledlayout(fig, 2, K, 'TileSpacing', 'compact', 'Padding', 'compact');
[~, inName, ext] = fileparts(inPath);
heading = repmat({' '}, 1, K);          % image name above the first column only
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
% Draw a mask with a thin frame, so its white (pass) area is visible on the
% white figure background.
imshow(H);
axis on;
set(gca, 'XTick', [], 'YTick', [], 'Box', 'on');
title(titleText);
end
