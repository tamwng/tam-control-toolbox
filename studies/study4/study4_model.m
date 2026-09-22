function [model,theta0,labels,name] = study4_model(id)
%STUDY4_MODEL Fixed complete order; every adaptive coefficient is unknown.
switch char(id)
    case 'A'
        [model,~,labels] = study1_model('A');
        name = 'Affine'; theta0 = [0;.5;.25];
    case 'Aplus'
        model = direct_model(1,1,1,4,@augmented);
        name = 'Augmented affine'; labels = {'d','a','b','q_xx'};
        theta0 = [0;.5;.25;0];
    case 'P2'
        [model,~,labels] = study1_model('P2');
        name = 'Complete quadratic'; theta0 = [0;.5;.25;0;0;0];
    case 'K'
        % Only K receives this exact map, with current h and rho supplied by
        % the plant driver. This is never an adaptive dictionary.
        model = direct_model(1,1,1,5,@known_features);
        name = 'Known-model reference'; labels = {'d','a','b','h','rho'};
        theta0 = [0;.65;.45;0;0];
    otherwise
        error('study4:Model','Unknown Study 4 model.');
end
end
function [phi,J] = augmented(z)
[phi,J] = polynomial_features(z,[0 0;1 0;0 1;2 0]);
end
function [phi,J] = known_features(z)
x = z(1); u = z(2);
phi = [1;x;u;x^2;sin(2*x)];
J = [0 0;1 0;0 1;2*x 0;2*cos(2*x) 0];
end
