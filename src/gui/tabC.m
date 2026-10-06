function tabC(app)
% TABC  Builds the part C tab (high-pass filtering) inside app.Tabs.C.
%
%   Filters the loaded image with one of the three high-pass filters from
%   highpassH (IHPF, GHPF, BHPF), applied in the frequency domain with
%   applyFilter: G = H .* F. The result has negative values (the mean is
%   removed), so it is shown through highpassDisplay with the chosen mode:
%   |g| normalised (default, the spec's dark background with bright edges),
%   |g|, or rescale (keeps the sign, flat areas mid-grey). Shows the input,
%   its spectrum, H(u,v), the result and its spectrum, plus the parameters
%   and display mode. Save result writes the displayed result to a PNG
%   whose name states the display mode.
%
%   INPUT
%     app  the FreqApp object (reads app.Image, app.ImagePath, app.Tabs.C,
%          app.Fig; listens to app's ImageChanged event)
%
%   OUTPUT
%     none (fills app.Tabs.C)

L = buildPartLayout(app.Tabs.C, ...
    {'Input', 'Input spectrum', 'H(u,v)', 'Result', 'Result spectrum'});

uilabel(L.Controls, 'Text', 'Filter');
typeField = uidropdown(L.Controls, ...
    'Items', {'Ideal (IHPF)', 'Gaussian (GHPF)', 'Butterworth (BHPF)'}, ...
    'ItemsData', {'ideal', 'gaussian', 'butterworth'}, 'Value', 'gaussian');
uilabel(L.Controls, 'Text', 'D0');
d0Field = uieditfield(L.Controls, 'numeric', 'Value', 30, ...
    'Limits', [0 Inf], 'LowerLimitInclusive', 'off');
uilabel(L.Controls, 'Text', 'n (Butterworth)');
nField = uieditfield(L.Controls, 'numeric', 'Value', 2, ...
    'Limits', [1 Inf], 'RoundFractionalValues', 'on');
uilabel(L.Controls, 'Text', 'Display');
modeField = uidropdown(L.Controls, ...
    'Items', {'|g| normalised', '|g|', 'Rescale min..max'}, ...
    'ItemsData', {'abs-normalized', 'abs', 'rescale'}, 'Value', 'abs-normalized');

typeField.ValueChangedFcn = @(~, ~) updateEnabled();
modeField.ValueChangedFcn = @(~, ~) redrawResult();
L.Apply.ButtonPushedFcn = @(~, ~) apply();
L.Save.ButtonPushedFcn = @(~, ~) saveResult();

result = [];        % last raw high-pass result (with negative values)
label = '';         % filter and parameters of that result

addlistener(app, 'ImageChanged', @(~, ~) showInput());
updateEnabled();
showInput();

    function updateEnabled()
        % n only matters for the Butterworth filter.
        nField.Enable = strcmp(typeField.Value, 'butterworth');
    end

    function showInput()
        % New image: draw input and spectrum, clear the old result.
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
        % Show the result with the chosen display mode (no recomputation).
        if isempty(result)
            return;
        end
        showImage(L.Axes(4), highpassDisplay(result, modeField.Value), 'Result');
        L.Params.Text = sprintf('Parameters: %s  |  display: %s  |  raw range [%.3f, %.3f]', ...
            label, modeField.Value, min(result, [], 'all'), max(result, [], 'all'));
    end

    function saveResult()
        if isempty(result)
            uialert(app.Fig, 'Press Apply first.', 'Part C');
            return;
        end
        [~, inName] = fileparts(app.ImagePath);
        suggested = sprintf('%s_%s_%s.png', inName, ...
            regexprep(label, '[ ,=]+', '-'), modeField.Value);
        [file, folder] = uiputfile('*.png', 'Save result', suggested);
        figure(app.Fig);
        if isequal(file, 0)
            return;
        end
        imwrite(min(max(highpassDisplay(result, modeField.Value), 0), 1), fullfile(folder, file));
    end
end
