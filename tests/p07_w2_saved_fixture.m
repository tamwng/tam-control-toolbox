function varargout=p07_w2_saved_fixture(action,varargin)
%P07_W2_SAVED_FIXTURE Test-only, read-only saved-record overlay.
% The unchanged strict verifiers read a virtual scratch namespace. Unchanged
% files are read from their original locations; result structs are copied in
% memory and ONLY gramCondition is replaced by the just-extracted native
% condition. No source/reference file is written or linked. A requested fault
% changes one finite scalar in that in-memory copy, after a positive run.
persistent state
switch action
 case 'start'
  assert(isempty(state),'test:OverlayActive');
  state=varargin{1};state.loader=@load;state.lister=@dir;
  state.mode='positive';state.fault=struct;state.events=struct([]);
  state.contexts=containers.Map('KeyType','char','ValueType','any');
  for file=state.extracted.contexts.'
   z=state.loader(file,'context');c=z.context;
   assert(strcmp(c.sourceSHA256,ejc_file_sha256(c.sourceFile)),'test:OverlaySource');
   state.contexts(char(c.case+".mat"))=c;
  end
 case 'mode'
  state.mode=varargin{1};state.events=struct([]);
  if numel(varargin)>1,state.fault=varargin{2};else,state.fault=struct;end
 case 'load'
  file=varargin{1};[mapped,relative,inside]=map(file,state);
  if ~inside,[varargout{1:nargout}]=state.loader(varargin{:});return;end
  z=state.loader(mapped,varargin{2:end});
  if startsWith(relative,['runs' filesep]) && isfield(z,'result')
   [~,name,ext]=fileparts(relative);key=[name ext];r=z.result;
   if isKey(state.contexts,key)
    c=state.contexts(key);
    assert(strcmp(c.sourceSHA256,ejc_file_sha256(mapped)),'test:OverlaySource');
    assert(isequal(c.indices,2:r.nSteps),'test:OverlayCoverage');
    original=r.gramCondition;r.gramCondition(c.indices)=c.conditions;
    assert(isequaln(rmfield(r,'gramCondition'),rmfield(z.result,'gramCondition')),'test:OverlayMutation');
    if strcmp(state.mode,'fault') && strcmp(key,state.fault.case)
     j=state.fault.index;assert(isfinite(r.gramCondition(j)) && r.gramCondition(j)>0,'test:FaultControl');
     native=r.gramCondition(j);r.gramCondition(j)=2*native;
     state.events=[state.events;struct('case',key,'index',j,'source',string(mapped), ...
      'sourceSHA256',c.sourceSHA256,'historical',original(j),'nativePositive',native, ...
      'injected',r.gramCondition(j),'nativePositiveHex',num2hex(native),'injectedHex',num2hex(r.gramCondition(j)))];
    end
    z.result=r;
   end
  end
  varargout{1}=z;
 case 'dir'
  [mapped,~,inside]=map(varargin{1},state);
  if inside,varargout{1}=state.lister(mapped);else,varargout{1}=state.lister(varargin{:});end
 case 'events'
  varargout{1}=state.events;
 case 'stop'
  state=[];
 otherwise
  error('test:OverlayAction','Unknown test-only fixture operation.');
end
end
function [mapped,relative,inside]=map(file,state)
file=char(file);prefix=[state.virtualRoot filesep];inside=startsWith(file,prefix);
mapped=file;relative='';if ~inside,return;end
relative=file(numel(prefix)+1:end);
assert(~contains(relative,'..') && ~contains(relative,':'),'test:OverlayPath');
mapped=fullfile(state.source,relative);
assert(~startsWith(string(state.virtualRoot),string(state.source)+filesep),'test:OverlayPath');
end
