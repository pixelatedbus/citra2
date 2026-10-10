function tests = test_motionPSF
% Tests for motionPSF. Run: runtests('tests/test_motionPSF.m')
tests = functiontests(localfunctions);
end

function testNormalisedOddAndCentred(tc)
    for L = [2 5 15 23]
        for theta = [-25 0 20 35 90]
            p = motionPSF(L, theta);
            verifyEqual(tc, sum(p(:)), 1, 'AbsTol', 1e-12);
            verifyGreaterThanOrEqual(tc, min(p(:)), 0);
            verifyEqual(tc, mod(size(p), 2), [1 1]);                  % odd size
            verifyEqual(tc, p, rot90(p, 2), 'AbsTol', 1e-12);         % symmetric about the centre
        end
    end
end

function testHorizontalProfile(tc)
    % theta = 0: one row [1/2 1 ... 1 1/2] / (L-1), L pixels long.
    L = 9;
    p = motionPSF(L, 0);
    row = p((size(p, 1) + 1) / 2, :);
    expected = [0.5 ones(1, L - 2) 0.5] / (L - 1);
    verifyEqual(tc, row(row > 0), expected, 'AbsTol', 1e-3);
    verifyEqual(tc, sum(p, 2)', double(1:size(p, 1) == (size(p, 1) + 1) / 2), 'AbsTol', 1e-12);
end

function testLengthOneIsIdentity(tc)
    verifyEqual(tc, motionPSF(1, 30), 1);
end

function testAngleConvention(tc)
    % Positive theta: the line goes down-right on screen (rows point down).
    p = motionPSF(15, 30);
    [cols, rows] = meshgrid(1:size(p, 2), 1:size(p, 1));
    c = (size(p, 1) + 1) / 2;
    x = cols - c; y = rows - c;
    angle = 0.5 * atan2d(2 * sum(p .* x .* y, 'all'), sum(p .* (x.^2 - y.^2), 'all'));
    verifyEqual(tc, angle, 30, 'AbsTol', 0.5);
end

function testMatchesFspecialAtMinusTheta(tc)
    % Comparison only: fspecial('motion') uses the opposite angle sign.
    rng(1);
    f = applyFilter(rand(96), lowpassH(96, 96, 'gaussian', 10));   % smooth test image
    for theta = [20 -25 35]
        ours = imfilter(f, motionPSF(19, theta), 'circular', 'conv');
        same = imfilter(f, fspecial('motion', 19, -theta), 'circular', 'conv');
        flipped = imfilter(f, fspecial('motion', 19, theta), 'circular', 'conv');
        verifyLessThan(tc, rms(ours(:) - same(:)), 0.2 * rms(ours(:) - flipped(:)));
    end
end
