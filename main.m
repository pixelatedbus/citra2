function app = main()
% MAIN  Entry point: put src/ on the path and open the GUI.
%   main            opens the window
%   app = main;     also returns the FreqApp object (handy for debugging)

root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'src')));

appObj = FreqApp();
if nargout > 0
    app = appObj;
end
end
