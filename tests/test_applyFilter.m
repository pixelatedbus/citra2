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
    H = rand(7, 6);
    [~, G, F] = applyFilter(img, H);
    verifySize(tc, F, [7 6 3]);
    for c = 1:3
        verifyEqual(tc, F(4, 4, c), complex(sum(img(:, :, c), 'all')), 'AbsTol', 1e-10);
    end
    verifyEqual(tc, G, H .* F, 'AbsTol', 1e-12);
end

function testRejectsWrongSizeH(tc)
    verifyError(tc, @() applyFilter(rand(8, 6), ones(6, 8)), 'applyFilter:sizeMismatch');
end
