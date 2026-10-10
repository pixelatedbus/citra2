function tests = test_tabE
% GUI tests for tab E: drives the real controls and compares with the core functions.
% Run: runtests('tests/test_tabE.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    % Fake part folder: reference + reference with a planted cosine.
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'reference'));
    rng(14);
    M = 40; N = 48;
    ref = 0.3 + 0.4 * rand(M, N);
    [x, y] = meshgrid(0:N-1, 0:M-1);
    noisy = ref + 0.2 * cos(2 * pi * (5 * y / M + 8 * x / N));
    imwrite(ref, fullfile(d, 'reference', 'tile_gray.png'));
    imwrite(noisy, fullfile(d, 'input', 'tile_gray_periodic_noise.png'));
    tc.TestData.input = fullfile(d, 'input', 'tile_gray_periodic_noise.png');
end

function setup(tc)
    tc.TestData.app = FreqApp();
    tc.TestData.app.loadImage(tc.TestData.input);
end

function teardown(tc)
    delete(tc.TestData.app);
end

function testNotchMatchesCoreAndRestores(tc)
    app = tc.TestData.app;
    setField(app, 1, 'notch');
    setField(app, 2, 'ideal');
    t = notchTableOf(app);
    t.Data = [5 8 1];
    press(app, 'Apply');
    [M, N] = size(app.Image);
    H = notchRejectH(M, N, 'ideal', [5 8 1]);
    verifyEqual(tc, imageIn(app, 'Mask H(u,v)'), H);
    verifyEqual(tc, imageIn(app, 'Restored'), min(max(applyFilter(app.Image, H), 0), 1), 'AbsTol', 1e-12);
    txt = paramsLabel(app).Text;
    verifySubstring(tc, txt, 'Notch reject, ideal: (5, 8) r=1');
    % The planted cosine is removed, so PSNR goes up a lot.
    tokens = regexp(txt, 'input ([\d.]+) dB -> result ([\d.]+) dB', 'tokens', 'once');
    verifyGreaterThan(tc, str2double(tokens{2}), str2double(tokens{1}) + 10);
end

function testBandrejectMatchesCore(tc)
    app = tc.TestData.app;
    setField(app, 1, 'band');
    setField(app, 2, 'butterworth');
    setField(app, 3, 3);       % n
    setField(app, 4, 9);       % D0
    setField(app, 5, 2);       % W
    press(app, 'Apply');
    [M, N] = size(app.Image);
    H = bandrejectH(M, N, 'butterworth', 9, 2, 3);
    verifyEqual(tc, imageIn(app, 'Mask H(u,v)'), H, 'AbsTol', 1e-12);
    verifySubstring(tc, paramsLabel(app).Text, 'Bandreject, butterworth n = 3: D0 = 9, W = 2');
end

function testEnableFollowsFilterAndShape(tc)
    app = tc.TestData.app;
    setField(app, 1, 'notch');
    verifyEqual(tc, string(notchTableOf(app).Enable), "on");
    verifyFalse(tc, logical(fieldInRow(app, 4).Enable));
    setField(app, 1, 'band');
    verifyEqual(tc, string(notchTableOf(app).Enable), "off");
    verifyTrue(tc, logical(fieldInRow(app, 5).Enable));
    setField(app, 2, 'gaussian');
    verifyFalse(tc, logical(fieldInRow(app, 3).Enable));
end

function testAddAndRemoveRows(tc)
    app = tc.TestData.app;
    press(app, 'Add notch');
    press(app, 'Add notch');
    t = notchTableOf(app);
    verifyEqual(tc, t.Data, [0 0 3; 0 0 3]);
    t.Selection = [1 2];                              % select row 1
    t.SelectionChangedFcn(t, []);
    press(app, 'Remove selected');
    verifySize(tc, t.Data, [1 3]);
end

function testBadRadiusDoesNotCrash(tc)
    app = tc.TestData.app;
    setField(app, 1, 'notch');
    t = notchTableOf(app);
    t.Data = [5 8 0];                                 % radius 0 is invalid
    press(app, 'Apply');                              % shows an alert, no error
    verifyEmpty(tc, findobj(axesTitled(app, 'Restored'), 'Type', 'image'));
end

% ---- helpers: find tab E's controls -----------------------------------
function grid = controlsGrid(app)
    grid = findobj(app.Tabs.E, 'Type', 'uipanel', 'Title', 'Parameters').Children;
end

function c = fieldInRow(app, row)
    % Column-2 field of a row: 1 filter, 2 shape, 3 n, 4 D0, 5 W.
    kids = controlsGrid(app).Children;
    c = kids(arrayfun(@(k) isequal(k.Layout.Row, row) && isequal(k.Layout.Column, 2), kids));
end

function t = notchTableOf(app)
    t = findobj(app.Tabs.E, 'Type', 'uitable');
end

function setField(app, row, value)
    c = fieldInRow(app, row);
    c.Value = value;
    if ~isempty(c.ValueChangedFcn)
        c.ValueChangedFcn(c, []);
    end
end

function press(app, text)
    b = findobj(app.Tabs.E, 'Type', 'uibutton', 'Text', text);
    b.ButtonPushedFcn(b, []);
end

function ax = axesTitled(app, titleText)
    axs = findobj(app.Tabs.E, 'Type', 'axes');
    ax = axs(arrayfun(@(a) strcmp(a.Title.String, titleText), axs));
end

function img = imageIn(app, titleText)
    img = findobj(axesTitled(app, titleText), 'Type', 'image').CData;
end

function lbl = paramsLabel(app)
    labels = findobj(app.Tabs.E, 'Type', 'uilabel');
    lbl = labels(startsWith({labels.Text}, 'Parameters:'));
end
