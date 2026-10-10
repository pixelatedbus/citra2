function [L, theta] = motionParamsFromName(fileName)
% MOTIONPARAMSFROMNAME  Motion blur length and angle written in a file name.
%
%   The part F test images carry their blur parameters in the name, e.g.
%   'coins_gray_motion_L23_A35.png' (length 23, angle 35 degrees) or
%   'retina_color_motion_L15_A-25_gaussian_noise.png' (angle -25). The
%   data README gives the same values. This reads the "_L<n>_A<n>" part so
%   the GUI and the batch run can fill in the PSF parameters.
%
%   INPUT
%     fileName  file name or path (text)
%
%   OUTPUT
%     L, theta  length (pixels) and angle (degrees) as doubles,
%               or [] and [] when the name has no "_L<n>_A<n>" part

arguments
    fileName {mustBeTextScalar}
end

[~, name] = fileparts(fileName);
tokens = regexp(name, '_L(\d+(?:\.\d+)?)_A(-?\d+(?:\.\d+)?)', 'tokens', 'once');
if isempty(tokens)
    L = [];
    theta = [];
else
    L = str2double(tokens{1});
    theta = str2double(tokens{2});
end
end
