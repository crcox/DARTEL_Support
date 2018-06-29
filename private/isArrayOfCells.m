function b = isArrayOfCells(x)
    b = iscell(x) && iscell(x{1});
    if ~b
        warning('ChildImages need to be supplied as an array of cells, even if you are only warping a single set of images.');
    end
end