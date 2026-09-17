function model = physical_model(Ts,nSubsteps)
%PHYSICAL_MODEL Integrated identification and cubic-flow reconstruction.
%   Parameters are theta=[J;d], with J>0 and d>=0 (Eqs. (19)-(22)).
%   The estimator applies any admissibility mapping before reconstruction.
%   The predictor uses five RK4 substeps by default, as in Section 6.4.
if nargin < 2
    nSubsteps = 5;
end
validateattributes(Ts,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(nSubsteps,{'numeric'},{'scalar','real','finite','integer','positive'});
model = struct('kind','physical','n',1,'p',1,'m',1,'ntheta',2, ...
    'C',1,'Ts',Ts,'nSubsteps',nSubsteps);
end
