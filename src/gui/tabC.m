function tabC(app)
% Tab C: high-pass filtering with a choice of how the signed result is displayed.
L = buildPartLayout(app.Tabs.C, {'Input', 'Input spectrum', 'H(u,v)', 'Result', 'Result spectrum'});

uilabel(L.Controls, 'Text', 'Filter');
typeField = uidropdown(L.Controls, 'Items', {'Ideal (IHPF)', 'Gaussian (GHPF)', 'Butterworth (BHPF)'}, ...
    'ItemsData', {'ideal', 'gaussian', 'butterworth'}, 'Value', 'gaussian');
uilabel(L.Controls, 'Text', 'D0');
d0Field = uieditfield(L.Controls, 'numeric', 'Value', 30, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off');
uilabel(L.Controls, 'Text', 'n (Butterworth)');
nField = uieditfield(L.Controls, 'numeric', 'Value', 2, 'Limits', [1 Inf], 'RoundFractionalValues', 'on');
uilabel(L.Controls, 'Text', 'Display');
modeField = uidropdown(L.Controls, 'Items', {'|g| normalised', '|g|', 'Rescale min..max'}, ...
    'ItemsData', {'abs-normalized', 'abs', 'rescale'}, 'Value', 'abs-normalized');

typeField.ValueChangedFcn = @(~, ~) updateEnabled();
modeField.ValueChangedFcn = @(~, ~) redrawResult();
L.Apply.ButtonPushedFcn = @(~, ~) apply();
L.Save.ButtonPushedFcn = @(~, ~) saveResult();

result = [];
label = '';
addlistener(app, 'ImageChanged', @(~, ~) showInput());
updateEnabled();
showInput();

    function updateEnabled()
        nField.Enable = strcmp(typeField.Value, 'butterworth');
    end

    function showInput()
        result = [];
        for k = 3:5
            showImage(L.Axes(k), [], L.Axes(k).Title.String);
        end
        L.Params.Text = 'Parameters: (press Apply)';
        if isempty(app.Image)
            return;
        end
        [M, N, ~] = size(app.Image);
        [~, ~, F] = applyFilter(app.Image, ones(M, N));
        showImage(L.Axes(1), app.Image, 'Input');
        showImage(L.Axes(2), spectrumImage(F), 'Input spectrum');
    end

    function apply()
        if isempty(app.Image)
            uialert(app.Fig, 'Load an image first.', 'Part C');
            return;
        end
        type = typeField.Value;
        D0 = d0Field.Value;
        n = nField.Value;
        [M, N, ~] = size(app.Image);
        H = highpassH(M, N, type, D0, n);
        [g, G] = applyFilter(app.Image, H);

        showImage(L.Axes(3), H, 'H(u,v)');
        showImage(L.Axes(5), spectrumImage(G), 'Result spectrum');
        result = g;

        names = struct('ideal', 'IHPF', 'gaussian', 'GHPF', 'butterworth', 'BHPF');
        label = sprintf('%s, D0 = %g', names.(type), D0);
        if strcmp(type, 'butterworth')
            label = sprintf('%s, n = %d', label, n);
        end
        redrawResult();
    end

    function redrawResult()
        if isempty(result)
            return;
        end
        showImage(L.Axes(4), highpassDisplay(result, modeField.Value), 'Result');
        L.Params.Text = sprintf('Parameters: %s  |  display: %s  |  raw range [%.3f, %.3f]', ...
            label, modeField.Value, min(result(:)), max(result(:)));
    end

    function saveResult()
        shown = [];
        if ~isempty(result)
            shown = highpassDisplay(result, modeField.Value);
        end
        [~, inName] = fileparts(app.ImagePath);
        name = sprintf('%s_%s_%s.png', inName, regexprep(label, '[ ,=]+', '-'), modeField.Value);
        saveResultImage(app, shown, name, 'C');
    end
end
