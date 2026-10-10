function tests = test_brightnessH
% Tests for brightnessH. Run: runtests('tests/test_brightnessH.m')
tests = functiontests(localfunctions);
end

function testCentreAndFarValues(tc)
    for sz = [64 64; 63 80]'
        M = sz(1); N = sz(2);
        H = brightnessH(M, N, 2.5, 0.8, 4);
        verifySize(tc, H, [M N]);
        verifyTrue(tc, isreal(H));
        verifyEqual(tc, H(floor(M/2) + 1, floor(N/2) + 1), 2.5, 'AbsTol', 1e-15);
        verifyEqual(tc, H(1, 1), 0.8, 'AbsTol', 1e-12);              % far corner -> gH
        verifyGreaterThanOrEqual(tc, min(H(:)), 0.8 - 1e-15);
        verifyLessThanOrEqual(tc, max(H(:)), 2.5 + 1e-15);
    end
end

function testMatchesGaussianFormula(tc)
    % H = gH + (gL - gH) * GLPF, so low-frequency emphasis is 1 + (k-1) * GLPF.
    M = 40; N = 52; k = 3; D0 = 6;
    expected = 1 + (k - 1) * lowpassH(M, N, 'gaussian', D0);
    verifyEqual(tc, brightnessH(M, N, k, 1, D0), expected, 'AbsTol', 1e-14);
end

function testDcOnly(tc)
    M = 9; N = 12;
    H = brightnessH(M, N, 4, 1, 0);
    expected = ones(M, N);
    expected(floor(M/2) + 1, floor(N/2) + 1) = 4;
    verifyEqual(tc, H, expected);
end

function testEqualGainsGiveConstant(tc)
    verifyEqual(tc, brightnessH(20, 21, 0.7, 0.7, 5), 0.7 * ones(20, 21), 'AbsTol', 1e-15);
end

function testDcGainRaisesOnlyTheMean(tc)
    % DC-only gain k adds (k-1) * mean to every pixel: brighter, same detail.
    rng(10);
    f = 0.2 * rand(30, 34, 3);
    g = applyFilter(f, brightnessH(30, 34, 3, 1, 0));
    verifyEqual(tc, g, f + 2 * mean(f, [1 2]), 'AbsTol', 1e-12);
end

function testSymmetricSoNoWarning(tc)
    verifyWarningFree(tc, @() applyFilter(rand(32, 30), brightnessH(32, 30, 2, 1, 3)));
end
