function T = resultRow(part, image, method, params, mse, psnr)
% RESULTROW  One row of the results table, or an empty table, in the standard format.
%
%   Every run_partX returns a table built from these rows, and run_all
%   writes them all to results/params.csv. Building rows only through this
%   function keeps the columns and their types identical for both members,
%   so the tables can be stacked and the CSV feeds the report directly.
%
%   Columns: part | image | method | params | mse | psnr
%   Write params as "name=value" pairs joined by "; ", e.g.
%   "type=gaussian; D0=40". Use NaN for mse/psnr when there is no reference.
%
%   INPUT
%     none        -> returns an empty table with the six columns
%     part        part letter, e.g. 'B' (text)
%     image       input file name, e.g. 'coins_gray.png' (text)
%     method      method name, e.g. 'GLPF' or 'input' (text)
%     params      parameter string, see above (text, may be '')
%     mse, psnr   scores against the reference (double, NaN if none)
%
%   OUTPUT
%     T  table with variables part, image, method, params (string) and
%        mse, psnr (double); 0 rows or 1 row

names = {'part', 'image', 'method', 'params', 'mse', 'psnr'};
if nargin == 0
    T = table('Size', [0 6], ...
        'VariableTypes', {'string', 'string', 'string', 'string', 'double', 'double'}, ...
        'VariableNames', names);
    return;
end

T = table(string(part), string(image), string(method), string(params), ...
    double(mse), double(psnr), 'VariableNames', names);
end
