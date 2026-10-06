function tests = test_highpassH
% Tests for highpassH. Run: runtests('tests/test_highpassH.m')
tests = functiontests(localfunctions);
end

function testComplementOfLowpass(tc)
    % LP + HP = 1 exactly, for every type, even and odd sizes.
    for sz = [8 6; 7 9; 427 640]'
        for type = {'ideal', 'gaussian', 'butterworth'}
            Hl = lowpassH(sz(1), sz(2), type{1}, 5, 3);
            Hh = highpassH(sz(1), sz(2), type{1}, 5, 3);
            verifyEqual(tc, Hl + Hh, ones(sz'), 'AbsTol', 1e-15, type{1});
        end
    end
end

function testShapeRangeAndCentre(tc)
    M = 9; N = 12;
    for type = {'ideal', 'gaussian', 'butterworth'}
        H = highpassH(M, N, type{1}, 3);
        verifySize(tc, H, [M N]);
        verifyTrue(tc, isreal(H));
        verifyGreaterThanOrEqual(tc, min(H(:)), 0);
        verifyLessThanOrEqual(tc, max(H(:)), 1);
        verifyEqual(tc, H(floor(M/2) + 1, floor(N/2) + 1), 0, type{1});   % DC removed
    end
end

function testValuesAtCutoff(tc)
    uc = 11; vc = 11; D0 = 5;
    H = highpassH(21, 21, 'ideal', D0);
    verifyEqual(tc, H(uc, vc + D0), 0);          % D <= D0 is removed
    verifyEqual(tc, H(uc, vc + D0 + 1), 1);
    H = highpassH(21, 21, 'gaussian', D0);
    verifyEqual(tc, H(uc, vc + D0), 1 - exp(-0.5), 'AbsTol', 1e-15);
    H = highpassH(21, 21, 'butterworth', D0, 2);
    verifyEqual(tc, H(uc, vc + D0), 0.5, 'AbsTol', 1e-15);
end

function testButterworthClosedForm(tc)
    % 1 - 1/(1+(D/D0)^2n) equals 1/(1+(D0/D)^2n); at D = 0 the latter is 0 via Inf.
    M = 15; N = 20; D0 = 4; n = 3;
    D = freqDistance(M, N);
    expected = 1 ./ (1 + (D0 ./ D).^(2 * n));
    verifyEqual(tc, highpassH(M, N, 'butterworth', D0, n), expected, 'AbsTol', 1e-14);
end

function testSymmetricSoNoWarning(tc)
    for type = {'ideal', 'gaussian', 'butterworth'}
        H = highpassH(15, 11, type{1}, 4);
        verifyEqual(tc, H, rot90(H, 2), 'AbsTol', 1e-15, type{1});
        verifyWarningFree(tc, @() applyFilter(rand(16, 10, 3), highpassH(16, 10, type{1}, 3)));
    end
end
