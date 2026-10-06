classdef FreqApp < handle
    % FREQAPP  Main window: shared image state and one tab per part (B-F).
    %   The tabs are empty for now; each part adds its own builder
    %   (tabB.m ... tabF.m) that fills app.Tabs.<part>.

    properties
        Fig             % uifigure
        Tabs            % struct with fields B..F, each a uitab
        Image = []      % loaded image, double in [0,1], M x N or M x N x 3
        ImagePath = ''  % full path of the loaded file
    end

    properties (Access = private)
        PathLabel       % shows which file is loaded
    end

    events
        ImageChanged    % fired after a new image is loaded
    end

    methods
        function app = FreqApp()
            app.Fig = uifigure('Name', 'IF4073 Tugas 2 - Frequency Domain Processing', ...
                'Position', [100 100 1200 750]);

            root = uigridlayout(app.Fig, [2 1]);
            root.RowHeight = {'fit', '1x'};

            % Top bar: one image loader shared by all tabs
            bar = uigridlayout(root, [1 2]);
            bar.ColumnWidth = {'fit', '1x'};
            bar.Padding = [0 0 0 0];
            uibutton(bar, 'Text', 'Load image...', ...
                'ButtonPushedFcn', @(~, ~) app.onLoadPressed());
            app.PathLabel = uilabel(bar, 'Text', 'No image loaded');

            % One tab per part of the assignment
            group = uitabgroup(root);
            titles = struct('B', 'B. Low-pass', 'C', 'C. High-pass', ...
                'D', 'D. Brightness', 'E', 'E. Periodic noise', ...
                'F', 'F. Motion blur');
            for part = fieldnames(titles)'
                p = part{1};
                app.Tabs.(p) = uitab(group, 'Title', titles.(p));
            end
        end

        function loadImage(app, filePath)
            % Read an image file and store it as double in [0,1].
            % Public so scripts can load without the file dialog.
            [img, map] = imread(filePath);
            if ~isempty(map)
                img = ind2rgb(img, map);   % indexed image -> RGB
            end
            app.Image = im2double(img);
            app.ImagePath = filePath;

            [~, name, ext] = fileparts(filePath);
            [M, N, C] = size(app.Image);
            app.PathLabel.Text = sprintf('%s%s  (%d x %d x %d)', name, ext, M, N, C);
            notify(app, 'ImageChanged');
        end
    end

    methods (Access = private)
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
