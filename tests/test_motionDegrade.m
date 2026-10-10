function tests = test_motionDegrade
% Tests for motionDegrade. Run: runtests('tests/test_motionDegrade.m')
tests = functiontests(localfunctions);
end

function testNoiseFreeIsCircularBlur(tc)
    rng(18);
    f = rand(30, 34, 3);
    p = motionPSF(9, 20);
    verifyEqual(tc, motionDegrade(f, p), applyFilter(f, psf2H(p, 30, 34)), 'AbsTol', 1e-15);
end

function testNoiseLevelAndSeed(tc)
    f = 0.5 * ones(200, 200);
    g1 = motionDegrade(f, motionPSF(5, 0), 0.02, 3);
    g2 = motionDegrade(f, motionPSF(5, 0), 0.02, 3);
    verifyEqual(tc, g1, g2);                              % same seed, same noise
    verifyEqual(tc, std(g1(:)), 0.02, 'RelTol', 0.05);
end

function testGlobalRandomStateKept(tc)
    rng(5);
    expected = rand;
    rng(5);
    motionDegrade(rand(8), 1, 0.1, 9);
    verifyNotEqual(tc, rand, expected);                  % rand(8) above used the stream
    rng(5);
    rand(8);
    after = rand;
    rng(5);
    rand(8);
    motionDegrade(zeros(4), 1, 0.1, 9);
    verifyEqual(tc, rand, after);                        % noise did not touch the stream
end
