function tabE(app)
% Tab E: periodic noise removal with notch reject (table of spikes) or a bandreject ring.
L = buildPartLayout(app.Tabs.E, {'Degraded', 'Spectrum before', 'Mask H(u,v)', 'Spectrum after', 'Restored'});
C = L.Controls;

filterField = place(uidropdown(C, 'Items', {'Notch reject', 'Bandreject'}, ...
    'ItemsData', {'notch', 'band'}, 'Value', 'notch'), 1, 2);
shapeField = place(uidropdown(C, 'Items', {'Ideal', 'Butterworth', 'Gaussian'}, ...
    'ItemsData', {'ideal', 'butterworth', 'gaussian'}, 'Value', 'gaussian'), 2, 2);
nField = place(uieditfield(C, 'numeric', 'Value', 2, 'Limits', [1 Inf], 'RoundFractionalValues', 'on'), 3, 2);
d0Field = place(uieditfield(C, 'numeric', 'Value', 30, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off'), 4, 2);
wField = place(uieditfield(C, 'numeric', 'Value', 4, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off'), 5, 2);
place(uilabel(C, 'Text', 'Filter'), 1, 1);
place(uilabel(C, 'Text', 'Shape'), 2, 1);
place(uilabel(C, 'Text', 'n (Butterworth)'), 3, 1);
place(uilabel(C, 'Text', 'Ring D0 (band)'), 4, 1);
place(uilabel(C, 'Text', 'Ring W (band)'), 5, 1);
notchTable = place(uitable(C, 'Data', zeros(0, 3), 'ColumnName', {'du (rows)', 'dv (cols)', 'radius'}, ...
    'ColumnEditable', true, 'RowName', {}), 6, [1 2]);
C.RowHeight{6} = 150;
addButton = place(uibutton(C, 'Text', 'Add notch'), 7, 1);
removeButton = place(uibutton(C, 'Text', 'Remove selected'), 7, 2);
hint = place(uilabel(C, 'WordWrap', 'on', 'Text', ''), 8, [1 2]);

filterField.ValueChangedFcn = @(~, ~) updateEnabled();
shapeField.ValueChangedFcn = @(~, ~) updateEnabled();
addButton.ButtonPushedFcn = @(~, ~) addNotch();
removeButton.ButtonPushedFcn = @(~, ~) removeSelected();
notchTable.SelectionChangedFcn = @(src, ~) setSelected(src);
L.Apply.ButtonPushedFcn = @(~, ~) apply();
L.Save.ButtonPushedFcn = @(~, ~) saveResult();

result = [];
resultName = '';
selectedRows = [];
addlistener(app, 'ImageChanged', @(~, ~) showInput());
updateEnabled();
showInput();

    function c = place(c, row, col)
        c.Layout.Row = row;
        c.Layout.Column = col;
    end

    function updateEnabled()
        isNotch = strcmp(filterField.Value, 'notch');
        nField.Enable = strcmp(shapeField.Value, 'butterworth');
        d0Field.Enable = ~isNotch;
        wField.Enable = ~isNotch;
        onOff = {'off', 'on'};
        notchTable.Enable = onOff{isNotch + 1};
        addButton.Enable = isNotch;
        removeButton.Enable = isNotch;
    end

    function setSelected(src)
        selectedRows = [];
        if ~isempty(src.Selection)
            selectedRows = unique(src.Selection(:, 1))';
        end
    end

    function addNotch()
        notchTable.Data = [notchTable.Data; 0 0 3];
    end

    function removeSelected()
        if isempty(selectedRows)
            uialert(app.Fig, 'Select a row in the notch table first.', 'Part E');
            return;
        end
        notchTable.Data(selectedRows, :) = [];
        selectedRows = [];
    end

    function saveResult()
        saveResultImage(app, result, resultName, 'E');
    end

    function showInput()
        result = [];
        for k = 3:5
            showImage(L.Axes(k), [], L.Axes(k).Title.String);
        end
        L.Params.Text = 'Parameters: (press Apply)';
        if isempty(app.Image)
            hint.Text = 'Load an image to see its spectrum centre.';
            return;
        end
        [M, N, ~] = size(app.Image);
        [~, ~, F] = applyFilter(app.Image, ones(M, N));
        showImage(L.Axes(1), app.Image, 'Degraded');
        showImage(L.Axes(2), spectrumImage(F), 'Spectrum before');
        uc = floor(M/2) + 1;
        vc = floor(N/2) + 1;
        hint.Text = sprintf(['Spectrum centre (row, col) = (%d, %d). A spike at spectrum pixel (x, y) is ' ...
            'du = y - %d, dv = x - %d. Each row also removes (-du, -dv).'], uc, vc, uc, vc);
    end

    function apply()
        if isempty(app.Image)
            uialert(app.Fig, 'Load an image first.', 'Part E');
            return;
        end
        [M, N, ~] = size(app.Image);
        shape = shapeField.Value;
        n = nField.Value;
        shapeText = shape;
        if strcmp(shape, 'butterworth')
            shapeText = sprintf('butterworth n = %d', n);
        end

        try
            if strcmp(filterField.Value, 'notch')
                notches = notchTable.Data;
                if isempty(notches)
                    uialert(app.Fig, 'Add at least one notch (du, dv, radius).', 'Part E');
                    return;
                end
                H = notchRejectH(M, N, shape, notches, n);
                spots = arrayfun(@(k) sprintf('(%g, %g) r=%g', notches(k, :)), 1:size(notches, 1), ...
                    'UniformOutput', false);
                label = sprintf('Notch reject, %s: %s', shapeText, strjoin(spots, '; '));
                tag = sprintf('notch-%s-%d', shape, size(notches, 1));
            else
                D0 = d0Field.Value;
                W = wField.Value;
                H = bandrejectH(M, N, shape, D0, W, n);
                label = sprintf('Bandreject, %s: D0 = %g, W = %g', shapeText, D0, W);
                tag = sprintf('band-%s-D0-%g-W-%g', shape, D0, W);
            end
        catch err
            uialert(app.Fig, err.message, 'Part E: invalid parameters');
            return;
        end

        [g, G] = applyFilter(app.Image, H);
        showImage(L.Axes(3), H, 'Mask H(u,v)');
        showImage(L.Axes(4), spectrumImage(G), 'Spectrum after');
        showImage(L.Axes(5), g, 'Restored');
        result = g;

        [~, inName] = fileparts(app.ImagePath);
        resultName = sprintf('%s_%s.png', inName, tag);
        L.Params.Text = ['Parameters: ' label psnrText(app, g)];
    end
end
