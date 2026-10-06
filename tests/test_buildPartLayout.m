function tests = test_buildPartLayout
% Tests for buildPartLayout. Runs headless with a hidden window.
% Run: runtests('tests/test_buildPartLayout.m')
tests = functiontests(localfunctions);
end

function setup(tc)
    tc.TestData.fig = uifigure('Visible', 'off');
    tc.TestData.tab = uitab(uitabgroup(tc.TestData.fig));
end

function teardown(tc)
    delete(tc.TestData.fig);
end

function testFieldsAndTypes(tc)
    L = buildPartLayout(tc.TestData.tab, {'Input', 'Spectrum', 'H(u,v)', 'Result'});
    verifyClass(tc, L.Controls, 'matlab.ui.container.GridLayout');
    verifyClass(tc, L.Apply, 'matlab.ui.control.Button');
    verifyClass(tc, L.Save, 'matlab.ui.control.Button');
    verifyClass(tc, L.Params, 'matlab.ui.control.Label');
    verifySize(tc, L.Axes, [1 4]);
    verifyEqual(tc, arrayfun(@(a) string(a.Title.String), L.Axes), ...
        ["Input", "Spectrum", "H(u,v)", "Result"]);
end

function testAxesGridShape(tc)
    % [number of titles, expected rows, expected columns]
    cases = [2 1 2; 3 1 3; 4 2 2; 5 2 3; 7 2 4; 9 3 3];
    for k = 1:size(cases, 1)
        tab = uitab(tc.TestData.tab.Parent);
        titles = compose("ax%d", 1:cases(k, 1));
        L = buildPartLayout(tab, titles);
        grid = L.Axes(1).Parent;
        verifyEqual(tc, [numel(grid.RowHeight) numel(grid.ColumnWidth)], cases(k, 2:3), ...
            sprintf('%d axes', cases(k, 1)));
    end
end

function testControlsAreAddedInOrderWithFitRows(tc)
    % A tab adds label/field pairs; they fill row by row and rows stay 'fit'.
    L = buildPartLayout(tc.TestData.tab, {'a', 'b'});
    uilabel(L.Controls, 'Text', 'D0');
    f1 = uieditfield(L.Controls, 'numeric');
    uilabel(L.Controls, 'Text', 'n');
    f2 = uieditfield(L.Controls, 'numeric');
    verifyEqual(tc, [f1.Layout.Row f1.Layout.Column], [1 2]);
    verifyEqual(tc, [f2.Layout.Row f2.Layout.Column], [2 2]);
    verifyTrue(tc, all(strcmp(L.Controls.RowHeight, 'fit')));
end
