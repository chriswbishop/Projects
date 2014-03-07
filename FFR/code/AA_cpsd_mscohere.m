function [Cxy, Pxy, F]=AA_cpsd_mscohere(X, Y, FSx, FSy, varargin)
%% DESCRIPTION:
%
%   Wrapper to generate cross power spectral density, a measure of spectral
%   overlap between two time series of requal length. Also generates the
%   magnitude squared coherence estimate using MATLAB's mscohere function. 
%
%   Computations are performed pairwise between X and all columns (or rows)
%   of Y.
%
%   For details, see 
%   http://www.mathworks.com/help/signal/ug/cross-spectrum-and-magnitude-squared-coherence.html
%   
%   Desired features: 
%       Allow users to pass raw time series, ERP data structures, and
%       filenames pointing to saved ERPs and WAV files. CWB does not think
%       it would be useful to support loading individual EEG datasets.
%
% INPUTS:
%
%   Required:
%
%   X:  XXX
%   Y:  XXX
%       Note, you do not want to pass ERP.bindata directly as Y if multiple
%       bins are used. The error checking will throw a shoe. Instead, just
%       send the vertically concatenated filenames or arrayed in in a cell
%       array and the data will load automatically. 
%   FSx:    Sampling rate for time series X. Only used if X is a double
%           array.
%   FSy:    "" for time series Y. "" Only used if Y is a double array. 
%
%   Additional parameters:
%
%   Plotting:
%
%       'plev':     integer, plot level (e.g., 1). (Note: this has not been
%                   well tested)
%                       0: no plots generated
%                       1: group plots generated
%                       2: group AND subject level plots created (not
%                       implemented as of 3/7/2014)
%       'frange':   two element array specifying the frequency range for
%                   plotting purposes. Note: this does not affect the
%                   actual computations in any way, just the way the data
%                   are visualized. 
%
%   Data clipping:
%
%       'xsig':     two element array specifying the time (in seconds) that
%                   the signal can be found. This is useful when loading
%                   wave files with extended silence at either beginning or
%                   end OR when focusing on the post-stimulus time period
%                   for ERP data structures. (Ex. [0 0.2] | default=[-Inf
%                   Inf])
%       'ysig':     "" but for Y input. (default=[-Inf Inf])
%
%       NOTE:   For ERPs, time point 0 is the first time point of the *pre
%               stimulus* period! Adjust the time window accordingly. 
%
%   ERPs:
%
%       'chans':    channels to load. Required for ERP file names and ERP
%                   structures. (no default)
%       'bins':     bins to load from ERP structure. (Optional; all bins
%                   loaded by default)
%
%   Analysis:
%       
%       'window':   window for cpsd and mscohere. (default=[]); 
%       'antype':   analysis type. ('mscohere' | 'cpsd' | 'all' (default))
%                   If we have analyses that take a very long time, it
%                   might be necessary to specify which analysis is done.
%                   However, with just mscohere and cpsd with short signals
%                   (<20,000 samples), the computations are *very* fast, so
%                   it's not an issue. This flag is here primarily for
%                   future development or in the event that long time
%                   series are necessary. 
%       'noverlap': number of samples by which sections overlap
%                   (default=[])
%       'nfft':     FFT length (default=[]); 
%
% OUTPUTS:
%
%   Cxy:    complex, cross-spectrum power density function.
%   Pxy:    magnitude-squared coherence estimate
%
% DEVELOPMENT NOTES:
%
%   -Might be useful to perform a time-frequency based CPSD analysis. That
%   is, one that does NOT collapse over section estimates. (low priority).
%
%   - Might be useful to estimate the "apparent latency" of the two
%   signals. 
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% INPUT CHECKS
% Filenames need to be in a cell array
if isa(X, 'char')
    X={X}; 
end % isa(X, 'char')

if isa(Y, 'char')
    % Assume these are vertically concatenated filenames
    for n=1:size(Y,1)
        y{n}={deblank(Y(s,:))}; 
    end % for n=1:size(Y,1)
end % if 

% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
else 
    p=varargin{1};
end %

% Set default values.
%   Note that p.bins is set in lddata if an ERP structure or ERP filename
%   are provided. 
try p.bins; catch p.bins=[]; end 
try p.chans; catch p.chans=[]; end % will throw a shoe during lddata call.
try p.window; catch p.window=[]; end 
try p.antype; catch p.antype='all'; end 
try p.noverlap; catch p.noverlap=[]; end
try p.nfft; catch p.nfft=[]; end %
try p.xsig; catch p.xsig=[-Inf Inf]; end 
try p.ysig; catch p.ysig=[-Inf Inf]; end 

