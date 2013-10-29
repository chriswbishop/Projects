function [ApeSERSP ApeNSERSP ApeVSERSP ApeVNSERSP]=MSPE_load_invoked(SID, EXPID)
%% DESCRIPTION
%
% INPUT:
%
% OUTPUT:
%
% Bishop, Christopher W.
%   UC Davis 
%   Miller Lab 2011
% cwbishop@ucdavis.edu

% str='-INDUCED-CLEAN-REB';
str='-INDUCED-MSPE_ERP (CLEAN; REB)';

C=[11 47 46 12 48 49 19 32 56];
for s=1:size(SID,1)
    display(deblank(SID(s,:)));
    load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-Ape(S)' str '.mat']), 'ersp', 'powbase');
    ersp=mean(ersp,4);
    ApeSERSP{s}=ersp;
%     ApeSITC{s}=itc(:,:,C,:);
%     ApeSITC(:,:,:,s)=itc;
%     ApeSPOWBASE{s}=powbase;
%     ApeSERSPz(:,:,:,s)=trls .* (ersp.^2); %% really? how does that make sense?
%     ApeSITCz(:,:,:,s)=trls .* (abs(itc).^2);    
%     ApeSTRLS(s)=trls;
    
    load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-Ape(NS)' str '.mat']), 'ersp', 'powbase');
    ersp=mean(ersp,4); 
    ApeNSERSP{s}=ersp;
%     ApeNSITC{s}=itc(:,:,C,:);
%     ApeNSITC(:,:,:,s)=itc;
%     ApeNSPOWBASE{s}=powbase;
%     ApeNSERSPz(:,:,:,s)=trls .* (ersp.^2);
%     ApeNSITCz(:,:,:,s)=trls .* (abs(itc).^2);
%     ApeNSTRLS(s)=trls; 
    
    load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-ApeVlead(S)' str '.mat']), 'ersp', 'powbase');
    ersp=mean(ersp,4); 
    ApeVSERSP{s}=ersp;
%     ApeVSITC{s}=itc(:,:,C,:);
%     ApeVSITC(:,:,:,s)=itc;
%     ApeVSPOWBASE{s}=powbase;
%     ApeVSERSPz(:,:,:,s)=trls .* (ersp.^2);
%     ApeVSITCz(:,:,:,s)=trls .* (abs(itc).^2);
%     ApeVSTRLS(s)=trls; 
    
    load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-ApeVlead(NS)' str '.mat']), 'ersp', 'powbase');
    ersp=mean(ersp,4); 
    ApeVNSERSP{s}=ersp;
%     ApeVNSITC{s}=itc(:,:,C,:); 
%     ApeVNSITC(:,:,:,s)=itc;
%     ApeVNSPOWBASE{s}=powbase;
%     ApeVNSERSPz(:,:,:,s)=trls .* (ersp.^2);
%     ApeVNSITCz(:,:,:,s)=trls .* (abs(itc).^2);
%     ApeVNSTRLS(s)=trls;
  
end % 