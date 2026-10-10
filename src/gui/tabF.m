function tabF(app)
% Tab F: motion blur restoration with our own PSF, inverse filtering and Wiener filtering side by side.
L = buildPartLayout(app.Tabs.F, {'Original (reference)', 'Degraded', 'PSF', '|H(u,v)|', ...
    'Degraded spectrum', 'Inverse filter', 'Wiener filter', 'Wiener result spectrum'});
C = L.Controls;

lengthField = place(uieditfield(C, 'numeric', 'Value', 15, 'Limits', [1 200]), 1, 2);
angleField = place(uieditfield(C, 'numeric', 'Value', 0, 'Limits', [-360 360]), 2, 2);
modeField = place(uidropdown(C, 'Items', {'Threshold t', 'Radius R0 (Butterworth)', 'None (plain 1/H)'}, ...
    'ItemsData', {'threshold', 'radius', 'none'}, 'Value', 'threshold'), 3, 2);
tField = place(uieditfield(C, 'numeric', 'Value', 0.1, 'Limits', [0 Inf]), 4, 2);
r0Field = place(uieditfield(C, 'numeric', 'Value', 20, 'Limits', [0 Inf], 'LowerLimitInclusive', 'off'), 5, 2);
kField = place(uieditfield(C, 'numeric', 'Value', 0.003, 'Limits', [0 Inf]), 6, 2);
borderField = place(uidropdown(C, 'Items', {'Edge taper', 'Periodic (none)', 'Mirror'}, ...
    'ItemsData', {'taper', 'periodic', 'mirror'}, 'Value', 'taper'), 7, 2);
simulateBox = place(uicheckbox(C, 'Text', 'Simulate: blur the loaded image first', 'Value', false), 8, [1 2]);
sigmaField = place(uieditfield(C, 'numeric', 'Value', 0, 'Limits', [0 1]), 9, 2);
place(uilabel(C, 'Text', 'Length L (pixels)'), 1, 1);
place(uilabel(C, 'Text', 'Angle theta (deg)'), 2, 1);
place(uilabel(C, 'Text', 'Inverse: stabilise'), 3, 1);
place(uilabel(C, 'Text', 'Inverse: t'), 4, 1);
place(uilabel(C, 'Text', 'Inverse: R0'), 5, 1);
place(uilabel(C, 'Text', 'Wiener K'), 6, 1);
place(uilabel(C, 'Text', 'Border'), 7, 1);
place(uilabel(C, 'Text', 'Simulated noise sigma'), 9, 1);
place(uilabel(C, 'WordWrap', 'on', 'Text', ['Angle: from the +x axis towards +y (rows point down), ' ...
    'so positive is clockwise on screen, as in the test data.']), 10, [1 2]);

modeField.ValueChangedFcn = @(~, ~) updateEnabled();
simulateBox.ValueChangedFcn = @(~, ~) updateEnabled();
L.Apply.ButtonPushedFcn = @(~, ~) apply();
L.Save.ButtonPushedFcn = @(~, ~) saveResult();

