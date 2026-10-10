function [mse, psnr] = scoreAgainstReference(img, dataDir, inputFile)
% MSE and PSNR of img against the reference of inputFile, NaN when there is none or the size differs.
mse = NaN;
psnr = NaN;
refPath = findReference(dataDir, inputFile);
if ~isempty(refPath)
    ref = readImageFile(refPath);
    if isequal(size(img), size(ref))
        [mse, psnr] = imageQuality(img, ref);
    end
end
end
