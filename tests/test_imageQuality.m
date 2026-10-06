function tests = test_imageQuality
% Tests for imageQuality. Run: runtests('tests/test_imageQuality.m')
tests = functiontests(localfunctions);
end

function testKnownValues(tc)
    % Every pixel off by 0.1: MSE = 0.01, PSNR = 10*log10(100) = 20 dB.
    [mse, psnr] = imageQuality(zeros(4, 5), 0.1 * ones(4, 5));
    verifyEqual(tc, mse, 0.01, 'AbsTol', 1e-15);
    verifyEqual(tc, psnr, 20, 'AbsTol', 1e-12);
end

function testIdenticalGivesInf(tc)
    img = rand(6, 7, 3);
    [mse, psnr] = imageQuality(img, img);
    verifyEqual(tc, mse, 0);
    verifyEqual(tc, psnr, Inf);
end

function testColourAveragesAllChannels(tc)
    % Only one of three channels differs (by 0.3): MSE = 0.09 / 3 = 0.03.
    ref = 0.5 * ones(4, 4, 3);
    g = ref;
    g(:, :, 2) = 0.8;
    verifyEqual(tc, imageQuality(g, ref), 0.03, 'AbsTol', 1e-15);
end

function testClipsBeforeComparing(tc)
    % 1.2 is displayed as 1 and -0.3 as 0, so against 1 and 0 there is no error.
    [mse, psnr] = imageQuality([1.2 -0.3], [1 0]);
    verifyEqual(tc, mse, 0);
    verifyEqual(tc, psnr, Inf);
end

function testMatchesBuiltinForInRangeImages(tc)
    % Comparison only: our formula vs the toolbox immse/psnr.
    rng(4);
    ref = rand(30, 40, 3);
    g = min(max(ref + 0.05 * randn(size(ref)), 0), 1);
    [mse, p] = imageQuality(g, ref);
    verifyEqual(tc, mse, immse(g, ref), 'RelTol', 1e-12);
    verifyEqual(tc, p, psnr(g, ref), 'RelTol', 1e-12);
end

function testRejectsSizeMismatch(tc)
    verifyError(tc, @() imageQuality(rand(4, 5), rand(4, 5, 3)), 'imageQuality:sizeMismatch');
    verifyError(tc, @() imageQuality(rand(4, 5), rand(5, 4)), 'imageQuality:sizeMismatch');
end
