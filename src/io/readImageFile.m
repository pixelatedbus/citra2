function img = readImageFile(filePath)
% READIMAGEFILE  Read an image file as double in [0,1], grey or RGB.
%
%   The one place where image files are read, used by the GUI's "Load
%   image..." and by the batch scripts, so both see exactly the same data.
%   Steps: imread, indexed colour -> RGB (ind2rgb), any integer class ->
%   double in [0,1] (im2double). An alpha channel is ignored (imread
%   returns it separately). Every part supports grey (1 channel) and RGB
%   (3 channels) only, so anything else (e.g. a CMYK TIFF, 4 channels) is
%   rejected here with a clear message instead of failing later.
%
%   INPUT
%     filePath  path to an image file readable by imread (text)
%
%   OUTPUT
%     img       M x N (grey) or M x N x 3 (RGB) double in [0,1]

arguments
    filePath {mustBeTextScalar}
end

[img, map] = imread(filePath);
if ~isempty(map)
    img = ind2rgb(img, map);   % indexed image -> RGB, already double
end
img = im2double(img);

C = size(img, 3);
if C ~= 1 && C ~= 3
    [~, name, ext] = fileparts(filePath);
    error('readImageFile:channels', ...
        '%s%s has %d channels. Only grey (1) or RGB (3) images are supported.', ...
        name, ext, C);
end
end
