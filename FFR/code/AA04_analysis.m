function AA04_analysis(varargin)
%% DESCRIPTION:
%   
%   Analysis function for AA04. CWB was doing most of this at the command
%   line, but found it a bit too cumbersome in this particular case, so
%   decided to write up a generalized analysis function.
%
% INPUT:
%
%   SID:    cell array of subject IDs
%   'sid':          cell array, subject IDs (e.g., {{'KM', 'CJB'}})
%   'erpext':       cell array, ERP extension (e.g., '-cABR_CzLE') 
%   'studydir':     full path to study directory
%   'expid':        experiment ID (e.g., 'AA04')
%   'nsem':         integer, SEM error bars to plot
%   'tnoise':       time window for temporal noise estimates (e.g., [-Inf
%                   0]);
%   'tsig':         time window for temporal signal estimate (e.g., [0
%                   Inf])
%   'frange':       frequency range for plotting purposes in AA_FFT and
%                   AA_phasecoher.m.
%   'tfreqs':       target frequencies for AA_FFT.
%   'chans':        which channels to analyze for functions that work for
%                   multiple channels (e.g., AA_phasecoher). NOTE: not all
%                   functions actually work with multiple channels, so this
%                   input arg might be ignored altogether for some function
%                   calls. OR, functions might collapse over channels
%                   (AA_tSNR) in their routines. Don't over interpret the
%                   findings or assign the findings to the incorrect
%                   channel. 
%   'plotphase':    bool, flag to plot phase (true to plot)
%   'fnoise':       frequency noise range. See AA_FFT for details. 
%   'bins':         integer array, bins to include in analysis.
%   'plev':         integer, plot level (e.g., 1)
%
%   Analysis types:
%
%   'fft':          bool, run AA_FFT (amplitude and phase analysis). 
%   'plv':          bool, run AA_phasecoher (PLV estimation).
%   'tsnr':         bool, run AA_tSNR (temporal SNR estimation)   
%   'twave':        bool, plot time waveforms
%
% OUTPUT:
%
%   Figures galore.
%
%   Maybe other return values from other functions.
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% CONVERT INPUT OPTIONS TO STRUCTURE
%   Trying a new way of passing arguments around.
p=struct(varargin{:}); 

%% SET DEFAULT VALUES FOR INPUT ARGS
%   Might be useful to set some optional input args here to reduce
%   commandline work. CWB is always scared of defaults, though.

%% ANALYSES FOR EACH ERP
%   These are the analyses that must be carried out independently for each
%   ERP extension
for e=1:length(p.erpext)
    
    % Initialize variables
    ERPF=cell(length(p.sid),1); 
    
    % Compile file list
    for s=1:length(p.sid)        
        ERPF{s}=fullfile(p.studydir, p.expid, p.sid{s}, 'analysis', [p.sid{s} p.erpext{e} '.mat']);         
    end % s=1:length(p.sid)
    
    %% TIME WAVEFORM PLOTS
    %   Time waveform plots with error bars (if specified).
    
    %% FREQUENCY DECOMPOSITION
        %   FFT decomposition on data (use AA_FFT.m)
    if p.fft        
    
        % Which figure are we on before the call?
        %   If no figures are open, calling gcf creates a figure. So we
        %   only want to use gcf if no figures exist.
        %
        %   Gleaned the following findobj command from 
        %   http://stackoverflow.com/questions/470851/how-to-check-if-a-figure-is-opened-and-how-to-close-it
        if ~isempty(findobj('type', 'figure'))
            cfig=gcf+1; 
        else
            cfig=1;
        end % if 
    
        % Call AA_FFT
        %   For details on analysis, please see help AA_FFT
        AA_FFT(ERPF, p.frange, p.nsem, p.bins, p.plev, p.tfreqs, p.plotphase, p.fnoise); 
    
        % Append ERP Extension name to figure title 
        appendext(cfig, p.erpext{e}); 
        
    end % if p.fft
    
    %% PHASE LOCKING VALUE (PLV)
    %   Plot out PLV for each frequency and bin (use AA_phasecoher.m).
    if p.plv
    
        if ~isempty(findobj('type', 'figure'))
            cfig=gcf+1; 
        else
            cfig=1;
        end % if 
    
        % Call AA_phasecoher
        %   Estimates phase coherence
        AA_phasecoher(ERPF, p.frange, p.chans, p.nsem, p.bins, p.plev, p.tfreqs); 
    
        % Append ERP Extension name to figure title 
        appendext(cfig, p.erpext{e}); 
        
    end % if p.plv
    
    %% XXX PERIODICITY ANALYSIS XXX
    %   An analysis to determine how well-represented the periodic aspects of
    %   the speech stimuli are represented. Nothing written to do this yet. 
    %
    %   For potential analytical options, see the article below. 
    %
    %   Marmel, F., et al. (2013). J Assoc Res Otolaryngol 14(5): 757-766.

end % for e=1:length(p.erpext)

%% ANALYSES ACROSS ALL ERP EXTENSIONS
%   These are analyses that directly compare data across multiple ERP
%   extensions

%% TEMPORAL SIGNAL TO NOISE RATIO
%   Plot out temporal signal to noise ratio for all ERPEXTs. Use AA_tSNR.m)
if p.tsnr
    
    % Call AA_tSNR
    %   Basic temporal SNR calculations. For more information, please see
    %   help AA_tSNR
    AA_tSNR(p.sid, p.erpext, p.studydir, p.expid, p.nsem, p.tnoise, p.tsig, p.bins, p.plev);
    
end % if p.tsnr
end %% AA04_analysis

function appendext(sfig, ext)
%% DESCRIPTION:
%
%   Function to append ERP extension names to figure titles.
%
% INPUT:
%
%   sfig:   integer, starting figure.
%   ext:    string, extension name
%
% OUTPUT:
%
%   Appended figure titles to figures
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% FIGURE RANGE
%   Figure range to append extension name to.
fr=sfig : gcf;

%% 
for i=fr
    % Change to appropriate figure
    figure(i);
    % Append ERPEXT to figure title
    %   Must append to all figures 
    htitl=get(gca,'Title'); % handle to title
    ntitl=get(htitl, 'String');
    ntitl=[ntitl ' | ' ext];
    set(htitl, 'Interpreter', 'none');  % remove interpreter from title
    set(htitl, 'String', ntitl); 
end % for i=fr

end % appendext