function rows = run_partF(dataDir, outDir)
% RUN_PARTF  Batch run of part F (motion blur restoration) over every input image.
%
%   The blur length L and angle theta come from the file name
%   (motionParamsFromName, same values as the data README). Our PSF
%   (motionPSF) reproduces the official inputs from their references to
%   within the 8-bit rounding error, with the angle convention described
%   in motionPSF. The data was blurred with mirrored (not wrapped) borders,
%   so every setting is run with the three border options of
%   motionRestore: periodic, taper and mirror.
%
%   For each input it writes the baseline row "input" and, per border:
%     inverse-threshold  t in {0.02, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.5}
%     inverse-radius     R0 in {10, 20, 30, 40, 60} (Butterworth, order 10)
%     wiener             K in {1e-4, 3e-4, 1e-3, 3e-3, 0.01, 0.03, 0.05, 0.1}
%   plus built-in comparison rows (deconvwnr, never the main method), with
%   the K of our best periodic Wiener result and our PSF or
%   fspecial('motion', L, -theta).
%   Inputs whose name has no "_L<n>_A<n>" get the baseline row only.
%
%   Three figures per input in outDir:
%     <input>_F.png          original, degraded, PSF, |H|, degraded
%                            spectrum, best inverse and best Wiener result
%                            (taper), spectrum of the Wiener result
%     <input>_F_compare.png  inverse with a too small t, best t, best R0,
%                            PSNR vs t; Wiener best per border, PSNR vs K
%     <input>_F_builtin.png  our Wiener next to the built-in deconvwnr,
%                            labelled as a comparison
%
%   INPUT
%     dataDir  part folder holding input/ and reference/ (text)
%     outDir   folder for the figures (text, must exist)
%
%   OUTPUT
%     rows     table in the resultRow format

s.ts = [0.02 0.05 0.1 0.15 0.2 0.3 0.4 0.5];
s.R0s = [10 20 30 40 60];
s.Ks = [1e-4 3e-4 1e-3 3e-3 0.01 0.03 0.05 0.1];
s.borders = {'periodic', 'taper', 'mirror'};

rows = resultRow();
files = dir(fullfile(dataDir, 'input', '*.png'));
for k = 1:numel(files)
    name = files(k).name;
    inPath = fullfile(files(k).folder, name);
    g = readImageFile(inPath);

    [mse, psnr] = scoreAgainstReference(g, dataDir, inPath);
    rows = [rows; resultRow('F', name, 'input', '', mse, psnr)]; %#ok<AGROW>

    [L, theta] = motionParamsFromName(name);
    if isempty(L)
        continue;
    end
    psf = motionPSF(L, theta);
    blur = sprintf('L=%g; theta=%g', L, theta);

    % Sweeps: one PSNR table per method, rows = border, columns = value
    r.t = NaN(3, numel(s.ts));
    r.R0 = NaN(3, numel(s.R0s));
    r.K = NaN(3, numel(s.Ks));
    for b = 1:3
        border = s.borders{b};
        for j = 1:numel(s.ts)
            [mse, r.t(b, j)] = scoreAgainstReference( ...
                motionRestore(g, psf, 'threshold', s.ts(j), border), dataDir, inPath);
            rows = [rows; resultRow('F', name, 'inverse-threshold', ...
                sprintf('%s; t=%g; border=%s', blur, s.ts(j), border), mse, r.t(b, j))]; %#ok<AGROW>
        end
        for j = 1:numel(s.R0s)
            [mse, r.R0(b, j)] = scoreAgainstReference( ...
                motionRestore(g, psf, 'radius', s.R0s(j), border), dataDir, inPath);
            rows = [rows; resultRow('F', name, 'inverse-radius', ...
                sprintf('%s; R0=%g; border=%s', blur, s.R0s(j), border), mse, r.R0(b, j))]; %#ok<AGROW>
        end
        for j = 1:numel(s.Ks)
            [mse, r.K(b, j)] = scoreAgainstReference( ...
                motionRestore(g, psf, 'wiener', s.Ks(j), border), dataDir, inPath);
            rows = [rows; resultRow('F', name, 'wiener', ...
                sprintf('%s; K=%g; border=%s', blur, s.Ks(j), border), mse, r.K(b, j))]; %#ok<AGROW>
        end
    end

    % Built-in comparison at the K of our best periodic Wiener result
    K = s.Ks(bestIndex(r.K(1, :), 4));
    builtin.ours = channelwise(@(x) deconvwnr(x, psf, K), g);
    builtin.fspecial = channelwise(@(x) deconvwnr(x, fspecial('motion', L, -theta), K), g);
    [mse, builtin.oursPsnr] = scoreAgainstReference(builtin.ours, dataDir, inPath);
    rows = [rows; resultRow('F', name, 'builtin-deconvwnr', ...
        sprintf('%s; NSR=%g; psf=motionPSF', blur, K), mse, builtin.oursPsnr)]; %#ok<AGROW>
    [mse, builtin.fspecialPsnr] = scoreAgainstReference(builtin.fspecial, dataDir, inPath);
    rows = [rows; resultRow('F', name, 'builtin-deconvwnr', ...
        sprintf('%s; NSR=%g; psf=fspecial(-theta)', blur, K), mse, builtin.fspecialPsnr)]; %#ok<AGROW>
    builtin.K = K;

    base = fullfile(outDir, erase(name, '.png'));
    saveMainFigure(g, psf, dataDir, inPath, s, r, [base '_F.png']);
    saveCompareFigure(g, psf, s, r, [base '_F_compare.png']);
    saveBuiltinFigure(g, psf, dataDir, inPath, builtin, [base '_F_builtin.png']);
