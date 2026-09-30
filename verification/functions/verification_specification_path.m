function file = verification_specification_path(identity)
%VERIFICATION_SPECIFICATION_PATH Locate a frozen specification by original identity.
% The policy retains its original path strings and content hashes.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
switch string(identity)
    case "evidence/p07_acceptance/maximum_locator/CLAIM_SCOPE.json"
        name='maximum_scope.json';
    case "evidence/p07_acceptance/maximum_locator/SOURCE_DEFINITIONS.json"
        name='maximum_definitions.json';
    otherwise
        error('study:SpecificationIdentity','Unknown numerical specification identity: %s.',identity);
end
file=fullfile(root,'verification','specification',name);
assert(isfile(file),'study:MissingSpecification','Required numerical specification is missing: %s.',name);
end
