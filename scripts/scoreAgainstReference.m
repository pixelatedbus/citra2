function [mse, psnr] = scoreAgainstReference(img, dataDir, inputFile)
% SCOREAGAINSTREFERENCE  MSE and PSNR of a result against its input's reference image.
%
%   Finds the reference of inputFile (findReference), reads it
%   (readImageFile) and scores img against it (imageQuality). When there is
%   no reference (part C) or the sizes differ (e.g. a grey result against a
%   colour reference), both scores are NaN instead of an error, matching
%   "compute MSE and PSNR where a reference exists and sizes match".
%
%   INPUT
%     img        result image, double, M x N or M x N x 3
%     dataDir    part folder that holds input/ and reference/ (text)
%     inputFile  path or name of the input image img came from (text)
%
%   OUTPUT
%     mse, psnr  scores from imageQuality, or NaN, NaN

mse = NaN;
psnr = NaN;

refPath = findReference(dataDir, inputFile);
if isempty(refPath)
    return;
end
ref = readImageFile(refPath);
if isequal(size(img), size(ref))
    [mse, psnr] = imageQuality(img, ref);
end
end
