function showImage(ax, img, titleText)
% SHOWIMAGE  Draw an image, spectrum or filter on an axes, with a title.
%
%   One drawing routine for every axes in the GUI, so all tabs look the
%   same. Values are clipped to [0,1] for display only (the data itself is
%   not changed), following the project convention "clip only when
%   displaying or saving". Display modes such as |g| or rescaling for
%   high-pass results are the caller's job, done before calling this.
%   An empty image clears the axes but keeps the title, which is used
%   before an image is loaded.
%
%   INPUT
%     ax         target axes (uiaxes or axes)
%     img        M x N (grey) or M x N x 3 (colour) real numeric or logical,
%                normally in [0,1]; [] clears the axes. For a spectrum pass
%                spectrumImage(F); for a complex H pass abs(H).
%     titleText  optional, title shown above the image (text, default '')
%
%   OUTPUT
%     none (draws on ax)

arguments
    ax  (1,1)
    img
    titleText {mustBeTextScalar} = ''
end

if isempty(img)
    cla(ax);
else
    if ~isreal(img)
        error('showImage:complex', ...
            'Image is complex. Pass abs(H) or spectrumImage(F) instead.');
    end
    imshow(min(max(double(img), 0), 1), 'Parent', ax);
end

title(ax, titleText, 'Interpreter', 'none');
axis(ax, 'off');
end
