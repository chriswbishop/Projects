function results=MSPE_GROUP_ERP(args)
%% DESCRIPTION
%
% INPUT:
%
%   args
%       .sid:   
%       .studyDir:
%       .outDir:
%
% OUTPUT:
%
% Bishop, Chris Miller Lab 2010

global ALLERP;
ALLERP=[];
for s=1:size(args.sid,1)
    SID=deblank(args.sid(s,:));
    load(fullfile(args.studyDir, SID, 'analysis', [SID args.ERPext]), 'ERP');
    if s==1
        ALLERP=ERP;
    else
        ALLERP(s)=ERP;
    end % s
end % 

ERP = pop_gaverager(ALLERP,1:size(args.sid,1), args.iswavg, 1);

ERP.erpname=args.ERPName;
save(args.outDir, 'ERP'); 

results='done';