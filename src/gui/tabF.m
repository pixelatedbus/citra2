function tabF(app)
% TABF  Builds the part F tab (motion blur restoration) inside app.Tabs.F.
%
%   PLACEHOLDER from the shared foundation; owner: Member 2, who replaces
%   the body with the real controls and the Apply / Save logic.
%   It already follows the tab contract: it uses buildPartLayout with the
%   views this part must show, and it redraws the input and its spectrum
%   whenever a new image is loaded (the app's ImageChanged event).
%
%   INPUT
%     app  the FreqApp object (reads app.Image, app.Tabs.F, app.Fig)
%
%   OUTPUT
%     none (fills app.Tabs.F)

L = buildPartLayout(app.Tabs.F, ...
    {'Original (reference)', 'Degraded', 'PSF', '|H(u,v)|', ...
     'Degraded spectrum', 'Inverse filter', 'Wiener filter'});

msg = 'Part F is not implemented yet.';
note = uilabel(L.Controls, 'Text', msg, 'WordWrap', 'on');
note.Layout.Row = 1;
note.Layout.Column = [1 2];
L.Apply.ButtonPushedFcn = @(~, ~) uialert(app.Fig, msg, 'Part F');
L.Save.ButtonPushedFcn  = @(~, ~) uialert(app.Fig, msg, 'Part F');

addlistener(app, 'ImageChanged', @(~, ~) showInput());
showInput();

    function showInput()
        % Draw the loaded image and its centred spectrum.
        if isempty(app.Image)
            return;
        end
        [M, N, ~] = size(app.Image);
        [~, ~, F] = applyFilter(app.Image, ones(M, N));   % H = 1: just the spectrum
        showImage(L.Axes(2), app.Image, 'Degraded');
        showImage(L.Axes(5), spectrumImage(F), 'Degraded spectrum');
    end
end
