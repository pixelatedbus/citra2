function saveResultImage(app, img, suggestedName, part)
% Asks for a file name and writes img clipped to [0,1] as PNG; alerts when there is no result yet.
if isempty(img)
    uialert(app.Fig, 'Press Apply first.', ['Part ' part]);
    return;
end
[file, folder] = uiputfile('*.png', 'Save result', suggestedName);
figure(app.Fig);
if ~isequal(file, 0)
    imwrite(min(max(img, 0), 1), fullfile(folder, file));
end
end
