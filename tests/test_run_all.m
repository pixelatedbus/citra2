function tests = test_run_all
% End-to-end test of run_all on a small fake data folder (temporary).
% Checks only the contract (folders, CSV, merge), not what each run_partX
% computes, so it keeps passing when the owners fill in their parts.
% Run: runtests('tests/test_run_all.m')
tests = functiontests(localfunctions);
end

function setup(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    root = fixture.Folder;
    data = fullfile(root, 'data');
    mkdir(fullfile(data, 'B_fake', 'input'));
    mkdir(fullfile(data, 'B_fake', 'reference'));
    mkdir(fullfile(data, 'C_fake', 'input'));
    imwrite(uint8(255 * rand(16, 20)), fullfile(data, 'B_fake', 'input', 'tile_gray_noise.png'));
    imwrite(uint8(255 * rand(16, 20)), fullfile(data, 'B_fake', 'reference', 'tile_gray.png'));
    imwrite(uint8(255 * rand(16, 20, 3)), fullfile(data, 'C_fake', 'input', 'tile_color.png'));
    tc.TestData.data = data;
    tc.TestData.results = fullfile(root, 'results');
end

function testWritesCsvAndPartFolders(tc)
    run_all('BC', tc.TestData.data, tc.TestData.results);
    verifyTrue(tc, isfolder(fullfile(tc.TestData.results, 'B')));
    verifyTrue(tc, isfolder(fullfile(tc.TestData.results, 'C')));
    T = readtable(fullfile(tc.TestData.results, 'params.csv'), 'TextType', 'string');
    verifyEqual(tc, unique(T.part)', ["B" "C"]);
end

function testRunningOnePartKeepsTheOther(tc)
    run_all('BC', tc.TestData.data, tc.TestData.results);
    T = run_all('B', tc.TestData.data, tc.TestData.results);
    verifyEqual(tc, unique(T.part)', ["B" "C"]);
end

function testMissingDataFolderErrors(tc)
    verifyError(tc, @() run_all('E', tc.TestData.data, tc.TestData.results), 'run_all:noData');
end
