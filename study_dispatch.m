function stages = study_dispatch(study,output,options,operations)
%STUDY_DISPATCH Explicit orchestration; optional operations are synthetic tests.
% Mathematical work remains in the existing study drivers.
if nargin<4
    operations=struct('study1',@run_study1,'study2',@run_study2, ...
        'study3',@run_study3,'study4',@run_study4,'study5',@run_study5, ...
        'study6',@run_study6,'generate',@generate_results,'sensitivity',@run_sensitivity);
end
stages=struct([]);
if study=='all'
    assert(options.ConfirmFull,'study:ExpensiveSelection','Explicit complete selection required.');
    assert(~isfolder(output) && ~isfile(output),'study:ExistingOutput','Use a new output.');
    mkdir(output);parents=struct;
    for j=1:5
        key="study"+j;
        [parents.(key),m]=operations.generate(key,OutputDirectory=fullfile(output,key),Figures=options.Figures);
        stages=[stages;struct('study',key,'output',string(parents.(key)), ...
            'internalValidityPassed',m.internalValidity.passed)]; %#ok<AGROW>
    end
    [path6,m]=operations.generate('study6',OutputDirectory=fullfile(output,'study6'), ...
        Sources=parents,Figures=options.Figures);
    stages=[stages;struct('study',"study6",'output',string(path6),'internalValidityPassed',m.internalValidity.passed)];
    [pathS,m]=operations.sensitivity('all',OutputDirectory=fullfile(output,'p06'),ConfirmFull=true);
    stages=[stages;struct('study',"p06",'output',string(pathS),'internalValidityPassed',m.internalValidity.passed)];
elseif study=='sensitivity'
    [~,stages]=operations.sensitivity('all',OutputDirectory=output,ConfirmFull=options.ConfirmFull);
elseif study=='study6'
    operations.study6(output,Figures=options.Figures,Sources=options.Sources);
elseif any(study=="study"+(1:5))
    operations.(study)(output,Figures=options.Figures);
else
    error('study:Selection','Unknown study selection.');
end
end
