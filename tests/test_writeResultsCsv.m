function tests = test_writeResultsCsv
% Tests for writeResultsCsv. Writes CSVs in a temporary folder.
% Run: runtests('tests/test_writeResultsCsv.m')
tests = functiontests(localfunctions);
end

function setup(tc)
    fixture = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
    tc.TestData.csv = fullfile(fixture.Folder, 'params.csv');
end

function testRoundTripKeepsTypesInfAndNaN(tc)
    rows = [resultRow('B', 'a.png', 'input', '', 0, Inf)
            resultRow('C', 'b.png', 'IHPF', 'D0=30; n=2', NaN, NaN)];
    writeResultsCsv(rows, tc.TestData.csv, 'BC');
    back = writeResultsCsv(resultRow(), tc.TestData.csv, '');   % re-read, add nothing
    verifyEqual(tc, back, rows);
end

function testRerunReplacesOnlyThosePartsRows(tc)
    csv = tc.TestData.csv;
    writeResultsCsv([resultRow('B', 'a.png', 'old', '', 1, 1)
                     resultRow('D', 'd.png', 'partner', '', 2, 2)], csv, 'BD');
    T = writeResultsCsv(resultRow('B', 'a.png', 'new', '', 3, 3), csv, 'B');
    verifyEqual(tc, T.method, ["new"; "partner"]);   % B replaced, D kept
end

function testSortedByPartImageMethod(tc)
    rows = [resultRow('E', 'z.png', 'b', '', 1, 1)
            resultRow('B', 'y.png', 'b', '', 1, 1)
            resultRow('B', 'y.png', 'a', '', 1, 1)];
    T = writeResultsCsv(rows, tc.TestData.csv, 'BE');
    verifyEqual(tc, T.part + T.method, ["Ba"; "Bb"; "Eb"]);
end
