function tests = test_homomorphicBrightness
% Tests for homomorphicBrightness. Run: runtests('tests/test_homomorphicBrightness.m')
tests = functiontests(localfunctions);
end

function testGeometricMeanHitsTarget(tc)
    rng(11);
    eps0 = 1 / 255;
    for f = {0.2 * rand(40, 44), 0.3 * rand(33, 31, 3)}
        for D0 = [0 5]
            g = homomorphicBrightness(f{1}, 0.8, 0.9, D0, 0.4);
            verifyEqual(tc, exp(mean(log(g + eps0), 'all')), 0.4, 'RelTol', 1e-10);
        end
    end
end

function testIdentitySetting(tc)
    % gL = gH = 1 and t = the input's own geometric mean: nothing changes.
    rng(12);
    f = rand(24, 30, 3);
    t = exp(mean(log(f + 1/255), 'all'));
    verifyEqual(tc, homomorphicBrightness(f, 1, 1, 0, t), f, 'AbsTol', 1e-12);
end

function testDcOnlyIsPowerLaw(tc)
    % With D0 = 0 and gL = gH = gam, the filter is b * (f + eps0)^gam - eps0:
    % the inverse of a power-law darkening, done on the log spectrum.
    rng(13);
    eps0 = 1 / 255;
    f = 0.25 * rand(20, 22);
    gam = 0.8;
    t = 0.35;
    g = homomorphicBrightness(f, gam, gam, 0, t);
    z = log(f + eps0);
    expected = exp(gam * z + log(t) - gam * mean(z, 'all')) - eps0;
    verifyEqual(tc, g, expected, 'AbsTol', 1e-12);
end

function testUndoesPowerLawDarkening(tc)
    % Darken a clean image as dark = c * ref^gamma and restore it.
    rng(14);
    ref = 0.2 + 0.8 * applyFilter(rand(64, 64, 3), lowpassH(64, 64, 'gaussian', 8));
    ref = min(max(ref, 0), 1);
    dark = 0.3 * ref.^1.3;
    t = exp(mean(log(ref + 1/255), 'all'));
    [~, before] = imageQuality(dark, ref);
    [~, after] = imageQuality(homomorphicBrightness(dark, 1/1.3, 1/1.3, 0, t), ref);
    verifyGreaterThan(tc, after, 40);
    verifyGreaterThan(tc, after, before + 20);
end

function testColourRatiosKeptWhenGainIsOne(tc)
    % gL = gH = 1: every channel is scaled by the same factor (+ eps0 offset).
    rng(15);
    eps0 = 1 / 255;
    f = 0.2 * rand(16, 18, 3);
    g = homomorphicBrightness(f, 1, 1, 0, 0.5);
    ratio = (g + eps0) ./ (f + eps0);
    verifyEqual(tc, ratio, ratio(1) * ones(size(f)), 'RelTol', 1e-10);
    verifyGreaterThan(tc, mean(g(:)), mean(f(:)));
end

function testOutputsForDisplay(tc)
    f = rand(10, 12, 3);
    [~, H, Zin, Zout] = homomorphicBrightness(f, 0.7, 1.1, 2, 0.5);
    verifyEqual(tc, H, brightnessH(10, 12, 0.7, 1.1, 2));
    verifySize(tc, Zin, [10 12 3]);
    verifySize(tc, Zout, [10 12 3]);
end

function testBadTargetErrors(tc)
    verifyError(tc, @() homomorphicBrightness(rand(4), 1, 1, 0, 0), 'MATLAB:validators:mustBePositive');
    verifyError(tc, @() homomorphicBrightness(rand(4), 1, 1, 0, 1.5), 'MATLAB:validators:mustBeLessThanOrEqual');
end
