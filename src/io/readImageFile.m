function img = readImageFile(filePath)
% Reads an image as double in [0,1]; indexed images become RGB, and only grey or RGB is accepted.
[img, map] = imread(filePath);
if ~isempty(map)
    img = ind2rgb(img, map);
end
img = im2double(img);
if ~ismember(size(img, 3), [1 3])
    [~, name, ext] = fileparts(filePath);
    error('readImageFile:channels', '%s%s has %d channels; only grey or RGB images are supported.', ...
        name, ext, size(img, 3));
end
end
