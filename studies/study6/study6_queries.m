function q = study6_queries(record,indices,initialization)
%STUDY6_QUERIES Copy common or within-run inputs; never generate new data.
% Each row is one mathematical anchor k; MATLAB data start at column k+1.
n = numel(indices); H = 20; j = indices+1;
assert(all(j >= 1 & j+H-1 <= numel(record.u)));
q = struct('indices',indices,'matlabColumns',j,'horizons',[1 2 5 10 20], ...
    'inputModes',{{'held','rateLimited'}},'initialization',initialization, ...
    'x',record.x(j).','y',record.x(j).','inputs',nan(n,H,2));
if strcmp(initialization,'measured'), q.y = record.y(j).'; end
for a = 1:n
    q.inputs(a,:,1) = repmat(record.u(j(a)),1,H);
    q.inputs(a,:,2) = record.u(j(a):j(a)+H-1);
end
q.inputProvenance = 'Copied from the saved record; no optimized or regenerated future inputs.';
end
