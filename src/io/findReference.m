function refPath = findReference(dataDir, inputFile)
% FINDREFERENCE  Find the reference (ground-truth) image for an input image.
%
%   The official data names an input after its reference plus a suffix:
%       reference/astronaut_color.png
%       input/astronaut_color_gaussian_noise.png
%       input/astronaut_color_motion_L19_A20.png
%   So the reference is the file in <dataDir>/reference/ whose name equals
%   the input name, or is a prefix of it followed by '_'. If several match,
%   the longest name wins. Part C has no reference folder, which gives ''.
%
%   INPUT
%     dataDir    part folder that holds input/ and reference/ (text),
%                e.g. 'data/B_smoothing_blurring_frequency'
%     inputFile  input image path or file name (text)
%
%   OUTPUT
%     refPath    full path of the reference image, or '' if there is none

arguments
    dataDir   {mustBeTextScalar}
    inputFile {mustBeTextScalar}
end

refPath = '';
[~, inName] = fileparts(inputFile);
refs = dir(fullfile(dataDir, 'reference', '*.*'));
refs = refs(~[refs.isdir]);

bestLength = 0;
for k = 1:numel(refs)
    [~, refName] = fileparts(refs(k).name);
    matches = strcmp(inName, refName) || startsWith(inName, [refName '_']);
    if matches && strlength(refName) > bestLength
        refPath = fullfile(refs(k).folder, refs(k).name);
        bestLength = strlength(refName);
    end
end
end
