function [WAV_CORR APE LEAD LAG WAV_CORR_WAV LEAD_S LEAD_S_WAV LEAD_NS LEAD_NS_WAV LAG_S LAG_S_WAV LAG_NS LAG_NS_WAV APE_WAV]=PEABR_Exp02C_estadaptwav(SID, STR, STIME, ETFLAG, PREFIX)
%% DESCRIPTION:
%
%   Function estimates a time waveform from which monaural adaptation
%   estimates have been removed.  This, quite frankly, is a very confusing
%   bit of code that took me days to wrap my head around.  Let's hope I do
%   some decent commenting.
%
%   I borrowed a lot of this code from PEABR_analysis_adaptcorr's
%   ESTIMATE_WAV function.
%
%   This code is specific to PEABR_Exp02C. Some things are hardcoded, so be
%   careful if you're trying to harness this to do something new. 
%
%   INPUT:
%
%       SID:    string, subject IDs, each row is a subject ID
%       STR:    
%

if ~exist('PREFIX', 'var') || isempty(PREFIX), PREFIX='_ABR'; end

    % First, get weights based on Lead-Ape trains
    BINS=[41 42]; BFLAG=true; N=20;
    [RPROF W]=PEABR_response_profile(SID, STR, BINS, N, BFLAG);

    % Second, get the response for all 20 clicks in lead-only trains
    BINS=1:20; BL=[]; PFLAG=false;
    [LEAD SNR NOIZE T BLTT]=PEABR_ABR_analysis(SID, STR, BINS, ETFLAG, BL, STIME, PFLAG, PREFIX);

    % Third, get the response for all 20 clicks in lag-only trains relative to
    % lead/lag sound onset.
    BINS=21:40; BL=[]; PFLAG=false;
    [LAG SNR NOIZE T BLTT]=PEABR_ABR_analysis(SID, STR, BINS, ETFLAG, BL, STIME, PFLAG, PREFIX);

    % Fourth, create weighted lead only average based on weights
    % established from suppressed and not suppressed weighting profiles.
    
    % LEAD_S is the weighted average of the lead-only clicks using the
    % "suppressed" weighting profile.
    %
    % LEAD_NS is the weighted average of the lead-only clicks using the
    % "not-suppressed" weighting profile.
    for s=1:size(SID,1)
        LEAD_S_WAV(:,s)=squeeze(LEAD(1,:,:,s))*squeeze(W(1,:,s))'; % weighted average for suppressed
        LEAD_NS_WAV(:,s)=squeeze(LEAD(1,:,:,s))*squeeze(W(2,:,s))'; % weighted average for not-suppressed
    end % for s=1:size(SID,1)

    % Average over time window
    LEAD_S=mean(LEAD_S_WAV);
    LEAD_NS=mean(LEAD_NS_WAV); 
    
    % LEAD is the average amplitude of the (weight averaged) lead-only
    % response following the suppressed and not-suppressed weighting
    % profiles
    LEAD=[LEAD_S' LEAD_NS'];
    LEAD_WAV(:,1,:)=LEAD_S_WAV; 
    LEAD_WAV(:,2,:)=LEAD_NS_WAV;
    
    % Fifth, do the same for lag averages.
    %
    % LAG_S: see LEAD_S above, this is the same ,but for the LAG-only
    % train.
    for s=1:size(SID,1)
        LAG_S_WAV(:,s)=squeeze(LAG(1,:,:,s))*squeeze(W(1,:,s))'; % weighted average for suppressed
        LAG_NS_WAV(:,s)=squeeze(LAG(1,:,:,s))*squeeze(W(2,:,s))'; % weighted average for not-suppressed
    end % for s=1:size(SID,1)
    
    % Average over time window
    LAG_S=mean(LAG_S_WAV);
    LAG_NS=mean(LAG_NS_WAV); 
    
    % Average amplitude for LAG only train following each weighting profile
    LAG=[LAG_S' LAG_NS'];
    LAG_WAV(:,1,:)=LAG_S_WAV;
    LAG_WAV(:,2,:)=LAG_NS_WAV;
    
    % Sixth, get the average response for Lead-Ape(S) and Lead-Ape(NS) at
    % click wave location
    %
    %   APE is the estimated amplitude over the given time window for both
    %   the lead-ape(S) and lead-ape(NS) responses.
    BINS=[41 42]; BL=[]; PFLAG=false;
    [APE_WAV SNR NOIZE T BLTT]=PEABR_ABR_analysis(SID, STR, BINS, ETFLAG, BL, STIME, PFLAG, PREFIX);
    
    % Average over time window
    %   Results in an XXX matrix
    APE=squeeze(mean(APE_WAV,2))'; % Average over time bins
    APE_WAV=squeeze(APE_WAV); 

    % Seventh, compute adaptation corrected responses
    %   First column is suppressed, second is not-suppressed estimate.
    %   
    %   Here's the nuts and bolts of the equation.
    %
    %   Corrected Response for S = 
    %       Lead-APE(S) - (Lead(weighted by S profile) + Lag(weighted
    %       by S/ profile)); 
    %
    %   So, the idea behind this approach is that if we simply compare the
    %   Lead-Ape(S) and Lead-Ape(NS) amplitudes directly, any differences
    %   we potentially find could be due to within train adaptation.
    %   Specifically, Suppressed responses tend to occur later in the train
    %   and, assuming there is within train adaptation, would presumably
    %   have a smaller amplitude as a consequence of this adaptation.  
    %
    %   This approach allows us to estimate and correct for monaural
    %   adaptation.  Mathematically, it looks like this
    %
    %       (Lead(S) + Lag(S)) - (Lead(NS) + Lag(NS))
    %
    %   This gives us an estimate of monaural adaptation as it relates to
    %   perception.  Then, we compare the amplitude of perceptually
    %   meaningful measures to this
    %
    %       Lead_Ape(S) - Lead_Ape(NS)
    %
    %   If this difference is different from the estimated monaural
    %   adaptation, then we can be more confident in our conclusions that
    %   any significant difference is not due to monaural adaptation, but
    %   instead related to binaural adaptation and is highly correlated
    %   with perceptual outcome.  
    WAV_CORR=APE - (LEAD + LAG); 
    WAV_CORR_WAV = APE_WAV - (LEAD_WAV + LAG_WAV);
end % ESTIMATE_WAVE