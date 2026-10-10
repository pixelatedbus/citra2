function L = buildPartLayout(tab, axesTitles)
% Shared tab layout: parameter panel with Apply/Save on the left, titled axes and a parameter line on the right.
axesTitles = cellstr(axesTitles);
K = numel(axesTitles);
maxRows = 15;

root = uigridlayout(tab, [1 2]);
root.ColumnWidth = {280, '1x'};

left = uigridlayout(root, [3 1]);
left.RowHeight = {'fit', 'fit', '1x'};
left.Padding = [0 0 0 0];
panel = uipanel(left, 'Title', 'Parameters');
L.Controls = uigridlayout(panel, [maxRows 2]);
L.Controls.ColumnWidth = {'fit', '1x'};
L.Controls.RowHeight = repmat({'fit'}, 1, maxRows);
buttons = uigridlayout(left, [2 1]);
buttons.RowHeight = {'fit', 'fit'};
buttons.Padding = [0 0 0 0];
L.Apply = uibutton(buttons, 'Text', 'Apply');
L.Save = uibutton(buttons, 'Text', 'Save result...');

right = uigridlayout(root, [2 1]);
right.RowHeight = {'1x', 'fit'};
right.Padding = [0 0 0 0];
nRows = 1 + (K > 3) + (K > 8);
axesGrid = uigridlayout(right, [nRows ceil(K / nRows)]);
axesGrid.Padding = [0 0 0 0];
L.Axes = gobjects(1, K);
for k = 1:K
    L.Axes(k) = uiaxes(axesGrid);
    showImage(L.Axes(k), [], axesTitles{k});
end
L.Params = uilabel(right, 'Text', 'Parameters: (press Apply)', 'WordWrap', 'on', 'FontName', 'Consolas');
end
