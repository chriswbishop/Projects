function [CLEAD ULEAD CLAG ULAG]=PEABR_ABR_analysis_adaptcorr(SID, STR, STIME)
%% DESCRIPTION:
%
%   Function designed to calculate corrected amplitudes.  The amplitudes
%   are corrected for monaural adaptation as estimated using the LEADBIN,
%   and LAGBIN inputs.
%
% INPUT:
%
%   SID:    character matrix, each row is a subject ID    
%   STR:    string appended to ABR data (e.g., '_6CH_LERE')
%   STIME:  Stimulus time window in seconds (e.g. [0.005 0.006])
%
% OUTPUT:
%
%   CLEAD:  corrected amplitude estimates of time window relative to lead
%           onset
%   ULEAD:  "uncorrected" " "
%   CLAG:   corrected amplitude estimates of time window relative to lag
%           onset
%   ULAG:   "uncorrected" ""
%
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

% Get estimates for time window for both lead and lag time
[CLEAD ULEAD LL LG]=PEABR_Exp02C_estadaptwav(SID, STR, STIME, false); 
GENERATE_PLOTS(CLEAD, ULEAD, ['Lead Click [' num2str(STIME(1)) ' ' num2str(STIME(2)) '] ms']); 
[CLAG ULAG GL GG]=PEABR_Exp02C_estadaptwav(SID, STR, STIME, true); 
GENERATE_PLOTS(CLAG, ULAG, ['Lag Click [' num2str(STIME(1)) ' ' num2str(STIME(2)) '] ms']); 


end % PEABR_ABR_analysis_adaptcorr

