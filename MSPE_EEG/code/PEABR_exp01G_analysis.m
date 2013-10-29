function [NRESP D]=PEABR_exp01G_analysis(P)
%% DESCRIPTION:
%
%   Analysis code for Exp01G
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% RETURN VARS
DAPE=[]; % Lead-Ape
GAPE=[]; % Lag-Ape
SAPE=[]; % Silence-Ape
APE=[];  % Ape

%% READ IN DATA
[LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP]=PEABR_read(P);

%% DO WHAT WE NORMALLY DO FOR EXP01F
%   Gives us our normal plots, etc.
[NRESP D]=PEABR_exp01F_analysis(P); 

% Lead-Ape
DAPE=BLOCK(COND, RESP_NSTIM, [100 200]); 

end % PEABR_exp01G_analysis

function [OUT]=BLOCK(COND, RESP_NSTIM, C)
%% DESCRIPTION:
%
%   Function break down responses by location in block of same trial types
%   (identified by condition codes)

% Look for Delay values (encoded in condition codes)
% Initialize output
OUT=[];

% Mask data, only look at response codes we care about
MASK=COND>C(1) & COND<C(2);
COND=COND(MASK);
RESP_NSTIM=RESP_NSTIM(MASK); 
ucond=unique(COND); 

for i=1:length(ucond)
    IND=find(COND==ucond(i)); 
    
    S=[1 find(diff(find(COND==ucond(1)))>1)+1];
    for t=1:length(S)-1
        
    end % t
end % 

end % 
%% LOOK AT SEQUENTIAL TRIALS WITH IDENTICAL CODES

% figure, hold on;
% 
% %% EXTRACT LEAD-APE STIMULI
% %   Codes range from (100-200)
% DAPEind=find(COND>100 & COND<200); 
% 
% D=sort(unique(ALAG(DAPEind))); 
% 
% for d=1:length(D)
%     ind=find(COND>100 & COND<200 & ALAG==D(d));
%     DAPE(d,1)=nanmean(RESP_NSTIM(ind));
% end % 
% 
% % Plot data
% if ~isempty(D), plot(D, DAPE, 'rs-', 'linewidth', 2); end
% 
% %% EXTRACT LAG-APE STIMULI
% %   Codes range from (200 - 300)
% GAPEind=find(COND>200 & COND<300); 
% 
% D=sort(unique(ALAG(GAPEind))); 
% 
% for d=1:length(D)
%     ind=find(COND>200 & COND<300 & ALAG==D(d));
%     GAPE(d,1)=nanmean(RESP_NSTIM(ind)); 
% end % 
% 
% % Plot data
% if ~isempty(D), plot(D, GAPE, 'gd-', 'linewidth', 2); end
% 
% %% EXTRACT SILENCE-APE STIMULI
% %   Codes range from (300 - 400)
% SAPEind=find(COND>300 & COND<400);
% 
% D=sort(unique(ALAG(SAPEind))); 
% 
% for d=1:length(D)
%     ind=find(COND>300 & COND<400 & ALAG==D(d));
%     SAPE(d,1)=nanmean(RESP_NSTIM(ind)); 
% end % 
% 
% % Plot data
% if ~isempty(D), plot(D, SAPE, 'ko-', 'linewidth', 2); end
% 
% %% EXTRACT APE STIMULI
% %   Codes range from (300 - 400)
% APEind=find(COND>400 & COND<500);
% 
% D=sort(unique(ALAG(APEind))); 
% 
% for d=1:length(D)
%     ind=find(COND>400 & COND<500 & ALAG==D(d));
%     APE(d,1)=nanmean(RESP_NSTIM(ind)); 
% end % 
% 
% % Plot data
% if ~isempty(D), plot(D, APE, 'c*-', 'linewidth', 2); end
% 
% % Set legend
% axis([min(ALAG)-0.001 max(ALAG)+0.001 0 max(NSTIM)]);
% legend('Lead-Ape', 'Lag-Ape', 'Silence-Ape', 'Ape', 'location', 'best'); 
% xlabel('Delay (sec)');
% ylabel('Number on Left Side'); 
% 
% %% RETURN VARIABLE
% NRESP=[DAPE GAPE SAPE];