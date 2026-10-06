function L = buildPartLayout(tab, axesTitles)
% BUILDPARTLAYOUT  Standard layout for one part's tab: controls left, axes right.
%
%   Every tab (B to F) uses this so the five tabs look and work the same:
%
%     +-------------------+------------------------------------+
%     | Parameters        |  [axes 1]   [axes 2]   [axes 3]    |
%     |  label  [field]   |  [axes 4]   [axes 5]   ...         |
%     |  label  [field]   |                                    |
%     | [Apply]           |                                    |
%     | [Save result...]  |  Parameters: ...  (L.Params)       |
%     +-------------------+------------------------------------+
%
%   The tab builder then adds its own controls to L.Controls, in order,
%   one label and one field per row (the grid places them automatically).
%   Rows are pre-set to 'fit'; to make one row taller (e.g. a uitable),
%   set L.Controls.RowHeight{r} = 150. Axes are arranged in 1 row for up to
%   3 titles, 2 rows for up to 8, 3 rows beyond that. The callbacks of
%   Apply and Save are wired by the tab builder.
%
%   INPUT
%     tab         the uitab to fill (e.g. app.Tabs.B)
%     axesTitles  titles of the axes, one per axes, cell array or string
%                 array, e.g. {'Input', 'Spectrum', 'H(u,v)', 'Result'}
%
%   OUTPUT
%     L  struct with fields
%        Controls  uigridlayout, 2 columns (label | field), for parameters
%        Apply     uibutton 'Apply'
%        Save      uibutton 'Save result...'
%        Axes      1 x K array of uiaxes, K = numel(axesTitles), titled
%        Params    uilabel under the axes, for the active parameter values

arguments
    tab (1,1) matlab.ui.container.Tab
    axesTitles {mustBeText}
end

axesTitles = cellstr(axesTitles);
K = numel(axesTitles);
maxControlRows = 15;

root = uigridlayout(tab, [1 2]);
root.ColumnWidth = {280, '1x'};

% Left: parameter panel, then the two buttons, then empty space
left = uigridlayout(root, [3 1]);
left.RowHeight = {'fit', 'fit', '1x'};
left.Padding = [0 0 0 0];

panel = uipanel(left, 'Title', 'Parameters');
L.Controls = uigridlayout(panel, [maxControlRows 2]);
L.Controls.ColumnWidth = {'fit', '1x'};
L.Controls.RowHeight = repmat({'fit'}, 1, maxControlRows);

buttons = uigridlayout(left, [2 1]);
buttons.RowHeight = {'fit', 'fit'};
buttons.Padding = [0 0 0 0];
L.Apply = uibutton(buttons, 'Text', 'Apply');
L.Save  = uibutton(buttons, 'Text', 'Save result...');

% Right: axes grid, then the parameter line
right = uigridlayout(root, [2 1]);
right.RowHeight = {'1x', 'fit'};
right.Padding = [0 0 0 0];

if K <= 3
    nRows = 1;
elseif K <= 8
    nRows = 2;
else
    nRows = 3;
end
nCols = ceil(K / nRows);
axesGrid = uigridlayout(right, [nRows nCols]);
axesGrid.Padding = [0 0 0 0];

L.Axes = gobjects(1, K);
for k = 1:K
    L.Axes(k) = uiaxes(axesGrid);
    showImage(L.Axes(k), [], axesTitles{k});
end

L.Params = uilabel(right, 'Text', 'Parameters: (press Apply)', ...
    'WordWrap', 'on', 'FontName', 'Consolas');
end
