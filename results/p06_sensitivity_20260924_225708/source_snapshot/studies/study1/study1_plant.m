function next = study1_plant(x,u)
%STUDY1_PLANT Evaluator-only stationary Plant A, Eqs. (43)-(44).
next = 0.03+0.65*x+0.45*(1+0.35*x).*u;
end