%% INITIALIZE OUTPUT VARIABLES
F=[]; % Frequency bins
Pxy=[]; % magnitude squared coherence estimate
Cxy=[]; % CPSD estimates

%% LOAD TIME SERIES
% Load reference time series to which all others will be compared
%   This should have a maximum of ONE time series. 
p.maxts=1;
[X, fsx]=lddata(X,p);
% Reassign sampling rate if we need to. 
if ~isempty(fsx), FSx=fsx; clear fsx; end 

% Load data to compare to X. Infinite number of time series allowed, but
% will be limited by memory constraints. 
p.maxts=Inf;
[Y, fsy, LABELS]=lddata(Y,p); 
% Reassign sampling rate if we need to. 
if ~isempty(fsy), FSy=fsy; clear fsy; end

%% WINDOW DATA
%   Set analysis window as specified by p.xsig and p.ysig
X=windowdata(X, FSx, p.xsig); 
Y=windowdata(Y, FSy, p.ysig); 

%% MASSAGE DATA FOR MSCOHERE AND CPSD
% Match sampling rates
MAXFS= max([FSx FSy]); 
X=resample4TDT(X, MAXFS, FSx);

% Loop call to support multidimensional arrays
y=nan(size(Y)); 
for n=1:size(Y,3)
    y(:,:,n)=resample4TDT(Y(:,:,n), MAXFS, FSy); 
end 
% Reassign
Y=y; 
clear y; 
% Y=resample4TDT(Y, MAXFS, FSy);

% Match stimulus length
MAXLN= max([size(X,1) size(Y,1)]);
X=[X; zeros(MAXLN-size(X,1),size(X,2))];

