function H = highpassH(M, N, type, D0, n)
% Centred high-pass H(u,v) = 1 - low-pass of the same type.
if nargin < 5, n = 2; end
H = 1 - lowpassH(M, N, type, D0, n);
end
