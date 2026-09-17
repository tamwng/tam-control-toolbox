function model = direct_model(p,m,ell,featureCount,features,known,sharing)
%DIRECT_MODEL Define a fixed direct regressor and measured-history state.
%   FEATURES(z) returns a q-by-1 column and its q-by-(n+m) Jacobian,
%   where z=[xi;u]. KNOWN(z) supplies the known output and its Jacobian.
%   SHARING maps independent coefficients into column-major vec(Theta),
%   as in manuscript Eq. (16). Empty KNOWN and SHARING select zero and I.
validateattributes(p,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(m,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(ell,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(featureCount,{'numeric'},{'scalar','integer','positive','finite'});
if ~isa(features,'function_handle')
    error('ejc:InvalidFeatures','Features must be a function handle.');
end
if nargin < 6 || isempty(known)
    known = [];
elseif ~isa(known,'function_handle')
    error('ejc:InvalidKnown','Known contribution must be a function handle.');
end
if nargin < 7 || isempty(sharing)
    sharing = eye(p*featureCount);
end
validateattributes(sharing,{'numeric'},{'2d','real','finite','nonempty'});
if size(sharing,1) ~= p*featureCount || rank(sharing) ~= size(sharing,2)
    error('ejc:InvalidSharing','Sharing must have p*q rows and independent columns.');
end
n = p*ell + m*(ell-1);
model = struct('kind','direct','p',p,'m',m,'ell',ell,'n',n, ...
    'C',[eye(p),zeros(p,n-p)],'ntheta',size(sharing,2), ...
    'featureCount',featureCount,'features',features,'known',known, ...
    'sharing',sharing);
end
