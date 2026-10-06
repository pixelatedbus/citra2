function tests = test_freqDistance
% Tests for freqDistance. Run: runtests('tests/test_freqDistance.m')
tests = functiontests(localfunctions);
end

function testSize(tc)
    for sz = [4 6; 5 7; 427 640]'
        D = freqDistance(sz(1), sz(2));
        verifySize(tc, D, sz');
    end
end

function testZeroIsWhereFftshiftPutsDC(tc)
    % A constant image has all its energy in DC, so the peak of the
    % shifted spectrum marks the centre. D must be zero exactly there.
    for sz = [4 6; 5 7; 6 5; 427 640]'
        M = sz(1); N = sz(2);
        F = fftshift(fft2(ones(M, N)));
        [~, iPeak] = max(abs(F(:)));
        D = freqDistance(M, N);
        [~, iZero] = min(D(:));
        verifyEqual(tc, iZero, iPeak, sprintf('size %dx%d', M, N));
        verifyEqual(tc, nnz(D == 0), 1);
    end
end

function testRowsAreUColumnsAreV(tc)
    % Non-square size so a row/column swap would show.
    M = 9; N = 12;
    uc = floor(M/2) + 1; vc = floor(N/2) + 1;
    D = freqDistance(M, N);
    verifyEqual(tc, D(uc, vc + 3), 3);       % 3 columns right
    verifyEqual(tc, D(uc - 4, vc), 4);       % 4 rows up
    verifyEqual(tc, D(uc + 3, vc + 4), 5);   % 3-4-5 triangle
end

function testOffsetMovesTheZero(tc)
    M = 10; N = 11;
    uc = floor(M/2) + 1; vc = floor(N/2) + 1;
    D = freqDistance(M, N, 2, -3);
    [r, c] = find(D == 0);
    verifyEqual(tc, [r c], [uc + 2, vc - 3]);
end

function testRejectsBadSize(tc)
    verifyError(tc, @() freqDistance(0, 5), 'MATLAB:validators:mustBePositive');
    verifyError(tc, @() freqDistance(4.5, 5), 'MATLAB:validators:mustBeInteger');
end
