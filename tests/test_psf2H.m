function tests = test_psf2H
% Tests for psf2H. Run: runtests('tests/test_psf2H.m')
tests = functiontests(localfunctions);
end

function testDeltaGivesOnes(tc)
    verifyEqual(tc, psf2H(1, 8, 7), complex(ones(8, 7)), 'AbsTol', 1e-15);
    verifyEqual(tc, psf2H([0 0 0; 0 1 0; 0 0 0], 6, 9), complex(ones(6, 9)), 'AbsTol', 1e-15);
end

function testDcIsPsfSum(tc)
    for sz = [64 64; 63 80]'
        H = psf2H(motionPSF(11, 25), sz(1), sz(2));
        verifySize(tc, H, sz');
        verifyEqual(tc, H(floor(sz(1)/2) + 1, floor(sz(2)/2) + 1), complex(1), 'AbsTol', 1e-12);
    end
end

function testBlurEqualsCircularConvolution(tc)
    % applyFilter with psf2H is the same as circular convolution (no shift).
    rng(2);
    f = rand(40, 52, 3);
    p = motionPSF(7, 35);
    [g, ~, ~] = applyFilter(f, psf2H(p, 40, 52));
    expected = imfilter(f, p, 'circular', 'conv');   % comparison only
    verifyEqual(tc, g, expected, 'AbsTol', 1e-12);
end

function testImpulseStaysInPlace(tc)
    f = zeros(31, 31);
    f(10, 20) = 1;
    p = motionPSF(5, 0);
    g = applyFilter(f, psf2H(p, 31, 31));
    [~, idx] = max(g(:));
    [r, c] = ind2sub(size(g), idx);
    verifyEqual(tc, [r c], [10 20]);                  % centre of the smear = impulse position
end

function testSymmetricPsfGivesRealResult(tc)
    verifyWarningFree(tc, @() applyFilter(rand(32, 30), psf2H(motionPSF(9, -25), 32, 30)));
end

function testBadSizesError(tc)
    verifyError(tc, @() psf2H(ones(2, 3) / 6, 10, 10), 'psf2H:evenSize');
    verifyError(tc, @() psf2H(ones(5) / 25, 4, 10), 'psf2H:tooLarge');
end
