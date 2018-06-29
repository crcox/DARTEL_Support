function b = isThreeElementVector(x)
% This basic test should suffice, unless it needs to be a row vector (with
% extent only in the second dimension).
    b = numel(x) == 3;
end
