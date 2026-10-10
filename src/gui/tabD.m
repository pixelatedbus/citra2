function tabD(app)
% Tab D: brightening by homomorphic filtering of the log spectrum, or by low-frequency emphasis.
L = buildPartLayout(app.Tabs.D, {'Input', 'Input spectrum', 'H(u,v)', 'Result', 'Result spectrum'});
C = L.Controls;

methodField = place(uidropdown(C, 'Items', {'Homomorphic (log spectrum)', 'Low-frequency emphasis'}, ...
    'ItemsData', {'homomorphic', 'emphasis'}, 'Value', 'homomorphic'), 1, 2);
tField = place(uieditfield(C, 'numeric', 'Value', 0.4, 'Limits', [0 1], 'LowerLimitInclusive', 'off'), 2, 2);
gLField = place(uieditfield(C, 'numeric', 'Value', 0.8, 'Limits', [0 10]), 3, 2);
gHField = place(uieditfield(C, 'numeric', 'Value', 0.8, 'Limits', [0 10]), 4, 2);
kField = place(uieditfield(C, 'numeric', 'Value', 3, 'Limits', [0 20]), 5, 2);
d0Field = place(uieditfield(C, 'numeric', 'Value', 0, 'Limits', [0 1000]), 6, 2);
place(uilabel(C, 'Text', 'Method'), 1, 1);
place(uilabel(C, 'Text', 'Target t (homomorphic)'), 2, 1);
place(uilabel(C, 'Text', 'gL (homomorphic)'), 3, 1);
place(uilabel(C, 'Text', 'gH (homomorphic)'), 4, 1);
place(uilabel(C, 'Text', 'k (emphasis)'), 5, 1);
place(uilabel(C, 'Text', 'D0 (0 = DC only)'), 6, 1);
place(uilabel(C, 'WordWrap', 'on', 'Text', ['Homomorphic: t = geometric mean of the result; ' ...
    'gL, gH = gains of low / high frequencies of log(image). ' ...
    'Emphasis: low frequencies times k, high frequencies unchanged.']), 7, [1 2]);

methodField.ValueChangedFcn = @(~, ~) updateEnabled();
L.Apply.ButtonPushedFcn = @(~, ~) apply();
L.Save.ButtonPushedFcn = @(~, ~) saveResult();

result = [];
resultName = '';
addlistener(app, 'ImageChanged', @(~, ~) showInput());
updateEnabled();
showInput();

    function c = place(c, row, col)
        c.Layout.Row = row;
        c.Layout.Column = col;
    end

    function updateEnabled()
        homomorphic = strcmp(methodField.Value, 'homomorphic');
        tField.Enable = homomorphic;
        gLField.Enable = homomorphic;
        gHField.Enable = homomorphic;
        kField.Enable = ~homomorphic;
    end

    function saveResult()
        saveResultImage(app, result, resultName, 'D');
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
            uialert(app.Fig, 'Load an image first.', 'Part D');
            return;
        end
        [M, N, ~] = size(app.Image);
        D0 = d0Field.Value;
        if strcmp(methodField.Value, 'homomorphic')
            t = tField.Value;
            gL = gLField.Value;
            gH = gHField.Value;
            [g, H] = homomorphicBrightness(app.Image, gL, gH, D0, t);
            label = sprintf('Homomorphic, t = %g, gL = %g, gH = %g, D0 = %g', t, gL, gH, D0);
            tag = sprintf('homomorphic_t-%g_gL-%g_gH-%g_D0-%g', t, gL, gH, D0);
        else
            k = kField.Value;
            H = brightnessH(M, N, k, 1, D0);
            g = applyFilter(app.Image, H);
            label = sprintf('Low-frequency emphasis, k = %g, D0 = %g', k, D0);
            tag = sprintf('emphasis_k-%g_D0-%g', k, D0);
        end

        [~, G] = applyFilter(g, ones(M, N));
        showImage(L.Axes(3), H / max(H(:)), sprintf('H(u,v) / %.3g', max(H(:))));
        showImage(L.Axes(4), g, 'Result');
        showImage(L.Axes(5), spectrumImage(G), 'Result spectrum');
        result = g;

        [~, inName] = fileparts(app.ImagePath);
        resultName = sprintf('%s_%s.png', inName, tag);
        L.Params.Text = sprintf('Parameters: %s  |  mean %.3f -> %.3f%s', label, ...
            mean(app.Image, 'all'), mean(min(max(g, 0), 1), 'all'), psnrText(app, g));
    end
end
