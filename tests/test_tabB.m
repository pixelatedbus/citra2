function tests = test_tabB
% GUI tests for tab B: drives the real controls and compares with the core functions.
% Run: runtests('tests/test_tabB.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    % A fake part folder: input with noise + its reference, so PSNR is shown.
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'reference'));
    rng(10);
    ref = rand(30, 40, 3);
    noisy = min(max(ref + 0.1 * randn(size(ref)), 0), 1);
    imwrite(ref, fullfile(d, 'reference', 'tile_color.png'));
    imwrite(noisy, fullfile(d, 'input', 'tile_color_gaussian_noise.png'));
    tc.TestData.input = fullfile(d, 'input', 'tile_color_gaussian_noise.png');
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
        setControl(app, 2, 7);    % D0
        setControl(app, 3, 3);    % n
        press(app, 'Apply');

        [M, N, ~] = size(app.Image);
        H = lowpassH(M, N, type{1}, 7, 3);
        expected = applyFilter(app.Image, H);
        verifyEqual(tc, imageIn(app, 'Result'), min(max(expected, 0), 1), 'AbsTol', 1e-12, type{1});
        verifyEqual(tc, imageIn(app, 'H(u,v)'), H, 'AbsTol', 1e-12, type{1});
    end
end

function testParamsLineShowsSettingsAndPsnr(tc)
    app = tc.TestData.app;
    setControl(app, 1, 'butterworth');
    setControl(app, 2, 12);
    setControl(app, 3, 4);
    press(app, 'Apply');
    txt = paramsLabel(app).Text;
    verifySubstring(tc, txt, 'BLPF, D0 = 12, n = 4');
    verifySubstring(tc, txt, 'PSNR vs reference: input');
end

function testNOnlyEnabledForButterworth(tc)
    app = tc.TestData.app;
    nField = fieldInRow(app, 3);
    setControl(app, 1, 'ideal');
    verifyFalse(tc, logical(nField.Enable));
    setControl(app, 1, 'butterworth');
    verifyTrue(tc, logical(nField.Enable));
end

function testNewImageClearsResult(tc)
    app = tc.TestData.app;
    press(app, 'Apply');
    app.loadImage(tc.TestData.input);
    verifyEmpty(tc, findobj(axesTitled(app, 'Result'), 'Type', 'image'));
    verifyEqual(tc, paramsLabel(app).Text, 'Parameters: (press Apply)');
end

% ---- helpers: find tab B's controls -----------------------------------
function c = fieldInRow(app, row)
    % The field (column 2) in the given row of the Parameters grid:
    % row 1 filter type, row 2 D0, row 3 n.
    grid = findobj(app.Tabs.B, 'Type', 'uipanel', 'Title', 'Parameters').Children;
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
    b = findobj(app.Tabs.B, 'Type', 'uibutton', 'Text', text);
    b.ButtonPushedFcn(b, []);
end

function ax = axesTitled(app, titleText)
    axs = findobj(app.Tabs.B, 'Type', 'axes');
    ax = axs(arrayfun(@(a) strcmp(a.Title.String, titleText), axs));
end

function img = imageIn(app, titleText)
    img = findobj(axesTitled(app, titleText), 'Type', 'image').CData;
end

function lbl = paramsLabel(app)
    labels = findobj(app.Tabs.B, 'Type', 'uilabel');
    lbl = labels(startsWith({labels.Text}, 'Parameters:'));
end
