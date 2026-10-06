function tests = test_lowpassH
% Tests for lowpassH. Run: runtests('tests/test_lowpassH.m')
tests = functiontests(localfunctions);
end

function testShapeRangeAndCentre(tc)
    % Every type: M x N, real double, within [0,1], exactly 1 at the centre.
    for sz = [8 6; 7 9; 427 640]'
        M = sz(1); N = sz(2);
        for type = {'ideal', 'gaussian', 'butterworth'}
            H = lowpassH(M, N, type{1}, 3);
            msg = sprintf('%s %dx%d', type{1}, M, N);
            verifySize(tc, H, [M N], msg);
            verifyClass(tc, H, 'double', msg);
            verifyTrue(tc, isreal(H), msg);
            verifyGreaterThanOrEqual(tc, min(H(:)), 0, msg);
            verifyLessThanOrEqual(tc, max(H(:)), 1, msg);
            verifyEqual(tc, H(floor(M/2) + 1, floor(N/2) + 1), 1, msg);
        end
    end
end

function testValuesAtCutoff(tc)
    % Sample exactly D0 = 5 columns right of the centre.
    M = 21; N = 21; D0 = 5;
    uc = 11; vc = 11;
    H = lowpassH(M, N, 'ideal', D0);
    verifyEqual(tc, H(uc, vc + D0), 1);       % D <= D0 is kept
    verifyEqual(tc, H(uc, vc + D0 + 1), 0);

    H = lowpassH(M, N, 'gaussian', D0);
    verifyEqual(tc, H(uc, vc + D0), exp(-0.5), 'AbsTol', 1e-15);

    for n = [1 2 5]
        H = lowpassH(M, N, 'butterworth', D0, n);
        verifyEqual(tc, H(uc, vc + D0), 0.5, 'AbsTol', 1e-15);
    end
end

function testSymmetricAboutCentre(tc)
    % Odd size: the centre is the middle sample, so a 180 degree turn maps H onto itself.
    for type = {'ideal', 'gaussian', 'butterworth'}
        H = lowpassH(15, 11, type{1}, 4);
        verifyEqual(tc, H, rot90(H, 2), 'AbsTol', 1e-15, type{1});
    end
end

function testHighOrderButterworthApproachesIdeal(tc)
    % Samples sit at D^2 = integer. D0^2 = 22.5 lies between the nearest ones
    % (D^2 = 20 and 25), so no sample is close to the cutoff and order 60
    % is enough to reach ~1 inside and ~0 outside.
    D0 = sqrt(22.5);
    Hi = lowpassH(31, 31, 'ideal', D0);
    Hb = lowpassH(31, 31, 'butterworth', D0, 60);
    verifyEqual(tc, Hb, Hi, 'AbsTol', 1e-2);
end

function testCaseInsensitiveType(tc)
    verifyEqual(tc, lowpassH(8, 8, 'Gaussian', 2), lowpassH(8, 8, 'gaussian', 2));
end

function testRejectsBadInput(tc)
    verifyError(tc, @() lowpassH(8, 8, 'box', 2), 'lowpassH:unknownType');
    verifyError(tc, @() lowpassH(8, 8, 'ideal', 0), 'MATLAB:validators:mustBePositive');
    verifyError(tc, @() lowpassH(8, 8, 'butterworth', 2, 1.5), 'MATLAB:validators:mustBeInteger');
end
