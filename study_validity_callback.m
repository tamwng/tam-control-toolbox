function callback = study_validity_callback(study,output)
%STUDY_VALIDITY_CALLBACK Capture source-bound own-record verification.
[context,root]=study_context; %#ok<ASGLU>
proof=verify_source_relationship;
assert(any(string(study)==["study3","study4"]),'study:Selection','Expected Study 3 or 4.');
expected=fullfile(root,'studies','p07','ejc_study34_verify.m');
callback=@invoke;
    function report=invoke(source,cfg)
        [restore,actualRoot]=study_context; %#ok<ASGLU>
        assert(strcmp(root,actualRoot),'study:CallbackRoot','Callback source tree changed.');
        current=verify_source_relationship;
        assert(strcmp(current.relationshipSHA256,proof.relationshipSHA256), ...
            'study:CallbackSource','Source changed after callback capture.');
        assert(strcmpi(which('ejc_study34_verify'),expected), ...
            'study:CallbackResolution','Unexpected saved-data verifier.');
        saved=load(fullfile(source,'settings.mat'),'cfg');
        assert(isequaln(saved.cfg,cfg),'study:CallbackSettings','Saved settings differ.');
        report=ejc_study34_verify(study,source,cfg,output);
    end
end