end
end

function j = bestIndex(psnrs, jDefault)
% Index of the best PSNR; the default when there is no reference (all NaN).
if all(isnan(psnrs))
    j = jDefault;
else
    [~, j] = max(psnrs);
end
end

function out = channelwise(fun, img)
% Apply a 2-D function to each colour channel.
out = zeros(size(img));
for c = 1:size(img, 3)
    out(:, :, c) = fun(img(:, :, c));
end
end

function showTile(img, titleText)
nexttile; imshow(min(max(img, 0), 1)); title(titleText, 'Interpreter', 'none');
end

function [ref, label] = referenceTile(dataDir, inPath)
ref = [];
label = 'No reference';
refPath = findReference(dataDir, inPath);
if ~isempty(refPath)
    ref = readImageFile(refPath);
    label = 'Original (reference)';
end
end

function saveMainFigure(g, psf, dataDir, inPath, s, r, outFile)
[M, N, ~] = size(g);
[~, inName, ext] = fileparts(inPath);
[~, pg] = scoreAgainstReference(g, dataDir, inPath);
jt = bestIndex(r.t(2, :), 3);
jK = bestIndex(r.K(2, :), 4);
[fInv, H] = motionRestore(g, psf, 'threshold', s.ts(jt), 'taper');
fW = motionRestore(g, psf, 'wiener', s.Ks(jK), 'taper');

fig = figure('Visible', 'off', 'Position', [0 0 1700 850], 'Theme', 'light');
tiledlayout(fig, 2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
[ref, label] = referenceTile(dataDir, inPath);
if isempty(ref)
    nexttile; axis off; title(label);
else
    showTile(ref, label);
end
showTile(g, sprintf('Degraded: %s%s (%.2f dB)', inName, ext, pg));
nexttile; imshow(psf / max(psf(:))); title(sprintf('PSF %d x %d (/ max)', size(psf, 1), size(psf, 2)));
nexttile; imshow(abs(H)); title('|H(u,v)|');
[~, ~, Gs] = applyFilter(g, ones(M, N));
nexttile; imshow(spectrumImage(Gs)); title('Degraded spectrum');
showTile(fInv, sprintf('Inverse, threshold t = %g, taper (%.2f dB)', s.ts(jt), r.t(2, jt)));
showTile(fW, sprintf('Wiener, K = %g, taper (%.2f dB)', s.Ks(jK), r.K(2, jK)));
[~, ~, Ws] = applyFilter(fW, ones(M, N));
nexttile; imshow(spectrumImage(Ws)); title('Spectrum of the Wiener result');
exportgraphics(fig, outFile, 'Resolution', 110);
close(fig);
end

function saveCompareFigure(g, psf, s, r, outFile)
fig = figure('Visible', 'off', 'Position', [0 0 1700 850], 'Theme', 'light');
tiledlayout(fig, 2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

showTile(motionRestore(g, psf, 'threshold', s.ts(1), 'taper'), ...
    sprintf('Inverse t = %g: too small (%.2f dB)', s.ts(1), r.t(2, 1)));
jt = bestIndex(r.t(2, :), 3);
showTile(motionRestore(g, psf, 'threshold', s.ts(jt), 'taper'), ...
    sprintf('Inverse t = %g (%.2f dB)', s.ts(jt), r.t(2, jt)));
jR = bestIndex(r.R0(2, :), 2);
showTile(motionRestore(g, psf, 'radius', s.R0s(jR), 'taper'), ...
    sprintf('Inverse radius R0 = %g (%.2f dB)', s.R0s(jR), r.R0(2, jR)));
nexttile; semilogx(s.ts, r.t', '-o'); grid on;
xlabel('threshold t'); ylabel('PSNR (dB)'); legend(s.borders, 'Location', 'best');
title('Inverse filter: PSNR vs t');

for b = 1:3
    jK = bestIndex(r.K(b, :), 4);
    showTile(motionRestore(g, psf, 'wiener', s.Ks(jK), s.borders{b}), ...
        sprintf('Wiener K = %g, %s (%.2f dB)', s.Ks(jK), s.borders{b}, r.K(b, jK)));
end
nexttile; semilogx(s.Ks, r.K', '-o'); grid on;
xlabel('K'); ylabel('PSNR (dB)'); legend(s.borders, 'Location', 'best');
title('Wiener filter: PSNR vs K');
exportgraphics(fig, outFile, 'Resolution', 110);
close(fig);
end

function saveBuiltinFigure(g, psf, dataDir, inPath, builtin, outFile)
fig = figure('Visible', 'off', 'Position', [0 0 1500 520], 'Theme', 'light');
t = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'Comparison with the built-in deconvwnr (not part of our implementation)');
K = builtin.K;
ours = motionRestore(g, psf, 'wiener', K, 'periodic');
[~, p] = scoreAgainstReference(ours, dataDir, inPath);
showTile(ours, sprintf('Ours: Wiener K = %g, periodic (%.2f dB)', K, p));
showTile(builtin.ours, sprintf('Built-in deconvwnr, our PSF, NSR = %g (%.2f dB)', K, builtin.oursPsnr));
showTile(builtin.fspecial, sprintf('Built-in deconvwnr, fspecial PSF (%.2f dB)', builtin.fspecialPsnr));
exportgraphics(fig, outFile, 'Resolution', 110);
close(fig);
end
