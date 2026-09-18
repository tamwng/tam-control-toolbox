function [numericalRank,condition,valid] = study2_gram_diagnostic(G)
%STUDY2_GRAM_DIAGNOSTIC SVD rank at relative threshold 1e-10.
% Strictly greater singular values count toward rank. Numerical deficiency
% gives Inf condition; it does not claim exact algebraic singularity.
% Invalid matrices return NaN diagnostics and valid=false.
numericalRank = NaN;
condition = NaN;
valid = false;
if ~isa(G,'double') || ~ismatrix(G) || isempty(G) || ~isreal(G) || ...
        size(G,1) ~= size(G,2) || any(~isfinite(G),'all')
    return
end
try
    singular = svd(G);
catch
    return
end
if any(~isfinite(singular))
    return
end
valid = true;
if singular(1) == 0
    numericalRank = 0;
else
    numericalRank = nnz(singular > 1e-10*singular(1));
end
condition = Inf;
if numericalRank == size(G,1)
    condition = singular(1)/singular(end);
end
end
