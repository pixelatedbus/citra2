function tests = test_FreqApp
% Tests for the FreqApp window and the tab contract. Opens a real window.
% Run: runtests('tests/test_FreqApp.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    % Small test images, written once to a temporary folder.
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    tc.TestData.grey = fullfile(d, 'grey.png');
    tc.TestData.rgb  = fullfile(d, 'rgb.png');
    tc.TestData.cmyk = fullfile(d, 'cmyk.tif');
    imwrite(uint8(255 * rand(40, 50)), tc.TestData.grey);
    imwrite(uint8(255 * rand(41, 51, 3)), tc.TestData.rgb);
    imwrite(uint8(255 * rand(10, 10, 4)), tc.TestData.cmyk);
end

function setup(tc)
    tc.TestData.app = FreqApp();
end

function teardown(tc)
    if isvalid(tc.TestData.app)
        delete(tc.TestData.app);
    end
end

function testFiveTabsEachWithALayout(tc)
    app = tc.TestData.app;
    verifyEqual(tc, fieldnames(app.Tabs)', {'B', 'C', 'D', 'E', 'F'});
    for p = {'B', 'C', 'D', 'E', 'F'}
        nAxes = numel(findobj(app.Tabs.(p{1}), 'Type', 'axes'));
        verifyGreaterThanOrEqual(tc, nAxes, 5, ['tab ' p{1}]);
    end
end

function testLoadUpdatesEveryTab(tc)
    % After a load, each tab shows the input and its spectrum: 2 images.
    app = tc.TestData.app;
    app.loadImage(tc.TestData.rgb);
    verifySize(tc, app.Image, [41 51 3]);
    for p = {'B', 'C', 'D', 'E', 'F'}
        verifyEqual(tc, numel(findobj(app.Tabs.(p{1}), 'Type', 'image')), 2, ['tab ' p{1}]);
    end
    app.loadImage(tc.TestData.grey);
    verifySize(tc, app.Image, [40 50]);
end

function testBadFileKeepsPreviousImage(tc)
    app = tc.TestData.app;
    app.loadImage(tc.TestData.grey);
    verifyError(tc, @() app.loadImage(tc.TestData.cmyk), 'readImageFile:channels');
    verifySize(tc, app.Image, [40 50]);
    verifyEqual(tc, app.ImagePath, tc.TestData.grey);
end

function testClosingWindowDeletesApp(tc)
    app = tc.TestData.app;
    delete(app.Fig);
    verifyFalse(tc, isvalid(app));
end

function testDeletingAppClosesWindow(tc)
    app = tc.TestData.app;
    fig = app.Fig;
    delete(app);
    verifyFalse(tc, isvalid(fig));
end