% Slightly different call to support 3D matrices (e.g., when multiple ERP
% files are passed in as Y. 
%   Initialize a temporary variable as NaNs. Recall that matlab will
%   populate a resized array with zeros by default, which makes it tough to
%   spot errors. With a NaN array, any errors should be easy to spot.
y=nan(MAXLN, size(Y,2), size(Y,3)); 
for n=1:size(Y,3)
    y(:,:,n)=[Y(:,:,n); zeros(MAXLN-size(Y,1),size(Y,2))];
end

% Reassign
Y=y; 
clear y; 

% X=match_fs_length(X, FSx, MAXFS, MAXLN, p);
% Y=match_fs_length(Y, FSy, MAXFS, MAXLN, p);

%% COMPUTE MSCOHERE
%   Magnitude-squared coherence.
if strcmpi(p.antype, 'mscohere') || strcmpi(p.antype, 'all')
    for n=1:size(Y,3)
        for i=1:size(Y,2)        
            [pxy, F]=mscohere(X,Y(:,i,n),p.window,p.noverlap,p.nfft, MAXFS);
            Pxy(:,i,n)=pxy; 
            clear pxy            
        end % for i=1:size(Y,2)
    end % for n=1:size(Y,3)
       
    % Set parameter input to set y-axis range
    p.range=[0 1];
    create_plot(F, Pxy, 'Frequency (Hz)', 'Magnitude Squared Coherence', LABELS, p);
    
end % strcmpi(p.antype)

%% COMPUTE CPSD
%   Cross power spectral density
%
%   This computation averages over time windows.
if strcmpi(p.antype, 'cpsd') || strcmpi(p.antype, 'all')
    for n=1:size(Y,3)
        for i=1:size(Y,2)        
            [cxy, F]=cpsd(X,Y(:,i,n),p.window,p.noverlap,p.nfft, MAXFS);
            Cxy(:,i,n)=cxy; 
            clear cxy            
        end % for i=1:size(Y,2)
    end % for n=1:size(Y,3)
    
    % Try to create a plot
    %   Checks to p.plev (plotting level) are made in create_plot.
    p.range=[]; % use whatever autoscale gives us
    create_plot(F, db(abs(Cxy)), 'Frequency (Hz)', 'Power Spectral Density (dB/Hz)', LABELS, p);
        
end % strcmpi(p.antype)

%% PLOTTING FUNCTIONS
%   Group level CPSD plot%% GET LINE SPECS

%% ESTIMATE TIME DELAY BETWEEN TWO SIGNALS 
%   Y relative to X (+ values mean that Y starts after X, - values mean
%   that Y starts before X). 
%
%   Estimate phase delay as a measure of latency offset. For broadband
%   stimuli (e.g., speech), might be useful to use a linear fit to
%   unwrapped phase angles vs. frequency plot. 
%
%   Ah, I can see that this is actually suggested in
%
%   Picton, T. W., et al. (2003). "Human auditory steady-state responses." Int J Audiol 42(4): 177-219.
%
%   See "apparent latency" estimates and Figure 2. 
%
%   Limit slope estimate to frequencies that are well-represented in both
%   signals?? (MSCOHERE)?
%
%   Not sure how informative this will be. Reconsider before writing. 

%% TIME-FREQUENCY CPSD
%   Might be helpful to show CPSD as a function of time, rather than
%   averaging over all time windows. 
%   
%   Actually, CWB doesn't think this would be very useful, particularly for
%   temporally offset signals. 
%
%   Reconsider before writing. 

end % AA_cpsd_mscohere

function [X, FS, LABELS]=lddata(X, p)
%% DESCRIPTION:
%
%   Function to dynamically load data with various input types. Kicks back
%   data in double format.
%
% INPUT:
%
%   Required
%       X:      input data, or string to ERP file/wav file.
%       p:      additional parameters for loading data.
%
% OUTPUT:
%   
%   Y:  double array, loaded data. NxM array. 
%   FS: sample rate of data if data are loaded from file or contained in an
%       ERP structure.
%   LABELS: cell array of labels for plotting. This proved useful when
%           plotting out ERP data with bin labels specified in the ERP
%           structure.
%
% Christopher W. Bishop
%   University of Washington
%   3/14

%% INITIALIZE FS
FS=[]; 
LABELS={}; 

%% DETERMINE DATA TYPE AND WHAT TO DO
if isa(X, 'double')
    % If it's a double, just make sure it's the proper dimensions
    
    % If the number of time series exceeds p.maxts, throw an error. Useful
    % when ensuring that a loaded wav file is not (or is) stereo. Typically
    % we want a single time series for the "X" input to the parent
    % function. 
    if min(size(X))>p.maxts
        error('Exceeds maximum number of dimensions'); 
    end % if min(size(X))>1
    
    % Dimension checks
    %   Assume that the shortest dimension are the individual time series. 
    if numel(size(X))>2
        error('Too many dimensions');
    elseif size(X,1) == size(X,2)
        error('This is a square matrix, not sure what to do with it');
    elseif size(X,1)==min(size(X))
        X=X';
    end % if ... 
    
    % Create default labels for plotting
    for n=1:size(X,2)
        LABELS{n}=['TimeSeries (' num2str(n) ')'];
    end % for n=1:size(X,2)
    
elseif isa(X, 'cell') 
    % Filenames will be necessarily stored in a cell array.
    
    % Try reading in as a wav file. If that fails, assume it's an ERP file.
    % If THAT fails, then we're clueless.
    try
        [X, FS]=wavread(X{1});  %#ok<DWVRD>
        
        % Sommersault to check data size and dimensions
        X=lddata(X, p); 
    catch
        
        % In the event multiple file names are used, create a structure
        % array, then do a sommersault to process those data.
        for n=1:length(X)
            [pathstr,name,ext]= fileparts(X{n});
            x(n)=pop_loaderp('filename', [name ext], 'filepath', pathstr);   
        end % for n=1:length(X)
        
        % Reassign to X
        X=x;
        clear x; 
        
        % Sommersault to load ERP structure
        %   Include additional parameters in call so we know what to do
        %   with the data.
        [X, FS, LABELS]=lddata(X, p); 
    end % try/catch   
    
elseif iserpstruct(X)
    
    % Parameter checks
    %   We can't support more than a single channel. Do NOT set a default
    %   channel, however, since this could lead to some undetected wonky
    %   results.
    if numel(p.chans)>1
        error('Cannot support multi-channel data (yet)'); 
    elseif isempty(p.chans)
        error('No channels specified'); 
    elseif isempty(p.bins)        
        % If bins are not defined, then load all bins. 
        p.bins=1:size(X(1).bindata,3);  % assumes all ERP structures are the 
                                        % same size. Safe since they will
                                        % have to be for plotting purposes
                                        % later. 
    end % if numel(p.chans)>1
    
    % Set sampling rate
    %   Assumes all sampling rates are equal
    %   Also assumes that bin labels are the same across all ERP
    %   structures. Reasonably safe.
    FS=X(1).srate;    
    LABELS={X(1).bindescr{p.bins}}; % bin description labels
    for n=1:length(X)
    
        % Truncate data
        tx=squeeze(X(n).bindata(p.chans, :, p.bins)); 
        
        % Sommersault to reset data dimensions if necessary
        [tx]=lddata(tx, p); 
        
        % Assign to growing data structure
        x(:,:,n)=tx; 
    end % for n=1:length(X)
    
    % Reassign to return variable X
    X=x; 
    clear x; 
    
else
    error('Dunno what this is, kid.');
end  % if ...

end % function lddata

function X=windowdata(X, FS, TWIN)
%% DESCRIPTION:
%
%   Function to window data based on sampling rate and user specified time
%   windows.
%
% INPUT:
%
%   X:  data series as returned from lddata.
%   FS: sampling rate of data
%   TWIN:   two element array specifying the time window. (E.g. [0 Inf]). 
%
% OUTPUT:
%
%   X:  windowed data
%
% Christopher W. Bishop
%   University of Washington 
%   3/14

%% CREATE TIME VECTOR
%   lnspace
t=(0 : 1/FS : size(X,1)/FS-1/FS)';

% Was going to do input checks, but we can't do this easily with Inf and
% -Inf input arguments. So let it throw an uninformative error. 

% %% INPUT CHECKS
% %   Make sure time window fits the stimulus (e.g., window isn't too wide)
% if TWIN(2) > t(end)
%     error('Specified time window is too wide');
% end % if TWIN(2) > t(end)

% Generate a time mask
tmask=AA_maskdomain(t, TWIN); 

% Apply mask
%   Added 3rd dimension argument in the event that multiple ERP files are
%   used (e.g., when creating group averages based on time averaged
%   waveforms. 
X=X(tmask,:,:); 

disp('CWB: Should we use a smarter windowing function (e.g., hamming??). Will likely reduce spectral splatter effects'); 

end % X=windowdata(X, FS, p)

function create_plot(X, Y, XLAB, YLAB, LABELS, p)
%% DESCRIPTION:
%
%   Function to create data plots for AA_cpsd_mscohere. All plots at the
%   time CWB wrote this were almost identical, so CWB decided to modularize
%   the plotting function.
%
% INPUT:
%
%   X:
%   Y:
%   XLAB:
%   YLAB:
%   p:  
%
% OUTPUT:
%
%   A figure, man. A figure.
%
% Christopher W. Bishop
%   University of Washington
%   3/14

% Group level plots
if p.plev>0
    figure, hold on
    
    % Massage NxS data matrix into Nx1xS matrix
    if ndims(Y)==2 %#ok<ISMAT>
        y(:,1,:)=Y;
        Y=y; 
    end % if ndims(X)==2
    
    % Attempt to get appropriate colors with NxS and NxBxS matrices
    [colorDef, styleDef]=erplab_linespec(max([size(Y,2) p.bins]));
    
    
    %% PLOT SEM
    %   Plotted first for ease of legend labeling. Yes, I know I'm looping
    %   through the data twice. Yes, it is inefficient. No, I don't care.    
    for i=1:size(Y,2) % for each bin we are plotting
        
        % Put data into temporary matrix
        tdata=squeeze(Y(:,i,:)); 
        
        % Plotting SEM when NSEM=0 causes some graphical issues and very
        % slow performance. 
        if p.nsem~=0
            
            % Select color definition
            if ~isempty(p.bins) % && ndims(X)==3
                cdef=colorDef{p.bins(i)};
                sdef=styleDef{p.bins(i)};
            else
                cdef=colorDef{i};
                sdef=styleDef{i};
            end % if ~isempty(p.bins ...
            
            U=mean(tdata,2) + sem(tdata,2).*p.nsem; 
            L=mean(tdata,2) - sem(tdata,2).*p.nsem; 
            ciplot(L, U, X, cdef, 0.15); 
            
        end % if ~NSEM~=0
        
    end % for i=1:size(Y,2)    
    
    % Now plot the individual data traces 
    for i=1:size(Y,2)
        
        % Select color definition
            if ~isempty(p.bins) % && ndims(X)==3
                cdef=colorDef{p.bins(i)};
                sdef=styleDef{p.bins(i)};
            else
                cdef=colorDef{i};
                sdef=styleDef{i};
            end % if ~isempty(p.bins ...
        
        tdata=mean(squeeze(Y(:,i,:)),2); 
        plot(X, tdata, 'Color', cdef, 'LineStyle', sdef, 'linewidth', 1.5);
    end % for i=1:size(A,2)
    
    % Turn on grids
    set(gca, 'XGrid', 'on', 'YGrid', 'on')
    
    % Markup figure
    xlabel(XLAB)
    ylabel(YLAB)
    legend(LABELS, 'Location', 'northeast'); 
    
    % Set title string
    titlstr= ['N=' num2str(size(Y,3)) ' | '];
        
    if ~isempty(p.bins)
        titlstr=[titlstr 'Bins: [' num2str(p.bins) '] | ']; 
    end % if ~isempty(p.bins)

    title(titlstr); 
    
    % Set domain if user specifies it
    if isfield(p, 'frange') && ~isempty(p.frange)
        xlim(p.frange);
    end % if isfield(p, 'frange') ...
    
    % Set range if specified
    if isfield(p, 'range') && ~isempty(p.range)
        ylim(p.range);
    end % if isfield(...
    
end % if p.plev>0
end % function create_plot