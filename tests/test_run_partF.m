function tests = test_run_partF
% Tests for run_partF on a small fake part folder (temporary). The fake
% input is a circular motion blur of the reference, named like the
% official images so L and theta come from the name.
% Run: runtests('tests/test_run_partF.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'reference'));
    mkdir(fullfile(d, 'out'));
    rng(20);
    ref = applyFilter(rand(64, 72, 3), lowpassH(64, 72, 'gaussian', 10));
    ref = (ref - min(ref(:))) / (max(ref(:)) - min(ref(:)));
    imwrite(ref, fullfile(d, 'reference', 'tile_color.png'));
    imwrite(min(max(motionDegrade(ref, motionPSF(9, 20)), 0), 1), ...
        fullfile(d, 'input', 'tile_color_motion_L9_A20.png'));
    imwrite(ref, fullfile(d, 'input', 'plain_color.png'));    % no blur parameters in the name
    tc.TestData.dir = d;
    tc.TestData.rows = run_partF(d, fullfile(d, 'out'));
end

function testRowsForBlurredImage(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "tile_color_motion_L9_A20.png", :);
    verifyEqual(tc, height(rows), 1 + 3 * (8 + 5 + 8) + 2);
    verifyEqual(tc, unique(rows.method)', ...
        ["builtin-deconvwnr" "input" "inverse-radius" "inverse-threshold" "wiener"]);
    verifyTrue(tc, any(rows.params == "L=9; theta=20; K=0.001; border=taper"));
    verifyTrue(tc, any(rows.params == "L=9; theta=20; t=0.1; border=mirror"));
end

function testRestorationImprovesPsnr(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "tile_color_motion_L9_A20.png", :);
    baseline = rows.psnr(rows.method == "input");
    verifyGreaterThan(tc, max(rows.psnr(rows.method == "wiener")), baseline + 10);
    verifyGreaterThan(tc, max(rows.psnr(rows.method == "inverse-threshold")), baseline + 10);
end

function testOurWienerEqualsBuiltin(tc)
    % Same PSF, same K, periodic border: the built-in gives the same result.
    rows = tc.TestData.rows(tc.TestData.rows.image == "tile_color_motion_L9_A20.png", :);
    builtin = rows(rows.method == "builtin-deconvwnr" & endsWith(rows.params, "psf=motionPSF"), :);
    K = extractBetween(builtin.params, "NSR=", ";");
    ours = rows(rows.method == "wiener" & contains(rows.params, "K=" + K + ";") & ...
        endsWith(rows.params, "periodic"), :);
    verifyEqual(tc, builtin.psnr, ours.psnr, 'AbsTol', 0.05);
end

function testImageWithoutParametersGetsBaselineOnly(tc)
    rows = tc.TestData.rows(tc.TestData.rows.image == "plain_color.png", :);
    verifyEqual(tc, rows.method, "input");
end

function testFiguresWritten(tc)
    out = fullfile(tc.TestData.dir, 'out');
    for suffix = ["_F.png" "_F_compare.png" "_F_builtin.png"]
        verifyTrue(tc, isfile(fullfile(out, "tile_color_motion_L9_A20" + suffix)), suffix);
    end
    verifyFalse(tc, isfile(fullfile(out, 'plain_color_F.png')));
end
