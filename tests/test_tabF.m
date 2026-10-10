function tests = test_tabF
% GUI tests for tab F: drives the real controls and compares with the core functions.
% Run: runtests('tests/test_tabF.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    % Fake part folder: a reference and its circular motion blur, named
    % like the official images so L and theta come from the name.
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'reference'));
    rng(19);
    ref = applyFilter(rand(48, 52), lowpassH(48, 52, 'gaussian', 8));
    ref = (ref - min(ref(:))) / (max(ref(:)) - min(ref(:)));
    imwrite(ref, fullfile(d, 'reference', 'tile_gray.png'));
    imwrite(min(max(motionDegrade(ref, motionPSF(7, 30)), 0), 1), ...
        fullfile(d, 'input', 'tile_gray_motion_L7_A30.png'));
    tc.TestData.input = fullfile(d, 'input', 'tile_gray_motion_L7_A30.png');
end

function setup(tc)
    tc.TestData.app = FreqApp();
    tc.TestData.app.loadImage(tc.TestData.input);
end

function teardown(tc)
    delete(tc.TestData.app);
end

function testParametersFromFileName(tc)
    app = tc.TestData.app;
    verifyEqual(tc, fieldInRow(app, 1).Value, 7);
    verifyEqual(tc, fieldInRow(app, 2).Value, 30);
end

function testResultsMatchCore(tc)
    app = tc.TestData.app;
    setField(app, 3, 'threshold');
    setField(app, 4, 0.05);       % t
    setField(app, 6, 0.001);      % K
    setField(app, 7, 'periodic');
    press(app, 'Apply');
    psf = motionPSF(7, 30);
    [fInv, H] = motionRestore(app.Image, psf, 'threshold', 0.05, 'periodic');
    fW = motionRestore(app.Image, psf, 'wiener', 0.001, 'periodic');
    verifyEqual(tc, imageIn(app, 'Inverse filter'), min(max(fInv, 0), 1), 'AbsTol', 1e-12);
    verifyEqual(tc, imageIn(app, 'Wiener filter'), min(max(fW, 0), 1), 'AbsTol', 1e-12);
    verifyEqual(tc, imageIn(app, '|H(u,v)|'), min(abs(H), 1), 'AbsTol', 1e-12);
    txt = paramsLabel(app).Text;
    verifySubstring(tc, txt, 'L = 7, theta = 30; inverse: threshold t = 0.05; Wiener K = 0.001; border: periodic');
    % Circular blur, no noise: both restorations beat the degraded image.
    tokens = regexp(txt, 'degraded ([\d.]+), inverse ([\d.]+), Wiener ([\d.]+) dB', 'tokens', 'once');
    values = str2double(tokens);
    verifyGreaterThan(tc, values(2), values(1) + 5);
    verifyGreaterThan(tc, values(3), values(1) + 5);
end

function testSimulateUsesLoadedImageAsOriginal(tc)
    app = tc.TestData.app;
    setField(app, 8, true);       % simulate
    setField(app, 9, 0.01);       % sigma
    press(app, 'Apply');
    psf = motionPSF(7, 30);
    g = motionDegrade(app.Image, psf, 0.01);
    verifyEqual(tc, imageIn(app, 'Degraded (simulated, sigma = 0.01)'), min(max(g, 0), 1), 'AbsTol', 1e-12);
    verifyEqual(tc, imageIn(app, 'Original (loaded image)'), app.Image);
    verifySubstring(tc, paramsLabel(app).Text, 'simulated noise sigma = 0.01');
end

function testEnableFollowsMode(tc)
    app = tc.TestData.app;
    setField(app, 3, 'radius');
    verifyFalse(tc, logical(fieldInRow(app, 4).Enable));
    verifyTrue(tc, logical(fieldInRow(app, 5).Enable));
    setField(app, 3, 'threshold');
    verifyTrue(tc, logical(fieldInRow(app, 4).Enable));
    verifyFalse(tc, logical(fieldInRow(app, 9).Enable));
end

function testNoImageDoesNotCrash(tc)
    app = tc.TestData.app;
    app.Image = [];
    press(app, 'Apply');                              % shows an alert, no error
    verifyEmpty(tc, findobj(axesTitled(app, 'Wiener filter'), 'Type', 'image'));
end

% ---- helpers: find tab F's controls -----------------------------------
function grid = controlsGrid(app)
    grid = findobj(app.Tabs.F, 'Type', 'uipanel', 'Title', 'Parameters').Children;
end

function c = fieldInRow(app, row)
    % Field of a row: 1 L, 2 theta, 3 mode, 4 t, 5 R0, 6 K, 7 border, 8 simulate, 9 sigma.
    kids = controlsGrid(app).Children;
    isField = @(k) isequal(k.Layout.Row, row) && ~isa(k, 'matlab.ui.control.Label');
    c = kids(arrayfun(isField, kids));
end

function setField(app, row, value)
    c = fieldInRow(app, row);
    c.Value = value;
    if ~isempty(c.ValueChangedFcn)
        c.ValueChangedFcn(c, []);
    end
end

function press(app, text)
    b = findobj(app.Tabs.F, 'Type', 'uibutton', 'Text', text);
    b.ButtonPushedFcn(b, []);
end

function ax = axesTitled(app, titleText)
    axs = findobj(app.Tabs.F, 'Type', 'axes');
    ax = axs(arrayfun(@(a) strcmp(a.Title.String, titleText), axs));
end

function img = imageIn(app, titleText)
    img = findobj(axesTitled(app, titleText), 'Type', 'image').CData;
end

function lbl = paramsLabel(app)
    labels = findobj(app.Tabs.F, 'Type', 'uilabel');
    lbl = labels(startsWith({labels.Text}, 'Parameters:'));
end
