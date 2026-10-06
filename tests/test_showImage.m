function tests = test_showImage
% Tests for showImage. Runs headless with a hidden window.
% Run: runtests('tests/test_showImage.m')
tests = functiontests(localfunctions);
end

function setup(tc)
    tc.TestData.fig = uifigure('Visible', 'off');
    tc.TestData.ax = uiaxes(tc.TestData.fig);
end

function teardown(tc)
    delete(tc.TestData.fig);
end

function testGreyAndColour(tc)
    ax = tc.TestData.ax;
    showImage(ax, rand(10, 12), 'grey');
    verifySize(tc, findobj(ax, 'Type', 'image').CData, [10 12]);
    showImage(ax, rand(10, 12, 3), 'colour');
    verifySize(tc, findobj(ax, 'Type', 'image').CData, [10 12 3]);
    verifyEqual(tc, ax.Title.String, 'colour');
end

function testClipsForDisplayOnly(tc)
    ax = tc.TestData.ax;
    img = [-0.5 0.5; 1.5 1];
    showImage(ax, img, 'clipped');
    verifyEqual(tc, findobj(ax, 'Type', 'image').CData, [0 0.5; 1 1]);
    verifyEqual(tc, img, [-0.5 0.5; 1.5 1]);   % caller's data unchanged
end

function testEmptyClearsButKeepsTitle(tc)
    ax = tc.TestData.ax;
    showImage(ax, rand(5), 'before');
    showImage(ax, [], 'No image loaded');
    verifyEmpty(tc, findobj(ax, 'Type', 'image'));
    verifyEqual(tc, ax.Title.String, 'No image loaded');
end

function testLogicalMaskIsAccepted(tc)
    ax = tc.TestData.ax;
    showImage(ax, magic(4) > 8, 'mask');
    verifyEqual(tc, class(findobj(ax, 'Type', 'image').CData), 'double');
end

function testRejectsComplex(tc)
    verifyError(tc, @() showImage(tc.TestData.ax, complex(rand(4), 1)), 'showImage:complex');
end
