function txt = psnrText(app, g)
% "PSNR vs reference: input -> result" text for the loaded image, or '' when it has no matching reference.
txt = '';
refPath = findReference(fileparts(fileparts(app.ImagePath)), app.ImagePath);
if isempty(refPath)
    return;
end
ref = readImageFile(refPath);
if isequal(size(ref), size(g))
    [~, before] = imageQuality(app.Image, ref);
    [~, after] = imageQuality(g, ref);
    txt = sprintf('  |  PSNR vs reference: input %.2f dB -> result %.2f dB', before, after);
end
end
