function rows = run_partD(dataDir, outDir)
% Part D batch: homomorphic g x t sweep, split gains, and low-frequency emphasis k x D0 for every input.
gs = [0.7 0.75 0.8 0.85 0.9 1.0];
ts = 0.10:0.025:0.70;
ks = 2:6;
emphasisD0s = [0 10 80];
default = struct('g', 0.8, 't', 0.4);

rows = resultRow();
files = dir(fullfile(dataDir, 'input', '*.png'));
for k = 1:numel(files)
    name = files(k).name;
    inPath = fullfile(files(k).folder, name);
    f = readImageFile(inPath);
    [M, N, ~] = size(f);
    [mse, psnr] = scoreAgainstReference(f, dataDir, inPath);
    rows = [rows; resultRow('D', name, 'input', '', mse, psnr)];

    psnrTable = NaN(numel(gs), numel(ts));
    for i = 1:numel(gs)
        for j = 1:numel(ts)
            g = homomorphicBrightness(f, gs(i), gs(i), 0, ts(j));
            [mse, psnrTable(i, j)] = scoreAgainstReference(g, dataDir, inPath);
            params = sprintf('gL=%g; gH=%g; D0=0; t=%g', gs(i), gs(i), ts(j));
            rows = [rows; resultRow('D', name, 'homomorphic', params, mse, psnrTable(i, j))];
        end
    end
    [i, j] = bestIndex(psnrTable, find(gs == default.g), find(abs(ts - default.t) < 1e-9));
    best = struct('g', gs(i), 't', ts(j), 'psnr', psnrTable(i, j));

    for D0 = [5 30]
        for pair = [best.g, best.g - 0.1; best.g - 0.1, best.g]'
            g = homomorphicBrightness(f, pair(1), pair(2), D0, best.t);
            [mse, psnr] = scoreAgainstReference(g, dataDir, inPath);
            params = sprintf('gL=%g; gH=%g; D0=%g; t=%g', pair(1), pair(2), D0, best.t);
            rows = [rows; resultRow('D', name, 'homomorphic-split', params, mse, psnr)];
        end
    end

    emphasisTable = NaN(numel(ks), numel(emphasisD0s));
    for i = 1:numel(ks)
        for j = 1:numel(emphasisD0s)
            g = applyFilter(f, brightnessH(M, N, ks(i), 1, emphasisD0s(j)));
            [mse, emphasisTable(i, j)] = scoreAgainstReference(g, dataDir, inPath);
            params = sprintf('k=%g; D0=%g', ks(i), emphasisD0s(j));
            rows = [rows; resultRow('D', name, 'emphasis', params, mse, emphasisTable(i, j))];
        end
    end

    saveFigure(f, dataDir, inPath, gs, ts, psnrTable, best, ks, emphasisD0s, emphasisTable, default, ...
        fullfile(outDir, [erase(name, '.png') '_D.png']));
end
end

function [i, j] = bestIndex(T, iDefault, jDefault)
if all(isnan(T(:)))
    i = iDefault;
    j = jDefault;
else
    [~, idx] = max(T(:));
    [i, j] = ind2sub(size(T), idx);
end
end

function saveFigure(f, dataDir, inPath, gs, ts, psnrTable, best, ks, emphasisD0s, emphasisTable, default, outFile)
[M, N, ~] = size(f);
uc = floor(M/2) + 1;
vc = floor(N/2) + 1;
[~, inName, ext] = fileparts(inPath);

fig = figure('Visible', 'off', 'Position', [0 0 2000 800], 'Theme', 'light');
tiledlayout(fig, 2, 5, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; imshow(min(max(f, 0), 1));
title(sprintf('Input: %s%s (mean %.3f)', inName, ext, mean(f, 'all')), 'Interpreter', 'none');
nexttile;
refPath = findReference(dataDir, inPath);
if isempty(refPath)
    axis off; title('No reference');
else
    ref = readImageFile(refPath);
    imshow(ref); title(sprintf('Reference (mean %.3f)', mean(ref, 'all')));
end
[~, ~, F] = applyFilter(f, ones(M, N));
nexttile; imshow(spectrumImage(F)); title('Input spectrum');
gBest = homomorphicBrightness(f, best.g, best.g, 0, best.t);
[~, ~, G] = applyFilter(gBest, ones(M, N));
nexttile; imshow(spectrumImage(G)); title('Spectrum of the homomorphic result');
nexttile; plot(ts, psnrTable', '-o'); grid on;
xlabel('target t (geometric mean)'); ylabel('PSNR (dB)');
legend(compose('g = %g', gs), 'Location', 'best'); title('Homomorphic, D0 = 0: PSNR vs t');

nexttile; imshow(min(max(gBest, 0), 1));
title(sprintf('Homomorphic g = %g, t = %g (%.2f dB)', best.g, best.t, best.psnr));
[i, j] = bestIndex(emphasisTable, 2, 1);
kE = ks(i);
D0E = emphasisD0s(j);
nexttile; imshow(min(max(applyFilter(f, brightnessH(M, N, kE, 1, D0E)), 0), 1));
title(sprintf('Emphasis k = %g, D0 = %g (%.2f dB)', kE, D0E, emphasisTable(i, j)));
[i, ~] = bestIndex(emphasisTable(:, 1), 2, 1);
nexttile; imshow(min(max(applyFilter(f, brightnessH(M, N, ks(i), 1, 0)), 0), 1));
title(sprintf('DC gain only k = %g (%.2f dB)', ks(i), emphasisTable(i, 1)));

nexttile; hold on; grid on;
v = 0:min(60, N - vc);
Hh = brightnessH(M, N, best.g, best.g, 0);
He = brightnessH(M, N, kE, 1, D0E);
stem(v, Hh(uc, vc + v), 'filled', 'MarkerSize', 3);
plot(v, He(uc, vc + v), '-', 'LineWidth', 1.5);
xlabel('distance from centre D (samples)'); ylabel('H');
legend({'homomorphic (on log spectrum)', 'emphasis (on spectrum)'}, 'Location', 'best');
title('Filter profiles H along the centre row');

gDefault = homomorphicBrightness(f, default.g, default.g, 0, default.t);
[~, pDefault] = scoreAgainstReference(gDefault, dataDir, inPath);
nexttile; imshow(min(max(gDefault, 0), 1));
title(sprintf('Default g = %g, t = %g (%.2f dB)', default.g, default.t, pDefault));
exportgraphics(fig, outFile, 'Resolution', 110);
close(fig);
end
