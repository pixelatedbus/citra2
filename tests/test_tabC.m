function tests = test_tabC
% GUI tests for tab C: drives the real controls and compares with the core functions.
% Run: runtests('tests/test_tabC.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    tc.TestData.input = fullfile(fixture.Folder, 'tile_color.png');
    rng(12);
    imwrite(rand(30, 40, 3), tc.TestData.input);
end

function setup(tc)
    tc.TestData.app = FreqApp();
    tc.TestData.app.loadImage(tc.TestData.input);
end

function teardown(tc)
    delete(tc.TestData.app);
end

function testApplyMatchesCoreFunctions(tc)
    app = tc.TestData.app;
    for type = {'ideal', 'gaussian', 'butterworth'}
        setControl(app, 1, type{1});
        setControl(app, 2, 6);    % D0
        setControl(app, 3, 3);    % n
        press(app, 'Apply');

        [M, N, ~] = size(app.Image);
        H = highpassH(M, N, type{1}, 6, 3);
        g = applyFilter(app.Image, H);
        verifyEqual(tc, imageIn(app, 'Result'), min(max(highpassDisplay(g, 'abs-normalized'), 0), 1), ...
            'AbsTol', 1e-12, type{1});
        verifyEqual(tc, imageIn(app, 'H(u,v)'), H, 'AbsTol', 1e-12, type{1});
    end
end

function testDisplayModeRedrawsWithoutApply(tc)
    app = tc.TestData.app;
    setControl(app, 1, 'gaussian');
    setControl(app, 2, 6);
    press(app, 'Apply');
    setControl(app, 4, 'rescale');            % changing the mode alone updates the view
    [M, N, ~] = size(app.Image);
    g = applyFilter(app.Image, highpassH(M, N, 'gaussian', 6));
    verifyEqual(tc, imageIn(app, 'Result'), highpassDisplay(g, 'rescale'), 'AbsTol', 1e-12);
    verifySubstring(tc, paramsLabel(app).Text, 'GHPF, D0 = 6  |  display: rescale');
end

function testNOnlyEnabledForButterworth(tc)
    app = tc.TestData.app;
    setControl(app, 1, 'ideal');
    verifyFalse(tc, logical(fieldInRow(app, 3).Enable));
    setControl(app, 1, 'butterworth');
    verifyTrue(tc, logical(fieldInRow(app, 3).Enable));
end

% ---- helpers: find tab C's controls -----------------------------------
function c = fieldInRow(app, row)
    % Field in column 2 of the Parameters grid: 1 type, 2 D0, 3 n, 4 display.
    grid = findobj(app.Tabs.C, 'Type', 'uipanel', 'Title', 'Parameters').Children;
    kids = grid.Children;
    c = kids(arrayfun(@(k) isequal(k.Layout.Row, row) && isequal(k.Layout.Column, 2), kids));
end

function setControl(app, row, value)
    c = fieldInRow(app, row);
    c.Value = value;
    if ~isempty(c.ValueChangedFcn)
        c.ValueChangedFcn(c, []);
    end
end

function press(app, text)
    b = findobj(app.Tabs.C, 'Type', 'uibutton', 'Text', text);
    b.ButtonPushedFcn(b, []);
end

function img = imageIn(app, titleText)
    axs = findobj(app.Tabs.C, 'Type', 'axes');
    ax = axs(arrayfun(@(a) strcmp(a.Title.String, titleText), axs));
    img = findobj(ax, 'Type', 'image').CData;
end

function lbl = paramsLabel(app)
    labels = findobj(app.Tabs.C, 'Type', 'uilabel');
    lbl = labels(startsWith({labels.Text}, 'Parameters:'));
end
