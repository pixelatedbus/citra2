function H = notchRejectH(M, N, type, notches, n)
% Notch reject H(u,v): every row [du dv r] removes a spike and its mirror, distances taken periodically.
if nargin < 5, n = 2; end
if size(notches, 2) ~= 3 || any(~isfinite(notches(:))) || any(notches(:, 3) <= 0)
    error('notchRejectH:badNotch', 'Every notch needs finite [du dv r] with r > 0.');
end
[V, U] = meshgrid(1:N, 1:M);
U = U - floor(M/2) - 1;
V = V - floor(N/2) - 1;
H = ones(M, N);
for k = 1:size(notches, 1)
    du = notches(k, 1);
    dv = notches(k, 2);
    r = notches(k, 3);
    H = H .* hole(hypot(wrap(U - du, M), wrap(V - dv, N)), type, r, n) ...
          .* hole(hypot(wrap(U + du, M), wrap(V + dv, N)), type, r, n);
end
end

function d = wrap(d, P)
d = mod(d + P/2, P) - P/2;
end

function H = hole(D, type, D0, n)
switch lower(type)
    case 'ideal'
        H = 1 - double(D <= D0);
    case 'gaussian'
        H = 1 - exp(-D.^2 / (2 * D0^2));
    case 'butterworth'
        H = 1 - 1 ./ (1 + (D / D0).^(2 * n));
    otherwise
        error('notchRejectH:unknownType', 'Unknown filter type "%s".', type);
end
end
