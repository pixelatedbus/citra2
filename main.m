function app = main()
% Adds src/ to the path and opens the frequency-domain image processing app.
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'src')));
window = FreqApp();
if nargout > 0
    app = window;
end
end
