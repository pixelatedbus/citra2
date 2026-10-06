function tests = test_findReference
% Tests for findReference. Builds a fake part folder in a temporary folder.
% Run: runtests('tests/test_findReference.m')
tests = functiontests(localfunctions);
end

function setup(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'reference'));
    for name = {'astronaut_color', 'coins_gray', 'coins_gray_big', 'retina_color'}
        imwrite(zeros(2, 'uint8'), fullfile(d, 'reference', [name{1} '.png']));
    end
    tc.TestData.dir = d;
end

function testNamesFromTheOfficialData(tc)
    d = tc.TestData.dir;
    cases = {
        'astronaut_color_gaussian_noise.png',              'astronaut_color.png'
        'astronaut_color_motion_L19_A20.png',              'astronaut_color.png'
        'retina_color_motion_L15_A-25_gaussian_noise.png', 'retina_color.png'
        'coins_gray_dark.png',                             'coins_gray.png'
        };
    for k = 1:size(cases, 1)
        verifyEqual(tc, findReference(d, cases{k, 1}), ...
            fullfile(d, 'reference', cases{k, 2}), cases{k, 1});
    end
end

function testLongestMatchWins(tc)
    d = tc.TestData.dir;
    verifyEqual(tc, findReference(d, 'coins_gray_big_dark.png'), ...
        fullfile(d, 'reference', 'coins_gray_big.png'));
end

function testExactNameAndFullPathInput(tc)
    d = tc.TestData.dir;
    verifyEqual(tc, findReference(d, fullfile(d, 'input', 'coins_gray.png')), ...
        fullfile(d, 'reference', 'coins_gray.png'));
end

function testPrefixMustEndAtUnderscore(tc)
    % "coins_grayish" must not match "coins_gray".
    verifyEqual(tc, findReference(tc.TestData.dir, 'coins_grayish.png'), '');
end

function testNoReferenceFolder(tc)
    % Part C has no reference/ folder.
    verifyEqual(tc, findReference(fullfile(tc.TestData.dir, 'reference'), 'coins_gray.png'), '');
end
