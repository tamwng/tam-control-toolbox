function [model,theta0,labels,name] = study5_model(id,cfg)
%STUDY5_MODEL Fixed structures and raw priors; only K receives true parameters.
switch char(id)
    case {'I','K'}
        model = physical_model(cfg.Ts,cfg.predictorSubsteps);
        theta0 = [.8;.3]; labels = {'J','d_C'}; name = 'Integrated physical';
        if strcmp(id,'K'), theta0 = cfg.trueParameters; name = 'Known-model reference'; end
    case 'D'
        model = direct_model(1,1,1,2,@euler_features,@known_state);
        theta0 = [cfg.Ts/.8;-.3*cfg.Ts/.8];
        labels = {'alpha_1','alpha_2'}; name = 'Euler-informed direct';
    case {'A','P3'}
        [model,~,labels,name] = study2_model(id);
        theta0 = zeros(model.ntheta,1); theta0(2:3) = [1;cfg.Ts/.8];
        if strcmp(id,'P3'), theta0(7) = -.3*cfg.Ts/.8; end
    otherwise
        error('study5:Model','Unknown Study 5 model.');
end
end
function [phi,J] = euler_features(z)
phi = [z(2);z(1)^3]; J = [0 1;3*z(1)^2 0];
end
function [value,J] = known_state(z)
value = z(1); J = [1 0];
end
