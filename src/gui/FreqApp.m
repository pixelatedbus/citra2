classdef FreqApp < handle
    % FREQAPP  Main window: one shared image and one tab per part (B to F).
    %
    %   Holds the image every tab works on, a "Load image..." bar, and a
    %   tab group. The constructor calls the five tab builders tabB(app)
    %   ... tabF(app). Each builder fills its own tab and listens to the
    %   ImageChanged event to redraw when a new image is loaded. If one
    %   builder fails, only that tab shows the error; the others still work.
    %   Closing the window deletes this object too (and deleting the object
    %   closes the window), so no listener outlives its tab.
    %
    %   Usage:  app = FreqApp();        normally through main
    %           app.loadImage(path);    load without the file dialog
    %
    %   INPUT
    %     none
    %
    %   OUTPUT
    %     app  FreqApp handle with public properties
    %          Fig        the uifigure
    %          Tabs       struct with fields B..F, each a uitab
    %          Image      loaded image, double in [0,1], M x N or M x N x 3
    %                     ([] before the first load)
    %          ImagePath  full path of the loaded file ('' before the first load)
    %          and the event ImageChanged, fired after each successful load

    properties
        Fig
        Tabs
        Image = []
        ImagePath = ''
    end

    properties (Access = private)
        PathLabel       % shows which file is loaded
    end

    events
        ImageChanged
    end

    methods
        function app = FreqApp()
            app.Fig = uifigure('Name', 'IF4073 Tugas 2 - Frequency Domain Processing', ...
                'Position', [100 100 1200 750]);
            app.Fig.DeleteFcn = @(~, ~) delete(app);

            root = uigridlayout(app.Fig, [2 1]);
            root.RowHeight = {'fit', '1x'};

            % Top bar: one image loader shared by all tabs
            bar = uigridlayout(root, [1 2]);
            bar.ColumnWidth = {'fit', '1x'};
            bar.Padding = [0 0 0 0];
            uibutton(bar, 'Text', 'Load image...', ...
                'ButtonPushedFcn', @(~, ~) app.onLoadPressed());
            app.PathLabel = uilabel(bar, 'Text', 'No image loaded');

            % One tab per part, each filled by its own builder (tabB.m ... tabF.m)
            group = uitabgroup(root);
            titles = struct('B', 'B. Low-pass', 'C', 'C. High-pass', ...
                'D', 'D. Brightness', 'E', 'E. Periodic noise', ...
                'F', 'F. Motion blur');
            for part = fieldnames(titles)'
                p = part{1};
                app.Tabs.(p) = uitab(group, 'Title', titles.(p));
                app.buildTab(p);
            end
        end

        function loadImage(app, filePath)
            % Load an image file, store it and notify the tabs.
            %   INPUT  filePath  path to a grey or RGB image file
            %   Errors from readImageFile are passed on; the previous image
            %   is then kept unchanged.
            img = readImageFile(filePath);
            app.Image = img;
            app.ImagePath = filePath;

            [~, name, ext] = fileparts(filePath);
            [M, N, C] = size(img);
            app.PathLabel.Text = sprintf('%s%s  (%d x %d x %d)', name, ext, M, N, C);
            notify(app, 'ImageChanged');
        end

        function delete(app)
            % Close the window when the object is deleted. Skipped when the
            % window itself is already closing (its DeleteFcn calls this).
            if ~isempty(app.Fig) && isvalid(app.Fig) && strcmp(app.Fig.BeingDeleted, 'off')
                delete(app.Fig);
            end
        end
    end

    methods (Access = private)
        function buildTab(app, part)
            % Run tab<part>(app); on failure show the error inside that tab only.
            try
                feval(['tab' part], app);
            catch err
                delete(app.Tabs.(part).Children);
                g = uigridlayout(app.Tabs.(part), [2 1]);
                g.RowHeight = {'fit', '1x'};
                uilabel(g, 'WordWrap', 'on', 'FontColor', [0.85 0.2 0.2], ...
                    'Text', sprintf('Tab %s failed to build: %s', part, err.message));
                warning('FreqApp:tabFailed', 'Tab %s failed to build: %s', part, err.message);
            end
        end

        function onLoadPressed(app)
            projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            [file, folder] = uigetfile( ...
                {'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Images'}, ...
                'Load image', fullfile(projectRoot, 'data'));
            figure(app.Fig);   % the dialog can push the window behind others
            if isequal(file, 0)
                return;        % user cancelled
            end
            try
                app.loadImage(fullfile(folder, file));
            catch err
                uialert(app.Fig, err.message, 'Could not load image');
            end
        end
    end
end
