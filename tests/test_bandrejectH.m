function tests = test_bandrejectH
% Tests for bandrejectH. Run: runtests('tests/test_bandrejectH.m')
tests = functiontests(localfunctions);
end

function testShapeRangeCentreAndNoNaN(tc)
    for sz = [8 6; 41 41; 427 640]'
        M = sz(1); N = sz(2);
        for type = {'ideal', 'butterworth', 'gaussian'}
            H = bandrejectH(M, N, type{1}, 10, 4);
            msg = sprintf('%s %dx%d', type{1}, M, N);
            verifySize(tc, H, [M N], msg);
            verifyTrue(tc, isreal(H) && ~any(isnan(H(:))), msg);
            verifyGreaterThanOrEqual(tc, min(H(:)), 0, msg);
            verifyLessThanOrEqual(tc, max(H(:)), 1, msg);
            verifyEqual(tc, H(floor(M/2) + 1, floor(N/2) + 1), 1, msg);   % DC kept
        end
    end
end

function testZeroOnTheRing(tc)
    % Sample exactly D0 = 10 columns right of the centre.
    for type = {'ideal', 'butterworth', 'gaussian'}
        H = bandrejectH(41, 41, type{1}, 10, 4);
        verifyEqual(tc, H(21, 31), 0, type{1});
    end
end

function testIdealBandWidth(tc)
    % D0 = 10, W = 4: distances 8..12 rejected, 7 and 13 kept (along a row).
    H = bandrejectH(41, 41, 'ideal', 10, 4);
    verifyEqual(tc, H(21, 21 + (7:13)), [1 0 0 0 0 0 1]);
end

function testBandEdgeValues(tc)
    % Where |D^2 - D0^2| = D*W the Butterworth is 0.5 and the Gaussian 1 - e^-1.
    % D0 = 12, W = 7: D = 16 gives 256 - 144 = 112 = 16 * 7.
    for n = [1 2 4]
        H = bandrejectH(41, 41, 'butterworth', 12, 7, n);
        verifyEqual(tc, H(21, 21 + 16), 0.5, 'AbsTol', 1e-14);
    end
    H = bandrejectH(41, 41, 'gaussian', 12, 7);
    verifyEqual(tc, H(21, 21 + 16), 1 - exp(-1), 'AbsTol', 1e-14);
end

function testWiderBandRejectsMore(tc)
    narrow = bandrejectH(64, 64, 'gaussian', 15, 2);
    wide = bandrejectH(64, 64, 'gaussian', 15, 8);
    verifyLessThan(tc, sum(wide(:)), sum(narrow(:)));
end

function testSymmetricSoNoWarning(tc)
    for type = {'ideal', 'butterworth', 'gaussian'}
        H = bandrejectH(15, 11, type{1}, 4, 2);
        verifyEqual(tc, H, rot90(H, 2), 'AbsTol', 1e-15, type{1});
        verifyWarningFree(tc, @() applyFilter(rand(16, 10, 3), bandrejectH(16, 10, type{1}, 4, 2)));
    end
end

function testRejectsBadInput(tc)
    verifyError(tc, @() bandrejectH(8, 8, 'box', 2, 1), 'bandrejectH:unknownType');
    verifyError(tc, @() bandrejectH(8, 8, 'ideal', 2, 0), 'MATLAB:validators:mustBePositive');
end
