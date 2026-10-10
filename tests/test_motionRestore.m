function tests = test_motionRestore
% Tests for motionRestore. Run: runtests('tests/test_motionRestore.m')
tests = functiontests(localfunctions);
end

function testPeriodicMatchesCoreFunctions(tc)
    rng(7);
    g = rand(40, 44, 3);
    p = motionPSF(9, 20);
    H = psf2H(p, 40, 44);
    [f, Hout] = motionRestore(g, p, 'wiener', 0.01);
    verifyEqual(tc, Hout, H);
    verifyEqual(tc, f, wienerRestore(g, H, 0.01), 'AbsTol', 1e-12);
    f = motionRestore(g, p, 'threshold', 0.1, 'periodic');
    verifyEqual(tc, f, inverseRestore(g, H, 'threshold', 0.1), 'AbsTol', 1e-12);
end

function testMirrorSizesAndRadius(tc)
    g = rand(30, 26);
    p = motionPSF(5, 0);
    [f, H, R] = motionRestore(g, p, 'radius', 8, 'mirror');
    verifySize(tc, f, [30 26]);
    verifySize(tc, H, [60 52]);
    % R0 is doubled for the 2M x 2N spectrum.
    verifyEqual(tc, R, lowpassH(60, 52, 'butterworth', 16, 10) ./ H, 'RelTol', 1e-12);
end

function testBorderOptionsReduceRinging(tc)
    % A blur that does not wrap around (symmetric borders, like the test
    % data). Taper helps at any angle; mirror is exact for theta = 0.
    rng(8);
    f = applyFilter(rand(80, 90), lowpassH(80, 90, 'gaussian', 6));
    f = (f - min(f(:))) / (max(f(:)) - min(f(:)));
    for theta = [0 30]
        p = motionPSF(11, theta);
        g = imfilter(f, p, 'symmetric', 'conv');  % builds the test input only
        [~, periodic] = imageQuality(motionRestore(g, p, 'wiener', 1e-3, 'periodic'), f);
        [~, taper] = imageQuality(motionRestore(g, p, 'wiener', 1e-3, 'taper'), f);
        verifyGreaterThan(tc, taper, periodic + 3, sprintf('taper, theta = %d', theta));
        if theta == 0
            [~, mirror] = imageQuality(motionRestore(g, p, 'wiener', 1e-3, 'mirror'), f);
            verifyGreaterThan(tc, mirror, periodic + 3, 'mirror, theta = 0');
        end
    end
end

function testColourWithEveryBorder(tc)
    g = rand(31, 36, 3);
    p = motionPSF(7, -25);
    for border = {'periodic', 'taper', 'mirror'}
        f = verifyWarningFree(tc, @() motionRestore(g, p, 'wiener', 0.01, border{1}));
        verifySize(tc, f, [31 36 3]);
        verifyTrue(tc, isreal(f), border{1});
    end
end

function testBadBorderErrors(tc)
    verifyError(tc, @() motionRestore(rand(8), 1, 'wiener', 0.1, 'zero'), ...
        'MATLAB:validators:mustBeMember');
end
