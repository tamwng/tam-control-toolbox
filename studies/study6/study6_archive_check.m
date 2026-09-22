function difference = study6_archive_check(out,archived,snapshot)
%STUDY6_ARCHIVE_CHECK Reuse compatible terminal results as independent checks.
if nargin < 3, snapshot = 1:size(out.mappedTheta,3); end
difference = 0;
for field = ["modelError","freezingError","totalError","crossTerm"]
    if ~isfield(archived,field), continue; end
    current = out.(field)(:,out.horizons+1,:,snapshot); previous = archived.(field);
    assert(isequal(size(current),size(previous)) && isequal(isfinite(current),isfinite(previous)), ...
        'study6:ArchiveShape','Archive and derived query validity/shape must agree.');
    mask = isfinite(previous);
    if any(mask,'all')
        delta = max(abs(current(mask)-previous(mask))); scale = max(1,max(abs(previous(mask))));
        assert(delta <= 1e-11*scale,'study6:ArchiveMismatch','Derived paths disagree with existing terminal forecasts.');
        difference = max(difference,delta);
    end
end
end
