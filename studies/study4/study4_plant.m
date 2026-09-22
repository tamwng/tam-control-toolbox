function next = study4_plant(x,u,h,rho)
%STUDY4_PLANT Linear start: no constant offset and no x*u contribution.
next = .65*x+.45*u+h.*x.^2+rho.*sin(2*x);
end
