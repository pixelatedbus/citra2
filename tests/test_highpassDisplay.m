function tests = test_highpassDisplay
% Tests for highpassDisplay. Run: runtests('tests/test_highpassDisplay.m')
tests = functiontests(localfunctions);
end

function testAbs(tc)
    verifyEqual(tc, highpassDisplay([-0.2 0 0.3], 'abs'), [0.2 0 0.3]);
end

function testAbsNormalized(tc)
    verifyEqual(tc, highpassDisplay([-0.2 0 0.4], 'abs-normalized'), [0.5 0 1]);
end

function testRescaleKeepsSign(tc)
    % -0.2 -> 0, 0 -> 1/3, 0.4 -> 1: zero lands between dark and bright.
    verifyEqual(tc, highpassDisplay([-0.2 0 0.4], 'rescale'), [0 1/3 1], 'AbsTol', 1e-15);
end

function testColourUsesOneScaleForAllChannels(tc)
    g = cat(3, [0 0.1], [0 0.2], [0 0.4]);
    out = highpassDisplay(g, 'abs-normalized');
    verifyEqual(tc, squeeze(out(1, 2, :))', [0.25 0.5 1]);   % ratios between channels kept
end

function testAllZeroGivesZeros(tc)
    for mode = {'abs', 'abs-normalized', 'rescale'}
        verifyEqual(tc, highpassDisplay(zeros(3, 4), mode{1}), zeros(3, 4), mode{1});
    end
end

function testRejectsUnknownMode(tc)
    verifyError(tc, @() highpassDisplay(1, 'log'), 'highpassDisplay:unknownMode');
end
