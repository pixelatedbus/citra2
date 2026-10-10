function out = highpassDisplay(g, mode)
% HIGHPASSDISPLAY  Map a high-pass result (which has negative values) to [0,1] for display.
%
%   A high-pass filter removes the mean (H = 0 at the centre), so the
%   result g is centred on 0: edges are positive on one side and negative
%   on the other, flat areas are ~0. Showing g directly would clip all the
%   negative half to black. Three ways to display it:
%
%       'abs'             |g|                     flat areas black, edges bright
%                                                 (the look of the spec's example)
%       'abs-normalized'  |g| / max|g|            same, stretched so the strongest
%                                                 edge is white (weak results stay visible)
%       'rescale'         (g - min g)/(max g - min g)  flat areas mid-grey, keeps the
%                                                 sign: dark/bright on either side of an edge
%
%   Colour images are mapped with one max/min over all channels, so the
%   colour balance between channels is kept. A result that is all zero
%   maps to all zeros (no division by zero).
%
%   INPUT
%     g     high-pass result, M x N or M x N x C, double (may be negative)
%     mode  'abs' | 'abs-normalized' | 'rescale' (text)
%
%   OUTPUT
%     out   same size as g, double in [0,1] for 'abs-normalized' and 'rescale';
%           for 'abs', |g| (normally <= 1, clipped when displayed)

arguments
    g    {mustBeNumeric, mustBeReal}
    mode {mustBeTextScalar}
end

switch lower(mode)
    case 'abs'
        out = abs(g);
    case 'abs-normalized'
        out = abs(g);
        peak = max(out, [], 'all');
        if peak > 0
            out = out / peak;
        end
    case 'rescale'
        lo = min(g, [], 'all');
        hi = max(g, [], 'all');
        if hi > lo
            out = (g - lo) / (hi - lo);
        else
            out = zeros(size(g));
        end
    otherwise
        error('highpassDisplay:unknownMode', ...
            'Unknown mode "%s". Use abs, abs-normalized or rescale.', mode);
end
end