% function [WAVE_CORR APE LEAD LAG]=ESTIMATE_WAVE(SID, STR, STIME, ETFLAG)
% %% DESCRIPTION:
% %
% %   Function estimates a time waveform from which monaural adaptation
% %   estimates have been removed.  This, quite frankly, is a very confusing
% %   bit of code that took me days to wrap my head around.  Let's hope I do
% %   some decent commenting.
% %
% %   INPUT:
% %
% %       SID:    string, subject IDs, each row is a subject ID
% %       STR:    
% %
%     figure;
%     
%     % First, get weights based on Lead-Ape trains
%     BINS=[41 42]; BFLAG=true; N=20;
%     [RPROF W]=PEABR_response_profile(SID, STR, BINS, N, BFLAG);
% 
%     % Second, get the response for all 20 clicks in lead-only trains
%     BINS=1:20; BL=[]; PFLAG=false;
%     [LEAD SNR NOIZE T BLTT]=PEABR_ABR_analysis(SID, STR, BINS, ETFLAG, BL, STIME, PFLAG);
% 
%     % Third, get the response for all 20 clicks in lag-only trains relative to
%     % lead/lag sound onset.
%     BINS=21:40; BL=[]; PFLAG=false;
%     [LAG SNR NOIZE T BLTT]=PEABR_ABR_analysis(SID, STR, BINS, ETFLAG, BL, STIME, PFLAG);
% 
%     % Fourth, create weighted lead only average based on weights
%     % established from suppressed and not suppressed weighting profiles.
%     
%     % LEAD_S is the weighted average of the lead-only clicks using the
%     % "suppressed" weighting profile.
%     %
%     % LEAD_NS is the weighted average of the lead-only clicks using the
%     % "not-suppressed" weighting profile.
%     for s=1:size(SID,1)
%         LEAD_S(:,s)=squeeze(LEAD(1,:,:,s))*squeeze(W(1,:,s))'; % weighted average for suppressed
%         LEAD_NS(:,s)=squeeze(LEAD(1,:,:,s))*squeeze(W(2,:,s))'; % weighted average for not-suppressed
%     end % for s=1:size(SID,1)
% 
%     % Average over time window
%     LEAD_S=mean(LEAD_S);
%     LEAD_NS=mean(LEAD_NS); 
%     
%     % LEAD is the average amplitude of the (weight averaged) lead-only
%     % response following the suppressed and not-suppressed weighting
%     % profiles
%     LEAD=[LEAD_S' LEAD_NS'];
% 
%     % Fifth, do the same for lag averages.
%     %
%     % LAG_S: see LEAD_S above, this is the same ,but for the LAG-only
%     % train.
%     for s=1:size(SID,1)
%         LAG_S(:,s)=squeeze(LAG(1,:,:,s))*squeeze(W(1,:,s))'; % weighted average for suppressed
%         LAG_NS(:,s)=squeeze(LAG(1,:,:,s))*squeeze(W(2,:,s))'; % weighted average for not-suppressed
%     end % for s=1:size(SID,1)
%     
%     % Average over time window
%     LAG_S=mean(LAG_S);
%     LAG_NS=mean(LAG_NS); 
%     
%     % Average amplitude for LAG only train following each weighting profile
%     LAG=[LAG_S' LAG_NS'];
% 
%     % Sixth, get the average response for Lead-Ape(S) and Lead-Ape(NS) at
%     % click wave location
%     %
%     %   APE is the estimated amplitude over the given time window for both
%     %   the lead-ape(S) and lead-ape(NS) responses.
%     BINS=[41 42]; BL=[]; PFLAG=false;
%     [APE SNR NOIZE T BLTT]=PEABR_ABR_analysis(SID, STR, BINS, ETFLAG, BL, STIME, PFLAG);
%     
%     % Average over time window
%     %   Results in an XXX matrix
%     APE=squeeze(mean(APE,2))'; % each row is a subject, first column is suppressed, second is not supprssed
% 
%     % Seventh, compute adaptation corrected responses
%     %   First column is suppressed, second is not-suppressed estimate.
%     %   
%     %   Here's the nuts and bolts of the equation.
%     %
%     %   Corrected Response for S = 
%     %       Lead-APE(S) - (Lead(weighted by S profile) + Lag(weighted
%     %       by S/ profile)); 
%     %
%     %   So, the idea behind this approach is that if we simply compare the
%     %   Lead-Ape(S) and Lead-Ape(NS) amplitudes directly, any differences
%     %   we potentially find could be due to within train adaptation.
%     %   Specifically, Suppressed responses tend to occur later in the train
%     %   and, assuming there is within train adaptation, would presumably
%     %   have a smaller amplitude as a consequence of this adaptation.  
%     %
%     %   This approach allows us to estimate and correct for monaural
%     %   adaptation.  Mathematically, it looks like this
%     %
%     %       (Lead(S) + Lag(S)) - (Lead(NS) + Lag(NS))
%     %
%     %   This gives us an estimate of monaural adaptation as it relates to
%     %   perception.  Then, we compare the amplitude of perceptually
%     %   meaningful measures to this
%     %
%     %       Lead_Ape(S) - Lead_Ape(NS)
%     %
%     %   If this difference is different from the estimated monaural
%     %   adaptation, then we can be more confident in our conclusions that
%     %   any significant difference is not due to monaural adaptation, but
%     %   instead related to binaural adaptation and is highly correlated
%     %   with perceptual outcome.  
%     WAVE_CORR=APE - (LEAD + LAG); 
% 
% end % ESTIMATE_WAVE

function GENERATE_PLOTS(CAPE, UAPE, TITLE_STR)
%% DESCRIPTION:
%
%
%
% INPUT

%% FIND MEAN AND ERRORS

% Raw means and SEM
MCAPE=mean(CAPE); ECAPE=std(CAPE./sqrt(size(CAPE,1))); 
MUAPE=mean(UAPE); EUAPE=std(UAPE)./sqrt(size(UAPE,1));

% Mean differences and SEM of diff
tmp=CAPE(:,1)-CAPE(:,2);
MDC=mean(tmp); EDC=std(tmp)./sqrt(size(tmp,1)); 

tmp=UAPE(:,1) - UAPE(:,2); 
MDU=mean(tmp); EDU=std(tmp)./sqrt(size(tmp,1)); 

%% CONCANTENATE EVERYTHING
M=[ [MUAPE MDU]; [MCAPE MDC]];
E=[ [EUAPE EDU]; [ECAPE EDC]];

%% GENERATE BAR PLOT
barweb(M, E, 1, {'No Corr.', 'Corr'}, TITLE_STR, [], 'Amplitude (microVolt)');
ylim([min(min(M-E))-.05 max(max(M+E))+0.05]);
legend('S', 'NS', 'S-NS');
end % GENERATE_PLOTS