function cfg = study6_settings
%STUDY6_SETTINGS Derived pilot diagnostics; no new control or noise campaign.
cfg.status = 'Derived pilot analysis; not independent confirmation';
cfg.sources = {'study1_candidate_20260917','study2_pilot_20260918', ...
    'study3_pilot_20260918','study4_pilot_20260922','study5_pilot_20260922'};
cfg.Ts = .1; cfg.fitSteps = [25 50 100 200]; cfg.horizons = [1 2 5 10 20];
cfg.anchors = 20:20:580; cfg.onlineTimes = [49.9 55 59.9 95];
cfg.onlineIndices = round(cfg.onlineTimes/cfg.Ts);
cfg.changeTimes = [49.5 49.9]; cfg.changeIndices = [495 499];
cfg.tolerance = 1e-11; % Existing Studies 1/2 forecast identity tolerance.
cfg.primaryTrials = 0; % Both existing Study 1 clean evaluation records, separately.
cfg.changeSelection = 'Both input modes; nine saved noise-free Study 3 cases only (user selection).';
cfg.measurementSelection = 'Existing Study 1 audit files/queries only (user selection); source labels retained.';
cfg.indexing = 'Mathematical k is MATLAB column k+1; input at that column generates x(k+1).';
cfg.forecastPolicy = 'Fixed estimates and affine coefficients; no RLS, QP, feedback, relinearization or future noise.';
end
