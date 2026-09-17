function columnScale = regression_scaling(PhiSamples, rowScale)
%REGRESSION_SCALING Fixed RMS column scales after fixed row scaling, Eq. (A.2).
% PhiSamples is nb-by-ntheta-by-nsamples. Each scale is the RMS over all
% entries in that column (rows and samples). rowScale multiplies rows and
% must also multiply the measured response. Zero columns are rejected.
validateattributes(PhiSamples, {'double'}, {'nonempty', 'real', 'finite'});
if ndims(PhiSamples) > 3
    error('regression_scaling:SampleDimensions', 'Calibration data must have at most three dimensions.');
end
validateattributes(rowScale, {'double'}, {'nonempty', 'vector', 'real', 'finite', 'positive'});
if ~isscalar(rowScale) && numel(rowScale) ~= size(PhiSamples, 1)
    error('regression_scaling:RowScaleSize', 'Row scaling must match the regressor rows.');
end
scaled = rowScale(:) .* PhiSamples;
columnScale = reshape(sqrt(mean(scaled.^2, [1 3])), [], 1);
if any(~isfinite(columnScale)) || any(columnScale <= 0)
    error('regression_scaling:InvalidColumnScale', ...
        'Calibration must give a positive finite RMS for every independent parameter.');
end
end
