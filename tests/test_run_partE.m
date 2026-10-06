function tests = test_run_partE
% Tests for run_partE on a small fake part folder (temporary). The fake
% input is named like the official brick image and carries a cosine at
% the brick spike frequency, so the analysed notch positions apply.
% Run: runtests('tests/test_run_partE.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'reference'));
    mkdir(fullfile(d, 'out'));
    rng(15);
    M = 128; N = 128;
    ref = 0.3 + 0.4 * rand(M, N);
    [x, y] = meshgrid(0:N-1, 0:M-1);
    noise = 0.15 * cos(2 * pi * (15.21 * y / M - 35.98 * x / N));
    imwrite(ref, fullfile(d, 'reference', 'brick_gray.png'));
    imwrite(ref + noise, fullfile(d, 'input', 'brick_gray_periodic_noise.png'));
    imwrite(ref, fullfile(d, 'input', 'unknown_gray.png'));   % no analysed spikes
    tc.TestData.dir = d;
    tc.TestData.rows = run_partE(d, fullfile(d, 'out'));
end

function testRowsForKnownImage(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "brick_gray_periodic_noise.png", :);
    verifyEqual(tc, height(rows), 1 + 3 * 5);   % baseline + 3 shapes x 5 radii
    verifyEqual(tc, unique(rows.method)', ["input" "notch-butterworth" "notch-gaussian" "notch-ideal"]);
    verifyTrue(tc, any(rows.params == "notches=(15.21,-35.98); r=3"));
end

function testNotchImprovesPsnr(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "brick_gray_periodic_noise.png", :);
    baseline = rows.psnr(rows.method == "input");
    best = max(rows.psnr(rows.method == "notch-gaussian"));
    verifyGreaterThan(tc, best, baseline + 5);
end

function testUnknownImageGetsBaselineOnly(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "unknown_gray.png", :);
    verifyEqual(tc, rows.method, "input");
end

function testFiguresWritten(tc)
    out = fullfile(tc.TestData.dir, 'out');
    verifyTrue(tc, isfile(fullfile(out, 'brick_gray_periodic_noise_E.png')));
    verifyTrue(tc, isfile(fullfile(out, 'brick_gray_periodic_noise_E_compare.png')));
    verifyFalse(tc, isfile(fullfile(out, 'unknown_gray_E.png')));
end
