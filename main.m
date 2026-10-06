function app = main()
% MAIN  Entry point: put src/ on the path and open the GUI.
%
%   Adds src/ and all its subfolders to the MATLAB path, then opens the
%   FreqApp window. From the project root: matlab -r "main", or type main
%   in the MATLAB command window.
%
%   INPUT
%     none
%
%   OUTPUT
%     app  optional, the FreqApp object (handy for debugging); nothing is
%          printed when main is called without an output

root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'src')));

appObj = FreqApp();
if nargout > 0
    app = appObj;
end
end
