function tests = test_readImageFile
% Tests for readImageFile. Writes small images to a temporary folder.
% Run: runtests('tests/test_readImageFile.m')
tests = functiontests(localfunctions);
end

function setup(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    tc.TestData.dir = fixture.Folder;
end

function testGrey8And16Bit(tc)
    p8 = fullfile(tc.TestData.dir, 'g8.png');
    p16 = fullfile(tc.TestData.dir, 'g16.png');
    imwrite(uint8([0 255; 51 102]), p8);
    imwrite(uint16([0 65535; 0 65535]), p16);
    verifyEqual(tc, readImageFile(p8), [0 1; 0.2 0.4], 'AbsTol', 1e-12);
    verifyEqual(tc, readImageFile(p16), [0 1; 0 1]);
end

function testRgbAndAlpha(tc)
    rgb = uint8(255 * rand(6, 7, 3));
    p = fullfile(tc.TestData.dir, 'rgba.png');
    imwrite(rgb, p, 'Alpha', ones(6, 7));
    img = readImageFile(p);
    verifySize(tc, img, [6 7 3]);           % alpha dropped
    verifyEqual(tc, img, im2double(rgb));
end

function testIndexedBecomesRgb(tc)
    map = [0 0 0; 1 0 0; 0 0 1];
    p = fullfile(tc.TestData.dir, 'idx.png');
    imwrite(uint8([0 1; 2 1]), map, p);
    img = readImageFile(p);
    verifySize(tc, img, [2 2 3]);
    verifyEqual(tc, squeeze(img(1, 2, :))', [1 0 0]);   % index 1 -> red
end

function testRejectsFourChannels(tc)
    p = fullfile(tc.TestData.dir, 'cmyk.tif');
    imwrite(uint8(255 * rand(5, 5, 4)), p);
    verifyError(tc, @() readImageFile(p), 'readImageFile:channels');
end

function testMissingFileErrors(tc)
    verifyError(tc, @() readImageFile(fullfile(tc.TestData.dir, 'nope.png')), ?MException);
end
