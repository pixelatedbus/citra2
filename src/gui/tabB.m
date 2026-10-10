function tabB(app)
% TABB  Builds the part B tab (low-pass smoothing) inside app.Tabs.B.
%
%   Smooths the loaded image with one of the three low-pass filters from
%   lowpassH (ILPF, GLPF, BLPF), applied in the frequency domain with
%   applyFilter: G = H .* F. Shows the input, its spectrum, H(u,v), the
%   result and the result's spectrum, plus the parameters used. When the
%   image comes from a data folder with a reference/ (e.g. data/B_.../input),
%   the PSNR of the input and of the result against the reference is shown
%   too. Save result writes the result, clipped to [0,1], to a PNG file.
%
%   INPUT
%     app  the FreqApp object (reads app.Image, app.ImagePath, app.Tabs.B,
%          app.Fig; listens to app's ImageChanged event)
%
%   OUTPUT
%     none (fills app.Tabs.B)

L = buildPartLayout(app.Tabs.B, ...
    {'Input', 'Input spectrum', 'H(u,v)', 'Result', 'Result spectrum'});

uilabel(L.Controls, 'Text', 'Filter');
typeField = uidropdown(L.Controls, ...
    'Items', {'Ideal (ILPF)', 'Gaussian (GLPF)', 'Butterworth (BLPF)'}, ...
    'ItemsData', {'ideal', 'gaussian', 'butterworth'}, 'Value', 'gaussian');
uilabel(L.Controls, 'Text', 'D0');
d0Field = uieditfield(L.Controls, 'numeric', 'Value', 40, ...
    'Limits', [0 Inf], 'LowerLimitInclusive', 'off');
uilabel(L.Controls, 'Text', 'n (Butterworth)');
nField = uieditfield(L.Controls, 'numeric', 'Value', 2, ...
    'Limits', [1 Inf], 'RoundFractionalValues', 'on');

typeField.ValueChangedFcn = @(~, ~) updateEnabled();
L.Apply.ButtonPushedFcn = @(~, ~) apply();
L.Save.ButtonPushedFcn = @(~, ~) saveResult();

result = [];        % last filtered image, [] until Apply
resultName = '';    % suggested file name for Save

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
            uialert(app.Fig, 'Load an image first.', 'Part B');
            return;
        end
        type = typeField.Value;
        D0 = d0Field.Value;
        n = nField.Value;

        [M, N, ~] = size(app.Image);
        H = lowpassH(M, N, type, D0, n);
        [g, G] = applyFilter(app.Image, H);

        showImage(L.Axes(3), H, 'H(u,v)');
        showImage(L.Axes(4), g, 'Result');
        showImage(L.Axes(5), spectrumImage(G), 'Result spectrum');
        result = g;

        names = struct('ideal', 'ILPF', 'gaussian', 'GLPF', 'butterworth', 'BLPF');
        label = sprintf('%s, D0 = %g', names.(type), D0);
        if strcmp(type, 'butterworth')
            label = sprintf('%s, n = %d', label, n);
        end
        [~, inName] = fileparts(app.ImagePath);
        resultName = sprintf('%s_%s_D0-%g.png', inName, names.(type), D0);
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
            uialert(app.Fig, 'Press Apply first.', 'Part B');
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
