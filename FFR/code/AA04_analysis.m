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
%                   Inf]). Units are milliseconds. 
%   'frange':       frequency range for plotting purposes in AA_FFT and
%                   AA_phasecoher.m. Also used in AA_cpsd_mscohere.m.
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
%   'plev':         integer, plot level (e.g., 1). (Note: this has not been
%                   well tested)
%                       0: no plots generated
%                       1: group plots generated
%                       2: group AND subject level plots created
%   'wsig':         window for wave file signal. (default=[-Inf Inf]); 
%   'xspec_window': window input for AA_cpsd_mscohere.m
%   'xspec_nfft':   number of FFT bins for xspec 
%   'xspec_nover':  number of overlapping samples
%   
%
%   Analysis types:
%
%   'fft':          bool, run AA_FFT (amplitude and phase analysis). 
%   'plv':          bool, run AA_phasecoher (PLV estimation).
%   'tsnr':         bool, run AA_tSNR (temporal SNR estimation)   
%   'twave':        bool, plot time waveforms
%   'xspec':        bool, run AA_cpsd_mscohere to estimate cross spectral
%                   power density and magnitude squared coherence esimates
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
STIM=fullfile('..', 'stims', 'MMBF7.WAV'); 

%% SET BASIC DEFAULTS
%   CWB is trying to avoid setting defaults in teh file, but this is one
%   that I think is reasonbly safe to set. If we don't set an analysis
%   window for the MMBF7.WAV file, then use the whole time series. 
try p.wsig; catch p.wsig=[-Inf Inf]; end 
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
    %   Also load ERPs; necessary for time waveform plotting later
    for s=1:length(p.sid)        
        ERPF{s}=fullfile(p.studydir, p.expid, p.sid{s}, 'analysis', [p.sid{s} p.erpext{e} '.mat']);         
        [pathstr,name,ext]= fileparts(deblank(ERPF{s}));
        ALLERP(s)=pop_loaderp('filename', [name ext], 'filepath', pathstr); 
    end % s=1:length(p.sid)
    
    %% INPUT CHECKS
    % Make sure we have sensible bin and channel information
    if ~isfield(p, 'bins') || isempty(p.bins), p.bins=1:length(ALLERP(end).bindescr); end 
    if ~isfield(p, 'chans') || isempty(p.chans), p.chans=size(ALLERP.bindata,1); end 
    
    %% TIME WAVEFORM PLOTS
    %   Time waveform plots with error bars (if specified).
    if p.twave && p.plev>1    
        
        %% SUBJECT SPECIFIC PLOTS
        for s=1:length(ALLERP)
            ERP=ALLERP(s);
            % Generate plot with appropriate error bars.
            cb_pop_ploterps(ERP, p.bins, p.chans, ...
                'SEM', num2str(p.nsem)); 
            
            % Change title
            %   Append subject name and ERP extension to whatever is
            %   already there. 
            appendext(gcf, [p.sid{s} p.erpext{e}]); 
        end % s=1:length(ERP)    
        
    end % p.twave && plev>1
    
    %% GROUP LEVEL WAVEFORM
    if p.twave && p.plev>0
        %   Use pop_gaverager to generate group average
        gALLERP(e)=pop_gaverager(ALLERP, ...
            'Erpsets', 1:length(ALLERP), ...
            'ExcludeNullBin', 'on', ...
            'Warning', 'off', ...
            'SEM', 'on', ...
            'weighted', 'off'); 
        
        % Rename ERP
        gALLERP(e).erpname = [p.erpext{e} ' | N=' num2str(length(ALLERP))];
        
        % Plot out group data
        
        % These weird reassignments are necessary because pop_ploterps
        % looks for the "ERP" variable by name. 
        ERP=gALLERP(e); 
        cb_pop_ploterps(ERP, p.bins, p.chans, ...
            'SEM', num2str(p.nsem)); 
        
        % Append information to figure title
        appendext(gcf, ['N=' num2str(length(ERP)) ' | ' p.sid{s} p.erpext{e}]); 
    end % p.twave && p.plev>0
    
    %% FREQUENCY DECOMPOSITION
    %   FFT decomposition on data (use AA_FFT.m)
    if p.fft && p.plev>0     
    
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
    if p.plv && p.plev>0
    
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
    
    %% CROSS POWER SPECTRAL DENSITY
    %   Looking at the cross-spectra between the stimulus (MMBF7.WAV, or
    %   /ba/) might provide unique insight into whether or not the stimulus
    %   is present in the time averaged waveform. 
    if p.xspec        
        % Compute CPSD and MSCOHERE
        AA_cpsd_mscohere(STIM, ERPF, [], [], ...
            'plev', p.plev, ...
            'chans', p.chans, ...
            'ysig', p.tsig, ...
            'bins', p.bins, ...
            'window', p.xspec_window, ...
            'nover', p.xspec_nover, ...
            'nfft', p.xspec_nfft, ...
            'nsem', p.nsem, ...
            'frange', p.frange, ...
            'antype', 'all');    
            
%         AA_xspec(STIM, ERPF, [], [], p); %...
%             'plev', p.plev, ...
%             'chans', p.chans, ...
%             'ysig', p.tsig, ...
%             'bins', p.bins, ...
%             'window', p.xspec_window, ...
%             'nover', p.xspec_nover, ...
%             'nfft', p.xspec_nfft, ...
%             'antype', 'all');                                
    end % p.xspec
    
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
if p.tsnr && p.plev>0
    
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