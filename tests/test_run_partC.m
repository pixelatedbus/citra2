function tests = test_run_partC
% Tests for run_partC on a small fake part folder (temporary).
% Run: runtests('tests/test_run_partC.m')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    d = fixture.Folder;
    mkdir(fullfile(d, 'input'));
    mkdir(fullfile(d, 'out'));
    rng(13);
    imwrite(rand(40, 50, 3), fullfile(d, 'input', 'tile_color.png'));
    tc.TestData.dir = d;
    tc.TestData.rows = run_partC(d, fullfile(d, 'out'));
end

function testRowsPerInput(tc)
    rows = tc.TestData.rows;
    verifyEqual(tc, height(rows), 1 + 3 * 3);   % baseline + 3 types x 3 D0
    verifyEqual(tc, unique(rows.method)', ["BHPF" "GHPF" "IHPF" "input"]);
    verifyEqual(tc, sort(rows.params(rows.method == "BHPF"))', ["D0=10; n=2" "D0=30; n=2" "D0=60; n=2"]);
end

function testNoReferenceGivesNaN(tc)
    verifyTrue(tc, all(isnan(tc.TestData.rows.psnr)));
end

function testFigureWritten(tc)
    verifyTrue(tc, isfile(fullfile(tc.TestData.dir, 'out', 'tile_color_C.png')));
end
