function [h,rho] = study4_schedule(k,scenario,cfg)
%STUDY4_SCHEDULE Evaluator/plant schedule, never passed to adaptive control.
h = zeros(size(k)); rho = zeros(size(k));
switch char(scenario)
    case 'no_change'
    case 'represented'
        h(k >= cfg.eventIndex) = cfg.hStar;
    case 'unrepresented'
        rho(k >= cfg.eventIndex) = cfg.rhoStar;
    otherwise
        error('study4:Scenario','Unknown Study 4 scenario.');
end
end
