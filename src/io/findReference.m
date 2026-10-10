function refPath = findReference(dataDir, inputFile)
% Reference image of an input: the longest reference name that equals the input name or prefixes it plus '_'.
refPath = '';
bestLength = 0;
[~, inName] = fileparts(inputFile);
refs = dir(fullfile(dataDir, 'reference', '*.*'));
refs = refs(~[refs.isdir]);
for k = 1:numel(refs)
    [~, refName] = fileparts(refs(k).name);
    matches = strcmp(inName, refName) || startsWith(inName, [refName '_']);
    if matches && strlength(refName) > bestLength
        refPath = fullfile(refs(k).folder, refs(k).name);
        bestLength = strlength(refName);
    end
end
end
