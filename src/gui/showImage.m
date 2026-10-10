function showImage(ax, img, titleText)
% Draws an image clipped to [0,1] on an axes with a title; an empty image clears the axes.
if nargin < 3, titleText = ''; end
if isempty(img)
    cla(ax);
elseif ~isreal(img)
    error('showImage:complex', 'Image is complex; pass abs(H) or spectrumImage(F) instead.');
else
    imshow(min(max(double(img), 0), 1), 'Parent', ax);
end
title(ax, titleText, 'Interpreter', 'none');
axis(ax, 'off');
end
