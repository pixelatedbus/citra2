function tests = test_tabD
% GUI tests for tab D: drives the real controls and compares with the core functions.
% Run: runtests('tests/test_tabD.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    % Fake part folder: a reference and a power-law darkened input.
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'reference'));
    rng(16);
    ref = 0.3 + 0.6 * rand(36, 44, 3);
    imwrite(ref, fullfile(d, 'reference', 'tile_color.png'));
    imwrite(0.3 * ref.^1.3, fullfile(d, 'input', 'tile_color_dark.png'));
    tc.TestData.input = fullfile(d, 'input', 'tile_color_dark.png');
end

function setup(tc)
    tc.TestData.app = FreqApp();
    tc.TestData.app.loadImage(tc.TestData.input);
end

function teardown(tc)
    delete(tc.TestData.app);
end

function testHomomorphicMatchesCore(tc)
    app = tc.TestData.app;
    setField(app, 1, 'homomorphic');
    setField(app, 2, 0.5);     % t
    setField(app, 3, 0.75);    % gL
    setField(app, 4, 0.8);     % gH
    setField(app, 6, 0);       % D0
    press(app, 'Apply');
    expected = homomorphicBrightness(app.Image, 0.75, 0.8, 0, 0.5);
    verifyEqual(tc, imageIn(app, 'Result'), min(max(expected, 0), 1), 'AbsTol', 1e-12);
    txt = paramsLabel(app).Text;
    verifySubstring(tc, txt, 'Homomorphic, t = 0.5, gL = 0.75, gH = 0.8, D0 = 0');
    % Brighter, and much closer to the reference.
    tokens = regexp(txt, 'mean ([\d.]+) -> ([\d.]+)', 'tokens', 'once');
    verifyGreaterThan(tc, str2double(tokens{2}), 2 * str2double(tokens{1}));
    tokens = regexp(txt, 'input ([\d.]+) dB -> result ([\d.]+) dB', 'tokens', 'once');
    verifyGreaterThan(tc, str2double(tokens{2}), str2double(tokens{1}) + 10);
end

function testEmphasisMatchesCore(tc)
    app = tc.TestData.app;
    setField(app, 1, 'emphasis');
    setField(app, 5, 2.5);     % k
    setField(app, 6, 4);       % D0
    press(app, 'Apply');
    [M, N, ~] = size(app.Image);
    H = brightnessH(M, N, 2.5, 1, 4);
    verifyEqual(tc, imageIn(app, 'Result'), min(max(applyFilter(app.Image, H), 0), 1), 'AbsTol', 1e-12);
    verifyEqual(tc, imageIn(app, sprintf('H(u,v) / %.3g', 2.5)), H / 2.5, 'AbsTol', 1e-12);
    verifySubstring(tc, paramsLabel(app).Text, 'Low-frequency emphasis, k = 2.5, D0 = 4');
end

function testEnableFollowsMethod(tc)
    app = tc.TestData.app;
    setField(app, 1, 'emphasis');
    verifyFalse(tc, logical(fieldInRow(app, 2).Enable));
    verifyTrue(tc, logical(fieldInRow(app, 5).Enable));
    setField(app, 1, 'homomorphic');
    verifyTrue(tc, logical(fieldInRow(app, 3).Enable));
    verifyFalse(tc, logical(fieldInRow(app, 5).Enable));
end

function testNoImageDoesNotCrash(tc)
    app = tc.TestData.app;
    app.Image = [];                                   % as before the first load
    press(app, 'Apply');                              % shows an alert, no error
    verifyEmpty(tc, findobj(axesTitled(app, 'Result'), 'Type', 'image'));
end

% ---- helpers: find tab D's controls -----------------------------------
function grid = controlsGrid(app)
    grid = findobj(app.Tabs.D, 'Type', 'uipanel', 'Title', 'Parameters').Children;
end

function c = fieldInRow(app, row)
    % Column-2 field of a row: 1 method, 2 t, 3 gL, 4 gH, 5 k, 6 D0.
    kids = controlsGrid(app).Children;
    c = kids(arrayfun(@(k) isequal(k.Layout.Row, row) && isequal(k.Layout.Column, 2), kids));
end

function setField(app, row, value)
    c = fieldInRow(app, row);
    c.Value = value;
    if ~isempty(c.ValueChangedFcn)
        c.ValueChangedFcn(c, []);
    end
end

function press(app, text)
    b = findobj(app.Tabs.D, 'Type', 'uibutton', 'Text', text);
    b.ButtonPushedFcn(b, []);
end

function ax = axesTitled(app, titleText)
    axs = findobj(app.Tabs.D, 'Type', 'axes');
    ax = axs(arrayfun(@(a) strcmp(a.Title.String, titleText), axs));
end

function img = imageIn(app, titleText)
    img = findobj(axesTitled(app, titleText), 'Type', 'image').CData;
end

function lbl = paramsLabel(app)
    labels = findobj(app.Tabs.D, 'Type', 'uilabel');
    lbl = labels(startsWith({labels.Text}, 'Parameters:'));
end
