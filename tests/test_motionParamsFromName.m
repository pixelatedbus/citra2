function tests = test_motionParamsFromName
% Tests for motionParamsFromName. Run: runtests('tests/test_motionParamsFromName.m')
tests = functiontests(localfunctions);
end

function testOfficialNames(tc)
    [L, theta] = motionParamsFromName('coins_gray_motion_L23_A35.png');
    verifyEqual(tc, [L theta], [23 35]);
    [L, theta] = motionParamsFromName(fullfile('data', 'x', 'retina_color_motion_L15_A-25_gaussian_noise.png'));
    verifyEqual(tc, [L theta], [15 -25]);
    [L, theta] = motionParamsFromName('brick_gray_motion_L17_A0.png');
    verifyEqual(tc, [L theta], [17 0]);
end

function testNoParameters(tc)
    [L, theta] = motionParamsFromName('coins_gray.png');
    verifyEmpty(tc, L);
    verifyEmpty(tc, theta);
end
