function [R, P]=AA_tSNR(SID, ERPEXT, STUDYDIR, EXPID, NSEM, NOISE, SIG, BINS, PLEV)
%% DESCRIPTION:
%
%   Function to calculate the temporal signal to noise ratio between two
%   portions of a signal. Inputs are a bit cumbersome, but allow for easy
%   visualization and comparison across different ERP files (e.g., when
%   comparing SNR levels across various referencing schemes, as CWB was
%   doing when he wrote this function). 
%
% INPUT:
%
%   ERPF:   cell, each element is the full path to an ERP file
%   NSEM:   integer, number of SEMs to include in error bars (default=0)
%   BINS:   integer index, BINS to include in the analysis
%   NOISE:  2x1 or 1x2 double array defining the time range (in sec) of the
%           noise estimation window. (default = [-Inf 0])
%   SIG:    2x1 or 1x2 double array defining the time range (in sec) of the
%           signal estimation window. (default = [0 Inf])
%   PLEV:   plot level setting (1=just group, 2=group and subject data;
%           default=1)
%   NOPER:  Not sure what the format will be yet, but this should allow the
%           user to specify the function to estimate noise and signal
%           levels. Perhaps a function handle?
%
% OUTPUT:
%
%   R:
%   P:
%  
%   Lots of figures. Figures should be self explanatory. 
%
% Christopher W. Bishop
%   University of Washington
%   2/14

%% PARAMETERS
if ~exist('PLEV', 'var') || isempty(PLEV), PLEV=1; end
if ~exist('NSEM', 'var') || isempty(NSEM), NSEM=0; end % 0 by default
if ~exist('NOISE', 'var'), NOISE=[-Inf 0]; end % pre stim period
if ~exist('SIG', 'var'), SIG=[0 Inf]; end % post stim period

%% CONVERT NOISE/SIG FROM SEC TO MSEC
NOISE=NOISE.*1000; 
SIG=SIG.*1000; 

%% REPEAT FOR ALL SUBJECTS
for x=1:length(ERPEXT)
    
    for s=1:length(SID)
        
        %% FILE PARTS OF INPUT FILE
        pathstr=fullfile(STUDYDIR, EXPID, SID{s}, 'analysis');
        name=[SID{s} ERPEXT{x} '.mat'];

        %% LOAD THE ERPFILE
        ERP=pop_loaderp('filename', name, 'filepath', pathstr); 
    
        %% WHICH BINS TO ANALYZE?
        %   Analyze all bins by default
        if ~exist('BINS', 'var') || isempty(BINS)
            BINS=1:size(ERP.bindata,3); 
        end % if ~exist('BINS ...
    
        %% DEFINE OUTPUT VARIABLE(S)
        %   R is a CxBxXxS matrix, where C is the number of channels, B is the
        %   number of BINS, and S is the number of files used (e.g., subjects
        %   included), and X is the number of ERPEXTs defined.
        %   R is the db(rms) estimate of SNR.
        %
        %   P has the same dimensions as R, but is the SNR of the maximum (or
        %   minimal) value in each time series. 
        if x==1 && s==1
            R=nan(size(ERP.bindata,1), length(BINS), length(ERPEXT), length(SID)); 
            P=nan(size(ERP.bindata,1), length(BINS), length(ERPEXT), length(SID)); 
        end % if s==1
    
        %% EXTRACT BIN LABELS
        %   Used for plotting below.    
        LABELS=ERP.bindescr(BINS)'; % bin description labels
    
        %% ESTABLISH TIME MASKS
        %   Add a fraction of a sample to lower bound of SMASK to make sure we
        %   don't have 0 in both pre and post period estimation. Zero ms is
        %   more appropriately called NOISE because stims are just being
        %   presented. 
        %   NOISE=[-Inf, 0]
        %   SIG=[0+1/ERP.srate/2, Inf]
        NMASK=AA_maskdomain(ERP.times, NOISE); % convert NOISE to msec
        SMASK=AA_maskdomain(ERP.times, SIG); 
    
        % Compute SNR using RMS
        R(:,:,x,s)=db(rms(ERP.bindata(:,SMASK,BINS),2)) - db(rms(ERP.bindata(:,NMASK,BINS),2));
        P(:,:,x,s)=db(max(abs(ERP.bindata(:,SMASK,BINS)),[], 2)) - db(max(abs(ERP.bindata(:,NMASK,BINS)),[], 2));
    end % s=1:length(SID)
    
end % for x=1:length(ERPEXT)

%% CREATE DATA PLOTS

% db(RMS)
%   Plot dB(RMS) as a function of ERPEXT. 
AA_tSNR_plot(R, LABELS, ERPEXT, NSEM, BINS, PLEV, 'db(rms)');

% db(peak)
%   Plot dB(peak) as a function of ERPEXT.
AA_tSNR_plot(P, LABELS, ERPEXT, NSEM, BINS, PLEV, 'db(peak)');
end % AA_tSNR

function AA_tSNR_plot(DATA, LABELS, ERPEXT, NSEM, BINS, PLEV, YLAB)
%% DESCRIPTION:
%
%   Plotting function for AA_tSNR. Output variables are of the same
%   dimensions, so the code needed to plot them are damn near identical.
%   CWB decided to write a semi-generic function to do the plots for him,
%   that way all mods are carried through to all plots.
%
% INPUT:
%
%   XXX
%
% OUTPUT:
%
%   Figure with all kinds of cool colors on it. 
%
% Christopher W. Bishop
%   University of Washington
%   2/14

if PLEV>0
    %% GET LINE SPECS
    [colorDef, styleDef]=erplab_linespec(max(BINS));

    figure, hold on

    %% AVERAGE OVER CHANNELS
    %   To simplify, first average over channels.
    tdata=mean(DATA,1);

    %% CALCULATE SEM
    %   Plotted first for ease of legend labeling. Yes, I know I'm looping
    %   through the data twice. Yes, it is inefficient. No, I don't care. 
    U=squeeze(sem(tdata,4)).*NSEM; 

    %% MASSAGE DATA FOR BAR PLOTS
    tdata=squeeze(mean(tdata,4));

    %% CREATE BARPLOT
    barweb(tdata', U', [], ERPEXT, [], [], [], color2colormap({colorDef{BINS}}), 'xy');  
    xlabel('ERP Extension')
    ylabel(YLAB)
    legend(LABELS, 'Location', 'northeast'); 
    title(['N=' num2str(size(DATA,4)) ' | Bins: [' num2str(BINS) '] | ' num2str(size(DATA,1)) ' Chans']);     
end % if PLEV>0

end % AA_tSNR_plot