results = {};
resultNames = {};
addlistener(app, 'ImageChanged', @(~, ~) showInput());
updateEnabled();
showInput();

    function c = place(c, row, col)
        c.Layout.Row = row;
        c.Layout.Column = col;
    end

    function updateEnabled()
        tField.Enable = strcmp(modeField.Value, 'threshold');
        r0Field.Enable = strcmp(modeField.Value, 'radius');
        sigmaField.Enable = simulateBox.Value;
    end

    function showInput()
        results = {};
        for k = [1 3 4 6 7 8]
            showImage(L.Axes(k), [], L.Axes(k).Title.String);
        end
        L.Params.Text = 'Parameters: (press Apply)';
        if isempty(app.Image)
            return;
        end
        [len, theta] = motionParamsFromName(app.ImagePath);
        if ~isempty(len)
            lengthField.Value = len;
            angleField.Value = theta;
        end
        [M, N, ~] = size(app.Image);
        [~, ~, F] = applyFilter(app.Image, ones(M, N));
        showImage(L.Axes(2), app.Image, 'Degraded');
        showImage(L.Axes(5), spectrumImage(F), 'Degraded spectrum');
        ref = reference();
        if ~isempty(ref)
            showImage(L.Axes(1), ref, 'Original (reference)');
        end
    end

    function ref = reference()
        ref = [];
        refPath = findReference(fileparts(fileparts(app.ImagePath)), app.ImagePath);
        if ~isempty(refPath)
            ref = readImageFile(refPath);
            if ~isequal(size(ref), size(app.Image))
                ref = [];
            end
        end
    end

    function apply()
        if isempty(app.Image)
            uialert(app.Fig, 'Load an image first.', 'Part F');
            return;
        end
        len = lengthField.Value;
        theta = angleField.Value;
        mode = modeField.Value;
        values = struct('threshold', tField.Value, 'radius', r0Field.Value, 'none', 0);
        K = kField.Value;
        border = borderField.Value;

        try
            psf = motionPSF(len, theta);
            if simulateBox.Value
                original = app.Image;
                g = motionDegrade(original, psf, sigmaField.Value);
            else
                original = reference();
                g = app.Image;
            end
            [fInverse, H] = motionRestore(g, psf, mode, values.(mode), border);
            fWiener = motionRestore(g, psf, 'wiener', K, border);
        catch err
            uialert(app.Fig, err.message, 'Part F: invalid parameters');
            return;
        end

        [M, N, ~] = size(g);
        [~, ~, Gs] = applyFilter(g, ones(M, N));
        [~, ~, Ws] = applyFilter(fWiener, ones(M, N));
        if simulateBox.Value
            showImage(L.Axes(1), original, 'Original (loaded image)');
            showImage(L.Axes(2), g, sprintf('Degraded (simulated, sigma = %g)', sigmaField.Value));
        end
        showImage(L.Axes(3), psf / max(psf(:)), sprintf('PSF %d x %d (/ max)', size(psf, 1), size(psf, 2)));
        showImage(L.Axes(4), abs(H), '|H(u,v)|');
        showImage(L.Axes(5), spectrumImage(Gs), 'Degraded spectrum');
        showImage(L.Axes(6), fInverse, 'Inverse filter');
        showImage(L.Axes(7), fWiener, 'Wiener filter');
        showImage(L.Axes(8), spectrumImage(Ws), 'Wiener result spectrum');
        results = {fInverse, fWiener};

        modeText = struct('threshold', sprintf('threshold t = %g', tField.Value), ...
            'radius', sprintf('radius R0 = %g', r0Field.Value), 'none', 'none');
        label = sprintf('L = %g, theta = %g; inverse: %s; Wiener K = %g; border: %s', ...
            len, theta, modeText.(mode), K, border);
        if simulateBox.Value
            label = sprintf('%s; simulated noise sigma = %g', label, sigmaField.Value);
        end
        if ~isempty(original)
            [~, pDegraded] = imageQuality(g, original);
            [~, pInverse] = imageQuality(fInverse, original);
            [~, pWiener] = imageQuality(fWiener, original);
            label = sprintf('%s  |  PSNR vs original: degraded %.2f, inverse %.2f, Wiener %.2f dB', ...
                label, pDegraded, pInverse, pWiener);
        end
        L.Params.Text = ['Parameters: ' label];

        [~, inName] = fileparts(app.ImagePath);
        resultNames = {sprintf('%s_inverse-%s-%g_%s.png', inName, mode, values.(mode), border), ...
            sprintf('%s_wiener-K-%g_%s.png', inName, K, border)};
    end

    function saveResult()
        if isempty(results)
            uialert(app.Fig, 'Press Apply first.', 'Part F');
            return;
        end
        folder = uigetdir('', 'Folder for the inverse and Wiener results');
        figure(app.Fig);
        if ~isequal(folder, 0)
            for k = 1:2
                imwrite(min(max(results{k}, 0), 1), fullfile(folder, resultNames{k}));
            end
        end
    end
end
