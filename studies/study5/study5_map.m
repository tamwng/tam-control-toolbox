function theta = study5_map(id,raw)
%STUDY5_MAP Prediction-only mapping, never an RLS state replacement.
theta = raw;
if strcmp(id,'I'), theta = min(max(raw,[.2;0]),[3;2]); end
end
