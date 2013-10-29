function [results]=MSPE_fMRI_Exp01C_GLM(args)
%% DESCRIPTION:
%
%   Function to build DURATION and ONSET vectors from logfiles. At the time
%   of writing, 
%
% INPUT:
%
%   args.
%       P:  path to mat-file with saved data or list of log files (each row
%           is a path to the log files)
%       
%
% OUTPUT:
%
%   results:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2012
%   cwbishop@ucdavis.edu


%% THESE WILL BE SAVED TO A MAT-FILE
names={};


% LOAD BEHAVIORAL DATA
try 
    load(args.P, 'COND', 'ALAG', 'COND', 'NRESP', 'PCOUNT', 'P', 'S', 'M');
catch
    [LAC RAC ALAG VCOD COND NRESP SRESP NRT SRT STIME X Y VOFF PCOUNT PTOTAL S M]=MSPE_fMRI_read(args.P);
end % try, catch

%% FIRST BREAK UP BY CONDITION
names={'Ape(L)', 'A(L)', 'D(L)'};
C=[2 7 24];
SESS=unique(S);
for s=1:length(SESS)
    onsets={};
    durations={}; 
    for i=1:length(C)
        onsets{1,i}=PCOUNT(find(COND==C(i) & S==SESS(s)))-1; % subtract 1
        durations{1,i}=zeros(size(onsets{1,i}));
    end % i
    %% Save session specific mat files
    save([args.OUT '_Sess' num2str(SESS(s)) '.mat'], 'names', 'onsets', 'durations'); 
end

%% SAVE MAT FILE FOR EACH SESSION
% SESS=unique(S);
% for i=1:length(S);
%     
% save(args.OUT, 'names', 'onsets', 'durations'); 

results='done'; 