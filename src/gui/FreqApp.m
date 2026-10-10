classdef FreqApp < handle
    % Main window: one shared image, a load button and one tab per part (B to F).

    properties
        Fig
        Tabs
        Image = []
        ImagePath = ''
    end

    properties (Access = private)
        PathLabel
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
            bar = uigridlayout(root, [1 2]);
            bar.ColumnWidth = {'fit', '1x'};
            bar.Padding = [0 0 0 0];
            uibutton(bar, 'Text', 'Load image...', 'ButtonPushedFcn', @(~, ~) app.onLoadPressed());
            app.PathLabel = uilabel(bar, 'Text', 'No image loaded');

            group = uitabgroup(root);
            titles = struct('B', 'B. Low-pass', 'C', 'C. High-pass', 'D', 'D. Brightness', ...
                'E', 'E. Periodic noise', 'F', 'F. Motion blur');
            for part = fieldnames(titles)'
                p = part{1};
                app.Tabs.(p) = uitab(group, 'Title', titles.(p));
                app.buildTab(p);
            end
        end

        function loadImage(app, filePath)
            img = readImageFile(filePath);
            app.Image = img;
            app.ImagePath = filePath;
            [~, name, ext] = fileparts(filePath);
            [M, N, C] = size(img);
            app.PathLabel.Text = sprintf('%s%s  (%d x %d x %d)', name, ext, M, N, C);
            notify(app, 'ImageChanged');
        end

        function delete(app)
            if ~isempty(app.Fig) && isvalid(app.Fig) && strcmp(app.Fig.BeingDeleted, 'off')
                delete(app.Fig);
            end
        end
    end

    methods (Access = private)
        function buildTab(app, part)
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
            [file, folder] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Images'}, ...
                'Load image', fullfile(projectRoot, 'data'));
            figure(app.Fig);
            if isequal(file, 0)
                return;
            end
            try
                app.loadImage(fullfile(folder, file));
            catch err
                uialert(app.Fig, err.message, 'Could not load image');
            end
        end
    end
end
