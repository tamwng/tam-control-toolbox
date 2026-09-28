function callback=ejc_study34_callback(root,study,output)
%EJC_STUDY34_CALLBACK Capture the verifier context before a runner path reset.
% This component does not certify a candidate. RUN_EJC's unchanged clean
% candidate gate remains mandatory for production. Saved-output diagnostics
% may invoke this bridge on an explicitly recorded repair snapshot.
ownFile=[mfilename('fullpath') '.m'];
expectedRoot=fileparts(fileparts(fileparts(ownFile)));
assert(strcmp(canonical(root),canonical(expectedRoot)), ...
    'ejc:CallbackCheckout','The callback and runner belong to different checkouts.');
root=canonical(root);study=string(study);
assert(isscalar(study) && any(study==["study3","study4"]), ...
    'ejc:CallbackStudy','Only the existing Study 3/4 binding is supported.');
output=canonical(output);p07=fullfile(root,'studies','p07');
verifier=fullfile(p07,'ejc_study34_verify.m');
gateFile=fullfile(root,'evidence','p07_acceptance','IMPLEMENTATION_GATE.json');
gate=jsondecode(fileread(gateFile));gateHash=sha(gateFile);ownHash=sha(ownFile);
policyFile=fullfile(p07,'p07_acceptance_policy.json');
assert(strcmp(sha(policyFile),gate.policySHA256), ...
    'ejc:CallbackPolicy','Policy bytes differ from the pinned implementation.');
pins=gate.sourceFiles;
names=string({pins.path});
pins=pins(startsWith(names,"studies/p07/") | ...
    names=="studies/"+study+"/"+study+"_verify_results.m");
assert(any(string({pins.path})=="studies/p07/ejc_study34_verify.m") && ...
    any(string({pins.path})=="studies/p07/ejc_study34_extract.m") && ...
    any(string({pins.path})=="studies/p07/ejc_study34_bind.m"), ...
    'ejc:CallbackPins','Required verifier source pins are absent.');
checkPins;
callback=@invoke;

    function report=invoke(source,cfg)
        callerPath=path;callerDirectory=pwd;
        restore=onCleanup(@()restoreCaller(callerPath,callerDirectory));
        assert(strcmp(sha(ownFile),ownHash) && strcmp(sha(gateFile),gateHash), ...
            'ejc:CallbackSource','Callback or source pins changed after capture.');
        checkPins;
        resolved=which('ejc_study34_verify');
        assert(isempty(resolved) || strcmp(canonical(resolved),canonical(verifier)), ...
            'ejc:CallbackResolution','A different checkout/shadow verifier is visible.');
        addpath(p07);
        % Only P07 is missing in the actual study lifecycle. Never add an
        % archive, output tree, recursive source tree or persistent path.
        for pin=reshape(pins,1,[])
            [~,name,extension]=fileparts(pin.path);
            if strcmp(extension,'.m')
                resolved=which(name);
                assert(~isempty(resolved) && ...
                    strcmp(canonical(resolved),canonical(fullfile(root,pin.path))), ...
                    'ejc:CallbackResolution','Wrong or missing candidate function: %s.',name);
            end
        end
        saved=load(fullfile(source,'settings.mat'),'cfg');
        assert(isfield(saved,'cfg') && isequaln(saved.cfg,cfg), ...
            'ejc:CallbackSourceIdentity','Callback configuration differs from its saved source.');
        report=ejc_study34_verify(study,source,cfg,output);
    end
    function checkPins
        assert(strcmp(sha(policyFile),gate.policySHA256), ...
            'ejc:CallbackPolicy','Policy bytes differ from the pinned implementation.');
        for pin=reshape(pins,1,[])
            assert(strcmp(sha(fullfile(root,pin.path)),pin.sha256), ...
                'ejc:CallbackSource','Pinned verifier dependency changed: %s.',pin.path);
        end
    end
end
function value=canonical(value)
value=char(java.io.File(char(value)).getCanonicalPath());
end
function restoreCaller(oldPath,oldDirectory)
cd(oldDirectory);path(oldPath);
end
function hash=sha(file)
fid=fopen(file,'rb');assert(fid>=0,'ejc:CallbackMissingSource','Missing pinned file: %s.',file);
cleanup=onCleanup(@()fclose(fid));digest=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid),digest.update(fread(fid,1024*1024,'*uint8'));end
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end
