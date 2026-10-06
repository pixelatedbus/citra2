function tabE(app)
% TABE  Builds the part E tab (periodic noise restoration) inside app.Tabs.E.
%
%   PLACEHOLDER from the shared foundation; owner: Member 1, who replaces
%   the body with the real controls and the Apply / Save logic.
%   It already follows the tab contract: it uses buildPartLayout with the
%   views this part must show, and it redraws the input and its spectrum
%   whenever a new image is loaded (the app's ImageChanged event).
%
%   INPUT
%     app  the FreqApp object (reads app.Image, app.Tabs.E, app.Fig)
%
%   OUTPUT
%     none (fills app.Tabs.E)

L = buildPartLayout(app.Tabs.E, ...
    {'Degraded', 'Spectrum before', 'Mask H(u,v)', 'Spectrum after', 'Restored'});

msg = 'Part E is not implemented yet.';
note = uilabel(L.Controls, 'Text', msg, 'WordWrap', 'on');
note.Layout.Row = 1;
note.Layout.Column = [1 2];
L.Apply.ButtonPushedFcn = @(~, ~) uialert(app.Fig, msg, 'Part E');
L.Save.ButtonPushedFcn  = @(~, ~) uialert(app.Fig, msg, 'Part E');

addlistener(app, 'ImageChanged', @(~, ~) showInput());
showInput();

    function showInput()
        % Draw the loaded image and its centred spectrum.
        if isempty(app.Image)
            return;
        end
        [M, N, ~] = size(app.Image);
        [~, ~, F] = applyFilter(app.Image, ones(M, N));   % H = 1: just the spectrum
        showImage(L.Axes(1), app.Image, 'Degraded');
        showImage(L.Axes(2), spectrumImage(F), 'Spectrum before');
    end
end
