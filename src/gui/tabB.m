function tabB(app)
% Tab B: smoothing with the ideal, Gaussian or Butterworth low-pass filter.
L = buildPartLayout(app.Tabs.B, {'Input', 'Input spectrum', 'H(u,v)', 'Result', 'Result spectrum'});

uilabel(L.Controls, 'Text', 'Filter');
typeField = uidropdown(L.Controls, 'Items', {'Ideal (ILPF)', 'Gaussian (GLPF)', 'Butterworth (BLPF)'}, ...
    'ItemsData', {'ideal', 'gaussian', 'butterworth'}, 'Value', 'gaussian');
uilabel(L.Controls, 'Text', 'D0');
d0Field = uieditfield(L.Controls, 'numeric', 'Value', 40, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off');
uilabel(L.Controls, 'Text', 'n (Butterworth)');
nField = uieditfield(L.Controls, 'numeric', 'Value', 2, 'Limits', [1 Inf], 'RoundFractionalValues', 'on');

typeField.ValueChangedFcn = @(~, ~) updateEnabled();
L.Apply.ButtonPushedFcn = @(~, ~) apply();
L.Save.ButtonPushedFcn = @(~, ~) saveResult();

result = [];
resultName = '';
addlistener(app, 'ImageChanged', @(~, ~) showInput());
updateEnabled();
showInput();

    function updateEnabled()
        nField.Enable = strcmp(typeField.Value, 'butterworth');
    end

    function saveResult()
        saveResultImage(app, result, resultName, 'B');
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
        L.Params.Text = ['Parameters: ' label psnrText(app, g)];
    end
end
