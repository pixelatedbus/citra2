function tests = test_run_partB
% Tests for run_partB on a small fake part folder (temporary).
% Run: runtests('tests/test_run_partB.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'reference'));
    mkdir(fullfile(d, 'out'));
    rng(11);
    ref = imgaussfilt(rand(48, 64), 3);   % smooth reference (test data only)
    imwrite(ref, fullfile(d, 'reference', 'tile_gray.png'));
    imwrite(min(max(ref + 0.1 * randn(size(ref)), 0), 1), ...
        fullfile(d, 'input', 'tile_gray_gaussian_noise.png'));
    tc.TestData.dir = d;
    tc.TestData.rows = run_partB(d, fullfile(d, 'out'));
end

function testRowsPerInput(tc)
    rows = tc.TestData.rows;
    verifyEqual(tc, height(rows), 1 + 3 * 12);   % baseline + 3 types x 12 D0
    verifyEqual(tc, unique(rows.method)', ["BLPF" "GLPF" "ILPF" "input"]);
    verifyEqual(tc, rows.params(rows.method == "BLPF" & contains(rows.params, "D0=40")), "D0=40; n=2");
end

function testScoresAreFiniteAndSmoothingHelps(tc)
    rows = tc.TestData.rows;
    verifyTrue(tc, all(isfinite(rows.psnr)));
    baseline = rows.psnr(rows.method == "input");
    verifyGreaterThan(tc, max(rows.psnr(rows.method == "GLPF")), baseline);
end

function testFigureWritten(tc)
    verifyTrue(tc, isfile(fullfile(tc.TestData.dir, 'out', 'tile_gray_gaussian_noise_B.png')));
end
