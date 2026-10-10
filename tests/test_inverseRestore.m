function tests = test_inverseRestore
% Tests for inverseRestore. Run: runtests('tests/test_inverseRestore.m')
tests = functiontests(localfunctions);
end

function setup(tc)
    % Odd size and a short blur: |H| has no exact zeros (min ~6e-4).
    rng(3);
    tc.TestData.f = rand(63, 61);
    tc.TestData.H = psf2H(motionPSF(3, 0), 63, 61);
    tc.TestData.g = applyFilter(tc.TestData.f, tc.TestData.H);
end

function testNoiseFreeRoundTrip(tc)
    f = inverseRestore(tc.TestData.g, tc.TestData.H, 'threshold', 1e-5);
    verifyEqual(tc, f, tc.TestData.f, 'AbsTol', 1e-8);
    f = inverseRestore(tc.TestData.g, tc.TestData.H, 'none');
    verifyEqual(tc, f, tc.TestData.f, 'AbsTol', 1e-8);
end

function testThresholdDropsSmallH(tc)
    H = tc.TestData.H;
    [~, R] = inverseRestore(tc.TestData.g, H, 'threshold', 0.1);
    small = abs(H) < 0.1;
    verifyTrue(tc, any(small(:)));
    verifyEqual(tc, abs(R(small)), zeros(nnz(small), 1));
    verifyEqual(tc, R(~small), 1 ./ H(~small), 'RelTol', 1e-12);
end

function testRadiusIsButterworthOverH(tc)
    H = tc.TestData.H;
    [~, R] = inverseRestore(tc.TestData.g, H, 'radius', 12);
    verifyEqual(tc, R, lowpassH(63, 61, 'butterworth', 12, 10) ./ H, 'RelTol', 1e-12);
end

function testZeroHGivesZeroNotInf(tc)
    % [1/4 1/2 1/4] on an even size: H = (1 + cos w)/2 is 0 at w = pi.
    H = psf2H([0 0 0; 0.25 0.5 0.25; 0 0 0], 64, 64);
    H(abs(H) < 1e-12) = 0;
    verifyGreaterThan(tc, nnz(H == 0), 0);
    [f, R] = inverseRestore(rand(64), H, 'none');
    verifyTrue(tc, all(isfinite(f(:))));
    verifyEqual(tc, abs(R(H == 0)), zeros(nnz(H == 0), 1));
end

function testColourPerChannel(tc)
    rng(4);
    f = rand(33, 35, 3);
    H = psf2H(motionPSF(3, 90), 33, 35);
    restored = inverseRestore(applyFilter(f, H), H, 'threshold', 1e-6);
    verifyEqual(tc, restored, f, 'AbsTol', 1e-8);
end

function testUnknownModeErrors(tc)
    verifyError(tc, @() inverseRestore(tc.TestData.g, tc.TestData.H, 'magic', 1), ...
        'inverseRestore:unknownMode');
    verifyError(tc, @() inverseRestore(tc.TestData.g, tc.TestData.H, 'radius', 0), ...
        'inverseRestore:badRadius');
end
