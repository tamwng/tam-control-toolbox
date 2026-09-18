function next = study2_plant(x,u)
%STUDY2_PLANT Noise-free sampled Plant B, Eq. (47), in stated units.
% This recurrence defines the plant directly; no numerical integration is used.
next = 0.03+0.65*x+0.40*sin(u);
end
