function [L, theta] = motionParamsFromName(fileName)
% Blur length and angle from a name like 'coins_gray_motion_L23_A35.png', or [] when the name has none.
[~, name] = fileparts(fileName);
tokens = regexp(name, '_L(\d+(?:\.\d+)?)_A(-?\d+(?:\.\d+)?)', 'tokens', 'once');
L = [];
theta = [];
if ~isempty(tokens)
    L = str2double(tokens{1});
    theta = str2double(tokens{2});
end
end
