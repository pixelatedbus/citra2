function tests = test_notchRejectH
% Tests for notchRejectH. Run: runtests('tests/test_notchRejectH.m')
tests = functiontests(localfunctions);
end

function testNoNotchesIsAllPass(tc)
    verifyEqual(tc, notchRejectH(8, 6, 'gaussian', zeros(0, 3)), ones(8, 6));
end

function testNotchAtCentreIsHighpassSquared(tc)
    % Offset (0,0): the pair collapses onto the centre, giving Hhp^2.
    for type = {'ideal', 'gaussian', 'butterworth'}
        H = notchRejectH(15, 20, type{1}, [0 0 3], 2);
        verifyEqual(tc, H, highpassH(15, 20, type{1}, 3, 2).^2, 'AbsTol', 1e-14, type{1});
    end
end

function testZeroAtNotchAndMirror(tc)
    M = 32; N = 40; uc = 17; vc = 21;
    for type = {'ideal', 'gaussian', 'butterworth'}
        H = notchRejectH(M, N, type{1}, [5 -7 2]);
        verifyEqual(tc, H(uc + 5, vc - 7), 0, type{1});
        verifyEqual(tc, H(uc - 5, vc + 7), 0, type{1});
        % Centre is ~8.6 samples from both notches: nearly untouched. Not exactly 1
        % for Butterworth (long tail: 1/(1+(2/8.6)^4)^2 ~ 0.994).
        verifyGreaterThan(tc, H(uc, vc), 0.99, type{1});
    end
end

function testSeveralNotchesMultiply(tc)
    a = notchRejectH(30, 30, 'butterworth', [4 6 2]);
    b = notchRejectH(30, 30, 'butterworth', [-8 3 3]);
    verifyEqual(tc, notchRejectH(30, 30, 'butterworth', [4 6 2; -8 3 3]), a .* b, 'AbsTol', 1e-15);
end

function testSymmetricWithFractionalOffsets(tc)
    % Odd size: a 180 degree turn maps every notch onto its mirror.
    H = notchRejectH(31, 41, 'gaussian', [15.21 -5.98 3; 0 8.26 2]);
    verifyEqual(tc, H, rot90(H, 2), 'AbsTol', 1e-14);
    % Even size: no rot90 check, but the spectrum symmetry must hold -> no warning.
    verifyWarningFree(tc, @() applyFilter(rand(32, 40, 3), ...
        notchRejectH(32, 40, 'gaussian', [5.4 -7.7 2; 0 9.3 2])));
end

function testRemovesAPlantedSinusoid(tc)
    % 0.5 + 0.2 cos at frequency (6, 9) samples; an ideal radius-1 notch there
    % leaves exactly the constant 0.5.
    M = 48; N = 64;
    [x, y] = meshgrid(0:N-1, 0:M-1);
    f = 0.5 + 0.2 * cos(2 * pi * (6 * y / M + 9 * x / N));
    g = applyFilter(f, notchRejectH(M, N, 'ideal', [6 9 1]));
    verifyEqual(tc, g, 0.5 * ones(M, N), 'AbsTol', 1e-12);
end

function testRejectsBadInput(tc)
    verifyError(tc, @() notchRejectH(8, 8, 'ideal', [1 1 0]), 'notchRejectH:badRadius');
    verifyError(tc, @() notchRejectH(8, 8, 'box', [1 1 1]), 'notchRejectH:unknownType');
    verifyError(tc, @() notchRejectH(8, 8, 'ideal', [1 1]), 'MATLAB:validation:IncompatibleSize');
end
