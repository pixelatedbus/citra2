function tabE(app)
% TABE  Builds the part E tab (periodic noise restoration) inside app.Tabs.E.
%
%   Removes periodic noise by multiplying the centred spectrum with a
%   reject filter and transforming back (applyFilter):
%     - Notch reject (notchRejectH): one row [du dv radius] per noise spike,
%       edited in a table; each row also removes the mirror spike (-du,-dv).
%     - Bandreject (bandrejectH): a ring of radius D0 and width W.
%   Shapes: ideal, Butterworth, Gaussian. Shows the five views the spec
%   asks for: degraded image, spectrum before, mask H(u,v), spectrum after,
%   restored image; plus the parameters and, when the image comes from a
%   data folder with a reference/, the PSNR before and after.
%
%   Finding the spikes: the hint under the table shows the spectrum centre
%   (uc, vc) of the loaded image. A spike seen at spectrum pixel (x, y)
%   (use the axes data tip / zoom) is at du = y - uc, dv = x - vc.
%
%   INPUT
%     app  the FreqApp object (reads app.Image, app.ImagePath, app.Tabs.E,
%          app.Fig; listens to app's ImageChanged event)
%
%   OUTPUT
%     none (fills app.Tabs.E)

L = buildPartLayout(app.Tabs.E, ...
    {'Degraded', 'Spectrum before', 'Mask H(u,v)', 'Spectrum after', 'Restored'});
C = L.Controls;

filterField = place(uidropdown(C, 'Items', {'Notch reject', 'Bandreject'}, ...
    'ItemsData', {'notch', 'band'}, 'Value', 'notch'), 1, 2);
shapeField = place(uidropdown(C, 'Items', {'Ideal', 'Butterworth', 'Gaussian'}, ...
    'ItemsData', {'ideal', 'butterworth', 'gaussian'}, 'Value', 'gaussian'), 2, 2);
nField = place(uieditfield(C, 'numeric', 'Value', 2, ...
    'Limits', [1 Inf], 'RoundFractionalValues', 'on'), 3, 2);
d0Field = place(uieditfield(C, 'numeric', 'Value', 30, ...
    'Limits', [0 Inf], 'LowerLimitInclusive', 'off'), 4, 2);
wField = place(uieditfield(C, 'numeric', 'Value', 4, ...
    'Limits', [0 Inf], 'LowerLimitInclusive', 'off'), 5, 2);
place(uilabel(C, 'Text', 'Filter'), 1, 1);
place(uilabel(C, 'Text', 'Shape'), 2, 1);
place(uilabel(C, 'Text', 'n (Butterworth)'), 3, 1);
place(uilabel(C, 'Text', 'Ring D0 (band)'), 4, 1);
place(uilabel(C, 'Text', 'Ring W (band)'), 5, 1);

notchTable = place(uitable(C, 'Data', zeros(0, 3), ...
    'ColumnName', {'du (rows)', 'dv (cols)', 'radius'}, ...
    'ColumnEditable', true, 'RowName', {}), 6, [1 2]);
C.RowHeight{6} = 150;
addButton = place(uibutton(C, 'Text', 'Add notch'), 7, 1);
removeButton = place(uibutton(C, 'Text', 'Remove selected'), 7, 2);
hint = place(uilabel(C, 'WordWrap', 'on', 'Text', ''), 8, [1 2]);

filterField.ValueChangedFcn = @(~, ~) updateEnabled();
shapeField.ValueChangedFcn = @(~, ~) updateEnabled();
addButton.ButtonPushedFcn = @(~, ~) addNotch();
removeButton.ButtonPushedFcn = @(~, ~) removeSelected();
L.Apply.ButtonPushedFcn = @(~, ~) apply();
L.Save.ButtonPushedFcn = @(~, ~) saveResult();

result = [];        % last restored image, [] until Apply
resultName = '';    % suggested file name for Save
selectedRows = [];  % rows selected in the notch table
notchTable.SelectionChangedFcn = @(src, ~) setSelected(src);

addlistener(app, 'ImageChanged', @(~, ~) showInput());
updateEnabled();
showInput();

    function c = place(c, row, col)
        % Put a component at an explicit cell of the Parameters grid.
        c.Layout.Row = row;
        c.Layout.Column = col;
    end

    function updateEnabled()
        isNotch = strcmp(filterField.Value, 'notch');
        nField.Enable = strcmp(shapeField.Value, 'butterworth');
        d0Field.Enable = ~isNotch;
        wField.Enable = ~isNotch;
        onOff = {'off', 'on'};
        notchTable.Enable = onOff{isNotch + 1};   % uitable only accepts 'on'/'off', not true/false
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

    function showInput()
        % New image: draw it and its spectrum, show the centre, clear the result.
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
        hint.Text = sprintf(['Spectrum centre (row, col) = (%d, %d). A spike at spectrum ' ...
            'pixel (x, y) is du = y - %d, dv = x - %d. Each row also removes (-du, -dv).'], ...
            floor(M/2) + 1, floor(N/2) + 1, floor(M/2) + 1, floor(N/2) + 1);
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
                parts = arrayfun(@(k) sprintf('(%g, %g) r=%g', notches(k, :)), ...
                    1:size(notches, 1), 'UniformOutput', false);
                label = sprintf('Notch reject, %s: %s', shapeText, strjoin(parts, '; '));
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
        L.Params.Text = ['Parameters: ' label psnrText(g)];
    end

    function txt = psnrText(g)
        % "| PSNR input -> result" when a matching reference image exists.
        txt = '';
        refPath = findReference(fileparts(fileparts(app.ImagePath)), app.ImagePath);
        if isempty(refPath)
            return;
        end
        ref = readImageFile(refPath);
        if isequal(size(ref), size(g))
            [~, before] = imageQuality(app.Image, ref);
            [~, after] = imageQuality(g, ref);
            txt = sprintf('  |  PSNR vs reference: input %.2f dB -> result %.2f dB', before, after);
        end
    end

    function saveResult()
        if isempty(result)
            uialert(app.Fig, 'Press Apply first.', 'Part E');
            return;
        end
        [file, folder] = uiputfile('*.png', 'Save result', resultName);
        figure(app.Fig);
        if isequal(file, 0)
            return;
        end
        imwrite(min(max(result, 0), 1), fullfile(folder, file));
    end
end
