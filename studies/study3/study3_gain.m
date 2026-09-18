function b = study3_gain(k,scenario,Ts)
%STUDY3_GAIN Evaluator-only current gain at sample k, Eqs. (50)-(51).
% b(k) generates x(k+1). The drift still has nominal gain at exactly 50 s.
validateattributes(k,{'double'},{'real','finite','integer','nonnegative'});
validateattributes(Ts,{'double'},{'scalar','real','finite','positive'});
t = k*Ts;
switch char(scenario)
    case 'abrupt'
        b = 0.45-0.15*(t >= 50);
    case 'drift'
        b = 0.45-0.15*min(1,max(0,(t-50)/40));
    otherwise
        error('study3:UnknownScenario','Unknown gain scenario: %s.',char(scenario));
end
end
