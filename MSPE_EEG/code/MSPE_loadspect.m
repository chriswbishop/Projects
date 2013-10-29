function [ApeSERSP ApeSITC ApeSPOWBASE ApeNSERSP ApeNSITC ApeNSPOWBASE...
    ApeVSERSP ApeVSITC ApeVSPOWBASE ApeVNSERSP ApeVNSITC ApeVNSPOWBASE ...
    ApeSTRLS ApeNSTRLS ApeVSTRLS ApeVNSTRLS...
    ApeSITCz ApeNSITCz ApeVSITCz ApeVNSITCz...
    ApeSITCk ApeNSITCk ApeVSITCk ApeVNSITCk]=MSPE_loadspect(SID, EXPID)
    
%     AERSP AITC AITCz ATRLS]=MSPE_loadspect(SID, EXPID)
%     VERSP VITC VITCz VTRLS]=MSPE_loadspect(SID, EXPID)
%% DESCRIPTION
%
% INPUT:
%
%   SID:
%   EXPID:
%   
% OUTPUT:
%   
%   o..m..g
%
% Bishop, Christopher W.
%   UC Davis 
%   Miller Lab 2011
% cwbishop@ucdavis.edu

str='-TimeFreq (CLEAN; REB)'; 
for s=1:size(SID,1)
    load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-Ape(S)' str '.mat']), 'ersp', 'powbase', 'itc', 'trls', 'times');
    ApeSERSP(:,:,:,s)=ersp;
    ApeSITC(:,:,:,s)=abs(itc);
    ApeSPOWBASE(:,:,:,s)=powbase;
%     ApeSERSPz(:,:,:,s)=trls .* (ersp.^2); %% really? how does that make sense?
    ApeSITCz(:,:,:,s)=trls .* (abs(itc).^2);        
    ApeSTRLS(s)=trls;
    
    load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-Ape(NS)' str '.mat']), 'ersp', 'powbase', 'itc', 'trls');
    ApeNSERSP(:,:,:,s)=ersp;
    ApeNSITC(:,:,:,s)=abs(itc);
    ApeNSPOWBASE(:,:,:,s)=powbase;
%     ApeNSERSPz(:,:,:,s)=trls .* (ersp.^2);
    ApeNSITCz(:,:,:,s)=trls .* (abs(itc).^2);
    ApeNSTRLS(s)=trls; 
    
    load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-ApeVlead(S)' str '.mat']), 'ersp', 'powbase', 'itc', 'trls');
    ApeVSERSP(:,:,:,s)=ersp;
    ApeVSITC(:,:,:,s)=abs(itc);
    ApeVSPOWBASE(:,:,:,s)=powbase;
%     ApeVSERSPz(:,:,:,s)=trls .* (ersp.^2);
    ApeVSITCz(:,:,:,s)=trls .* (abs(itc).^2);
    ApeVSTRLS(s)=trls; 
    
    load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-ApeVlead(NS)' str '.mat']), 'ersp', 'powbase', 'itc', 'trls');
    ApeVNSERSP(:,:,:,s)=ersp;
    ApeVNSITC(:,:,:,s)=abs(itc);
    ApeVNSPOWBASE(:,:,:,s)=powbase;
%     ApeVNSERSPz(:,:,:,s)=trls .* (ersp.^2);
    ApeVNSITCz(:,:,:,s)=trls .* (abs(itc).^2);
    ApeVNSTRLS(s)=trls;
    
%     load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-A' str '.mat']), 'ersp', 'powbase', 'itc', 'trls');
%     AERSP(:,:,:,s)=ersp;
%     AITC(:,:,:,s)=abs(itc);
%     APOWBASE(:,:,:,s)=powbase;
% %     AERSPz(:,:,:,s)=trls .* (ersp.^2);
%     AITCz(:,:,:,s)=trls .* (abs(itc).^2);
%     ATRLS(s)=trls;
    
%     load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-Double' str '.mat']), 'ersp', 'powbase', 'itc', 'trls');
%     DERSP(:,:,:,s)=ersp;
%     DITC(:,:,:,s)=itc;
%     DPOWBASE(:,:,:,s)=powbase;
%     DERSPz(:,:,:,s)=trls .* (ersp.^2);
%     DITCz(:,:,:,s)=trls .* (abs(itc).^2);
%     DTRLS(s)=trls;
    
%     load(fullfile(['../' EXPID], deblank(SID(s,:)), 'analysis', [deblank(SID(s,:)) '-V' str '.mat']), 'ersp', 'powbase', 'itc', 'trls');
%     VERSP(:,:,:,s)=ersp;
%     VITC(:,:,:,s)=itc;
%     VPOWBASE(:,:,:,s)=powbase;
%     VERSPz(:,:,:,s)=trls .* (ersp.^2);
%     VITCz(:,:,:,s)=trls .* (abs(itc).^2);
%     VTRLS(s)=trls;
end % s

%% KOLEV CORRECTED DATA
for i=1:size(ApeSITC,3)
    ApeSITCk(:,:,i,:)=MSPE_kolev(squeeze(ApeSITC(:,:,i,:)), times);
    
    ApeNSITCk(:,:,i,:)=MSPE_kolev(squeeze(ApeNSITC(:,:,i,:)), times);
    
    ApeVSITCk(:,:,i,:)=MSPE_kolev(squeeze(ApeVSITC(:,:,i,:)), times);
    
    ApeVNSITCk(:,:,i,:)=MSPE_kolev(squeeze(ApeVNSITC(:,:,i,:)), times);
end % i
%% PLOT OUT RAW DATA
% This is some hacked code, but it helps get a good visualization of the
% data quickly. Definitely needs to be gone through carefully. 

