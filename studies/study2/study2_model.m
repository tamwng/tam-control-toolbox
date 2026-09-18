function [model,theta0,labels,name] = study2_model(id)
%STUDY2_MODEL Ordered Plant B dictionaries and priors, Eqs. (47)-(48).
% Odd powers have independent coefficients; no sine-series ratios are used.
% Only the known-model reference receives the true sine coefficient.

switch char(id)
    case 'A'
        powers = [0 0;1 0;0 1];
        labels = {'d','a','b'};
        name = 'Affine';
    case 'E'
        model = direct_model(1,1,1,3,@sine_features);
        theta0 = [0;0.5;0.25];
        labels = {'d','a','b_sin'};
        name = 'Exact sine';
        return
    case 'O3'
        powers = [0 0;1 0;0 1;0 3];
        labels = {'d','a','b','b_u3'};
        name = 'Odd cubic';
    case 'O5'
        powers = [0 0;1 0;0 1;0 3;0 5];
        labels = {'d','a','b','b_u3','b_u5'};
        name = 'Odd quintic';
    case 'P3'
        powers = [0 0;1 0;0 1;2 0;1 1;0 2;3 0;2 1;1 2;0 3];
        labels = {'d','a','b','q_xx','q_xu','q_uu', ...
            'c_xxx','c_xxu','c_xuu','c_uuu'};
        name = 'Complete cubic';
    case 'K'
        model = direct_model(1,1,1,3,@sine_features);
        theta0 = [0.03;0.65;0.40];
        labels = {'d','a','b_sin'};
        name = 'Known model';
        return
    otherwise
        error('study2:UnknownModel','Unknown Study 2 model: %s.',char(id));
end
model = direct_model(1,1,1,size(powers,1),@(z) polynomial_features(z,powers));
theta0 = [0;0.5;0.25;zeros(size(powers,1)-3,1)];
end

function [phi,J] = sine_features(z)
phi = [1;z(1);sin(z(2))];
J = [0 0;1 0;0 cos(z(2))];
end
