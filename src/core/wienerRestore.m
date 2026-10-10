function [f, R] = wienerRestore(g, H, K)
% Wiener filter conj(H) ./ (|H|^2 + K) with a constant noise-to-signal ratio K.
R = conj(H) ./ (abs(H).^2 + K);
R(H == 0) = 0;
f = applyFilter(g, R);
end
