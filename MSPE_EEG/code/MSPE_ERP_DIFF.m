function results=MSPE_ERP_DIFF(args)
%% DESCRIPTION:
%
% INPUT:
%
% OUTPUT:
%
%

% Load first ERP
ERP1=load(args.ERP1, 'ERP');
ERP=ERP1.ERP; 

% Load second ERP
ERP2=load(args.ERP2, 'ERP');

% Calc difference
ERP.bindata=ERP1.ERP.bindata-ERP2.ERP.bindata; 

% Rename
ERP.erpname=args.ERPName;

% Save
save(args.outDir, 'ERP'); 

results='done'; 