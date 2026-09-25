function sources = ejc_reference_sources
%EJC_REFERENCE_SOURCES Immutable historical records; these are inputs only.
root = fileparts(mfilename('fullpath'));
names = {'study1_candidate_20260917','study2_pilot_20260918', ...
    'study3_pilot_20260918','study4_pilot_20260922','study5_pilot_20260922', ...
    'study6_pilot_20260922','p06_sensitivity_20260924_225708'};
keys = {'study1','study2','study3','study4','study5','study6','p06'};
sources = struct;
for j = 1:numel(keys), sources.(keys{j}) = fullfile(root,'results',names{j}); end
end
