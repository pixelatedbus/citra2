function out = highpassDisplay(g, mode)
% Maps a signed high-pass result to [0,1] with 'abs', 'abs-normalized' or 'rescale'.
switch lower(mode)
    case 'abs'
        out = abs(g);
    case 'abs-normalized'
        out = abs(g);
        if max(out(:)) > 0
            out = out / max(out(:));
        end
    case 'rescale'
        lo = min(g(:));
        hi = max(g(:));
        if hi > lo
            out = (g - lo) / (hi - lo);
        else
            out = zeros(size(g));
        end
    otherwise
        error('highpassDisplay:unknownMode', 'Unknown display mode "%s".', mode);
end
end
