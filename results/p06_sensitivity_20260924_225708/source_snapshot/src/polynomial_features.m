function [phi,Jphi] = polynomial_features(z,powers,center)
%POLYNOMIAL_FEATURES Evaluate an explicitly ordered, distinct monomial list.
%   Each row of POWERS is one multi-index in Eq. (13), including an all-zero
%   row for an unknown constant. CENTER is fixed, not the operating point.
validateattributes(z,{'numeric'},{'column','real','finite','nonempty'});
validateattributes(powers,{'numeric'},{'2d','real','finite','integer','nonnegative','nonempty'});
if size(powers,2) ~= numel(z) || size(unique(powers,'rows'),1) ~= size(powers,1)
    error('ejc:InvalidPowers','Powers must have one column per variable and distinct rows.');
end
if nargin < 3 || isempty(center)
    center = zeros(size(z));
end
validateattributes(center,{'numeric'},{'real','finite','size',size(z)});
delta = z-center;
phi = prod(delta.'.^powers,2);
Jphi = zeros(size(powers));
for j = 1:numel(z)
    selected = powers(:,j) > 0;
    reduced = powers(selected,:);
    reduced(:,j) = reduced(:,j)-1;
    Jphi(selected,j) = powers(selected,j).*prod(delta.'.^reduced,2);
end
end
