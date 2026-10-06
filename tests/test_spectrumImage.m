function tests = test_spectrumImage
% Tests for spectrumImage. Run: runtests('tests/test_spectrumImage.m')
tests = functiontests(localfunctions);
end

function testRangeAndSize(tc)
    rng(3);
    F = fftshift(fft2(rand(9, 12)));
    S = spectrumImage(F);
    verifySize(tc, S, [9 12]);
    verifyGreaterThanOrEqual(tc, min(S(:)), 0);
    verifyEqual(tc, max(S(:)), 1);
end

function testColourGivesOnePicture(tc)
    [~, ~, F] = applyFilter(rand(9, 12, 3), ones(9, 12));   % F is 9 x 12 x 3
    S = spectrumImage(F);
    verifySize(tc, S, [9 12]);
    verifyEqual(tc, max(S(:)), 1);
end

function testConstantImageIsSingleDot(tc)
    % A constant image has only DC, so only the centre is lit.
    M = 7; N = 8;
    S = spectrumImage(fftshift(fft2(ones(M, N))));
    expected = zeros(M, N);
    expected(floor(M/2) + 1, floor(N/2) + 1) = 1;
    verifyEqual(tc, S, expected, 'AbsTol', 1e-12);
end

function testZeroSpectrumStaysZero(tc)
    S = spectrumImage(zeros(5, 6));
    verifyEqual(tc, S, zeros(5, 6));
end
