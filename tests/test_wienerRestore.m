function tests = test_wienerRestore
% Tests for wienerRestore. Run: runtests('tests/test_wienerRestore.m')
tests = functiontests(localfunctions);
end

function testFormula(tc)
    H = psf2H(motionPSF(7, 20), 32, 40);
    [~, R] = wienerRestore(rand(32, 40), H, 0.01);
    verifyEqual(tc, R, conj(H) ./ (abs(H).^2 + 0.01), 'AbsTol', 1e-14);
end

function testSmallKApproachesInverse(tc)
    rng(5);
    f = rand(63, 61);
    H = psf2H(motionPSF(3, 0), 63, 61);          % no exact zeros
    g = applyFilter(f, H);
    inv = inverseRestore(g, H, 'none');
    verifyEqual(tc, wienerRestore(g, H, 1e-14), inv, 'AbsTol', 1e-6);
    verifyEqual(tc, wienerRestore(g, H, 0), inv, 'AbsTol', 1e-10);
end

function testGainIsBounded(tc)
    % |R| = |H| / (|H|^2 + K) <= 1 / (2 sqrt(K)): no blow-up where H ~ 0.
    H = psf2H(motionPSF(15, 35), 64, 64);
    K = 0.01;
    [~, R] = wienerRestore(rand(64), H, K);
    verifyLessThanOrEqual(tc, max(abs(R(:))), 1 / (2 * sqrt(K)) + 1e-12);
end

function testBeatsInverseWithNoise(tc)
    % With noise, the plain inverse amplifies it; Wiener keeps it down.
    rng(6);
    f = applyFilter(rand(64, 64, 3), lowpassH(64, 64, 'gaussian', 12));   % smooth test image
    H = psf2H(motionPSF(9, 30), 64, 64);
    g = applyFilter(f, H) + 0.01 * randn(64, 64, 3);
    [~, pInverse] = imageQuality(inverseRestore(g, H, 'threshold', 1e-3), f);
    [~, pWiener] = imageQuality(wienerRestore(g, H, 0.01), f);
    verifyGreaterThan(tc, pWiener, pInverse + 5);
end

function testZeroHWithZeroK(tc)
    H = complex(ones(8, 8));
    H(5, 5) = 0;                                  % symmetric: (5,5) is the centre of 8x8
    [f, R] = wienerRestore(rand(8, 8), H, 0);
    verifyTrue(tc, all(isfinite(f(:))));
    verifyEqual(tc, abs(R(5, 5)), 0);
end
