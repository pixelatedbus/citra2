function tests = test_run_partD
% Tests for run_partD on a small fake part folder (temporary).
% Run: runtests('tests/test_run_partD.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'reference'));
    mkdir(fullfile(d, 'out'));
    rng(17);
    ref = 0.2 + 0.7 * applyFilter(rand(48, 56), lowpassH(48, 56, 'gaussian', 10));
    ref = min(max(ref, 0), 1);
    imwrite(ref, fullfile(d, 'reference', 'tile_gray.png'));
    imwrite(0.35 * ref.^1.25, fullfile(d, 'input', 'tile_gray_dark.png'));   % power-law darkening
    imwrite(0.2 * rand(20, 24, 3), fullfile(d, 'input', 'other_color_dark.png'));   % no reference
    tc.TestData.dir = d;
    tc.TestData.rows = run_partD(d, fullfile(d, 'out'));
end

function testRowsPerImage(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "tile_gray_dark.png", :);
    verifyEqual(tc, height(rows), 1 + 6 * 25 + 4 + 5 * 3);
    verifyEqual(tc, unique(rows.method)', ["emphasis" "homomorphic" "homomorphic-split" "input"]);
    verifyTrue(tc, any(rows.params == "gL=0.8; gH=0.8; D0=0; t=0.4"));
    verifyTrue(tc, any(rows.params == "k=3; D0=0"));
end

function testHomomorphicUndoesPowerLaw(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "tile_gray_dark.png", :);
    baseline = rows.psnr(rows.method == "input");
    homomorphic = max(rows.psnr(rows.method == "homomorphic"));
    emphasis = max(rows.psnr(rows.method == "emphasis"));
    verifyGreaterThan(tc, homomorphic, baseline + 15);
    verifyGreaterThan(tc, homomorphic, emphasis);
end

function testNoReferenceGivesNaN(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "other_color_dark.png", :);
    verifyTrue(tc, all(isnan(rows.psnr)));
    verifyEqual(tc, height(rows), 1 + 6 * 25 + 4 + 5 * 3);
end

function testFiguresWritten(tc)
    out = fullfile(tc.TestData.dir, 'out');
    verifyTrue(tc, isfile(fullfile(out, 'tile_gray_dark_D.png')));
    verifyTrue(tc, isfile(fullfile(out, 'other_color_dark_D.png')));
end
