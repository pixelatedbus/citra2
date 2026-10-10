function T = resultRow(part, image, method, params, mse, psnr)
% One row of results/params.csv (part, image, method, params, mse, psnr); no arguments gives an empty table.
names = {'part', 'image', 'method', 'params', 'mse', 'psnr'};
if nargin == 0
    T = table('Size', [0 6], 'VariableTypes', {'string', 'string', 'string', 'string', 'double', 'double'}, ...
        'VariableNames', names);
else
    T = table(string(part), string(image), string(method), string(params), double(mse), double(psnr), ...
        'VariableNames', names);
end
end
