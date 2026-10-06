function tests = test_applyFilter
% Tests for applyFilter. Run: runtests('tests/test_applyFilter.m')
tests = functiontests(localfunctions);
end

function testAllPassReturnsInput(tc)
    % H = ones changes nothing: grey and colour, even and odd sizes.
    rng(1);
    for f = {rand(6, 8), rand(7, 5), rand(9, 10, 3), rand(5, 7, 3)}
        img = f{1};
        g = applyFilter(img, ones(size(img, 1), size(img, 2)));
        verifySize(tc, g, size(img));
        verifyEqual(tc, g, img, 'AbsTol', 1e-10);
    end
end

function testAllStopReturnsZeros(tc)
    img = rand(8, 6, 3);
    g = applyFilter(img, zeros(8, 6));
    verifyEqual(tc, g, zeros(size(img)));
end

function testDcOnlyGivesChannelMean(tc)
    % Keeping only the centre sample keeps only the mean of each channel.
    % This fails if H's centre and fftshift's DC position disagree.
    rng(2);
    for sz = [8 6; 7 5]'
        M = sz(1); N = sz(2);
        img = rand(M, N, 3);
        H = zeros(M, N);
        H(floor(M/2) + 1, floor(N/2) + 1) = 1;
        g = applyFilter(img, H);
        for c = 1:3
            verifyEqual(tc, g(:, :, c), mean(img(:, :, c), 'all') * ones(M, N), ...
                'AbsTol', 1e-12);
        end
    end
end

function testSpectrumOutputs(tc)
    % F at the centre is the DC term: the sum of all pixels of that channel.
    img = rand(7, 6, 3);
    H = lowpassH(7, 6, 'gaussian', 2);   % a valid (symmetric) filter, so no warning
    [~, G, F] = applyFilter(img, H);
    verifySize(tc, F, [7 6 3]);
    for c = 1:3
        verifyEqual(tc, F(4, 4, c), complex(sum(img(:, :, c), 'all')), 'AbsTol', 1e-10);
    end
    verifyEqual(tc, G, H .* F, 'AbsTol', 1e-12);
end

function testSymmetricHGivesNoWarning(tc)
    % Low-pass filters are symmetric about the centre: no warning, even and odd sizes.
    rng(5);
    for sz = [8 6; 7 9]'
        img = rand(sz(1), sz(2), 3);
        H = lowpassH(sz(1), sz(2), 'butterworth', 2);
        verifyWarningFree(tc, @() applyFilter(img, H));
    end
end

function testOneSidedNotchWarns(tc)
    % Removing a frequency without its mirror partner is a typical E mistake.
    rng(6);
    M = 16; N = 16;
    H = ones(M, N);
    H(floor(M/2) + 1, floor(N/2) + 1 + 3) = 0;   % notch at +3, no notch at -3
    verifyWarning(tc, @() applyFilter(rand(M, N), H), 'applyFilter:complexResult');
end

function testComplexHFromRealPsf(tc)
    % The part F route: H = centred FT of a real PSF (complex, but symmetric
    % in the conjugate sense). Must not warn, and must equal circular convolution.
    rng(7);
    psf = zeros(32);
    psf(1, 1:5) = 1/5;
    psf = circshift(psf, [0 -2]);   % PSF centre at index (1,1)
    H = fftshift(fft2(psf));
    img = rand(32);
    g = verifyWarningFree(tc, @() applyFilter(img, H));
    expected = real(ifft2(fft2(img) .* fft2(psf)));
    verifyEqual(tc, g, expected, 'AbsTol', 1e-12);
end

function testRejectsWrongSizeH(tc)
    verifyError(tc, @() applyFilter(rand(8, 6), ones(6, 8)), 'applyFilter:sizeMismatch');
end
