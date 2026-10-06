function D = freqDistance(M, N, du, dv)
% FREQDISTANCE  Distance of every frequency sample from the spectrum centre.
%
%   Builds the D(u,v) matrix that every filter in this project is defined
%   on. The spectrum is assumed centred with fftshift, so DC sits at
%   (uc, vc) = (floor(M/2)+1, floor(N/2)+1) for both even and odd sizes.
%   With an offset, distance is measured from (uc+du, vc+dv) instead; the
%   notch filter uses this for notches that sit away from the centre.
%
%       D(u,v) = sqrt((u - uc - du)^2 + (v - vc - dv)^2)
%
%   INPUT
%     M   number of rows of the spectrum (positive integer)
%     N   number of columns of the spectrum (positive integer)
%     du  optional, row offset of the reference point from the centre,
%         in frequency samples (real, default 0)
%     dv  optional, column offset of the reference point from the centre,
%         in frequency samples (real, default 0)
%
%   OUTPUT
%     D   M x N double, D >= 0. Row index is u, column index is v.

arguments
    M  (1,1) {mustBeInteger, mustBePositive}
    N  (1,1) {mustBeInteger, mustBePositive}
    du (1,1) {mustBeReal} = 0
    dv (1,1) {mustBeReal} = 0
end

uc = floor(M/2) + 1 + du;
vc = floor(N/2) + 1 + dv;

[V, U] = meshgrid(1:N, 1:M);   % U(i,j) = i (row index), V(i,j) = j (column index)
D = sqrt((U - uc).^2 + (V - vc).^2);
end
