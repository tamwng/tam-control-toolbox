function [model,theta0,labels] = study1_model(id)
%STUDY1_MODEL Ordered stationary Plant A regressors from Table 4.
% S and W each estimate one coefficient for their supplied coupled term.
% Only the explicit known-model reference K receives true coefficients.

switch char(id)
    case 'A'
        model = direct_model(1,1,1,3,@affine_features);
        theta0 = [0;0.5;0.25];
        labels = {'d','a','b'};
    case 'S'
        model = direct_model(1,1,1,3,@shared_features);
        theta0 = [0;0.5;0.25];
        labels = {'d','a','b'};
    case 'W'
        model = direct_model(1,1,1,3,@wrong_features);
        theta0 = [0;0.5;0.25];
        labels = {'d','a','b'};
    case 'R'
        model = direct_model(1,1,1,4,@relaxed_features);
        theta0 = [0;0.5;0.25;0.25*0.35];
        labels = {'d','a','b','b_xu'};
    case 'P2'
        model = direct_model(1,1,1,6,@quadratic_features);
        theta0 = [0;0.5;0.25;0;0.25*0.35;0];
        labels = {'d','a','b','q_xx','q_xu','q_uu'};
    case 'K'
        model = direct_model(1,1,1,3,@shared_features);
        theta0 = [0.03;0.65;0.45];
        labels = {'d','a','b'};
    otherwise
        error('study1:UnknownModel','Unknown Study 1 model: %s.',char(id));
end
end

function [phi,J] = affine_features(z)
phi = [1;z(1);z(2)];
J = [0 0;1 0;0 1];
end

function [phi,J] = shared_features(z)
x = z(1); u = z(2);
phi = [1;x;(1+0.35*x)*u];
J = [0 0;1 0;0.35*u 1+0.35*x];
end

function [phi,J] = wrong_features(z)
x = z(1); u = z(2);
phi = [1;x;(1-0.35*x)*u];
J = [0 0;1 0;-0.35*u 1-0.35*x];
end

function [phi,J] = relaxed_features(z)
x = z(1); u = z(2);
phi = [1;x;u;x*u];
J = [0 0;1 0;0 1;u x];
end

function [phi,J] = quadratic_features(z)
[phi,J] = polynomial_features(z,[0 0;1 0;0 1;2 0;1 1;0 2]);
end
