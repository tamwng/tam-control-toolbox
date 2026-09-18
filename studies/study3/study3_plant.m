function next = study3_plant(x,u,b,w)
%STUDY3_PLANT Plant A with current gain and process disturbance, Eq. (43).
% Nominal offset and state-input coupling remain present in this study.
next = 0.03+0.65*x+b.*(1+0.35*x).*u+w;
end
