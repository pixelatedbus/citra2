function tests = test_scoreAgainstReference
% Tests for scoreAgainstReference. Builds a fake part folder in a temporary folder.
% Run: runtests('tests/test_scoreAgainstReference.m')
tests = functiontests(localfunctions);
end

function setup(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'reference'));
    imwrite(uint8(zeros(4, 5)), fullfile(d, 'reference', 'flat_gray.png'));
    tc.TestData.dir = d;
end

function testScoresWhenReferenceMatches(tc)
    img = 0.1 * ones(4, 5);   % every pixel 0.1 off the black reference
    [mse, psnr] = scoreAgainstReference(img, tc.TestData.dir, 'flat_gray_noise.png');
    verifyEqual(tc, mse, 0.01, 'AbsTol', 1e-15);
    verifyEqual(tc, psnr, 20, 'AbsTol', 1e-12);
end

function testNaNWithoutReference(tc)
    [mse, psnr] = scoreAgainstReference(zeros(4, 5), tc.TestData.dir, 'other.png');
    verifyTrue(tc, isnan(mse) && isnan(psnr));
end

function testNaNWhenSizesDiffer(tc)
    [mse, psnr] = scoreAgainstReference(zeros(4, 5, 3), tc.TestData.dir, 'flat_gray_noise.png');
    verifyTrue(tc, isnan(mse) && isnan(psnr));
end
