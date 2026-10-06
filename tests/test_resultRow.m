function tests = test_resultRow
% Tests for resultRow. Run: runtests('tests/test_resultRow.m')
tests = functiontests(localfunctions);
end

function testEmptyTableHasTheColumns(tc)
    T = resultRow();
    verifyEqual(tc, height(T), 0);
    verifyEqual(tc, T.Properties.VariableNames, {'part', 'image', 'method', 'params', 'mse', 'psnr'});
    verifyEqual(tc, varfun(@class, T, 'OutputFormat', 'cell'), ...
        {'string', 'string', 'string', 'string', 'double', 'double'});
end

function testRowTypesAndStacking(tc)
    r1 = resultRow('B', 'a.png', 'GLPF', "type=gaussian; D0=40", 0.01, 20);
    r2 = resultRow("C", "b.png", "IHPF", '', NaN, NaN);   % char or string both fine
    T = [resultRow(); r1; r2];
    verifyEqual(tc, height(T), 2);
    verifyEqual(tc, T.part, ["B"; "C"]);
    verifyEqual(tc, T.params(2), "");
    verifyTrue(tc, isnan(T.psnr(2)));
end
