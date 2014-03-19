function [S, F, T, P]=AA_spectrogram(X, varargin)
%% DESCRIPTION:
%
%   Function to create spectrograms from data, including ERP data. 
%
% INPUTS:
%
%   Required:
%
%   X:  data information supported by AA_loaddata. This can be a cell array
%       of filenames pointing to EEG data structures, ERPLAB data
%       structures, WAV files, CNTs, etc. See AA_loaddata for details.
%
%   Usually Required:
%   
%   'fs':       sampling rate. ignored for ERP and EEG data structures.
%               Only used if X is a double matrix.
%   'chans':    required for ERP and EEG data structures. Can only be a
%               single channel (for now). This is necessary so
%               AA_spectrogram works with any data type. A wrapper will
%               have to be written to work with multiple channels (a simple
%               loop will suffice). 
%   'bins':     required for ERP data structures
%   'window':   window used for spectrogram. In this specific case, if a
%               single integer value is provided, the function assumes this
%               is the *duration* of a window in seconds. This is then
%               converted to a sample number in the call to spectrogram and
%               thus whatever spectrogram uses as a windowing function is
%               used here. 
%                   XXX Devel XXX Allow for custom windowing functions and
%                   shapes. 
%   'noverlap': integer, number of overlapping samples
%   'nfft':     integer, the number points to use in FFT - determines
%               frequency resolution of resulting spectrogram. For a
%               resolution of 1 Hz, set nfft to the sampling rate.
%
%   Plotting settings
%
%   'plev':     plotting level. Currently plots if value >0. (default 0)
%   'trange':   two element double. Min and max time range for plotting
%               purposes. (default = [-Inf Inf])        
%   'frange':   two element double. Min and max frequency range for
%               plotting purposes. (default = [-Inf Inf])
%   'caxis':    determines color scaling in figure. (default = 'default')
%                   'symmetric':    colorscale is symmetric around 0
%                   'default':      color scale is scaled however MATLAB
%                                   does it by default. 
%
% Desired features:
%   - Create spectrograms of data traces. 
%   - Data traces should be one of the following
%       - One or more channels of an EEG data structure
%       - One or more channels of an ERP data structure, or file path to
%       such a data structure. 
%
%   - Each graph will be for each time series within a specific frequency
%   range and time range.
%   
% Christopher W. Bishop
%   University of Washington
%   3/14

%% MASSAGE INPUT ARGS
% Convert inputs to structure
%   Users may also pass a parameter structure directly, which makes CWB's
%   life a lot easier. 
if length(varargin)>1
    p=struct(varargin{:}); 
elseif length(varargin)==1
    p=varargin{1};
elseif isempty(varargin)
    p=struct();     
end %

%% INPUT CHECK
%   I think AA_loaddata will take care of most other input checks
try p.fs; catch p.fs=[]; end 
try p.noverlap; catch p.noverlap=[]; end
try p.window; catch p.window=[]; end
try p.nfft; catch p.nfft=[]; end
try p.tfreqs; catch p.tfreqs=[]; end
try p.plev; catch p.plev=0; end 
try p.sem; catch p.sem=0; end 
try p.trange; catch p.trange=[-Inf Inf]; end 
try p.frange; catch p.frange=[-Inf Inf]; end
try p.caxis; catch p.caxis='default'; end

%% LOAD DATA
[X, FS, LABELS, ODAT, DTYPE]=AA_loaddata(X, p); 

% Squeeze data if this is an ERP or EEG structure
%   Useful when loading channel traces
if ismember(DTYPE, [3 4]) && size(X,1)==1 
    X=squeeze(X);          
elseif ismember(DTYPE, [3 4])
    error('Multiple channels loaded from ERP or EEG data set. Not supported.'); 
end % if ismember(DTYPE, [3 4])

% Last check to make sure we have an appropriately sized data matrix
if numel(size(X))>3 
    error('Something is up. Did you try to run analysis on multiple channels?');     
end % if numel(size(X))>3

% Check sampling rate
%   Set sampling rate if it's unknown from AA_loaddata but specified by the
%   user. 
%
%   If FS is unknown by AA_loaddata and the user doesn't supply one, then
%   throw an error. We won't be able to make much sense out of this later
%   during plotting routines.
if ~isempty(p.fs) && isempty(FS)
    FS=p.fs;
elseif isempty(p.fs) && isempty(FS)
    error('Sampling rate undefined.'); 
end % if ~isempty(p.fs) && ... 

%% DEFINE OUTPUT VARIABLES
S=[];   % FFT
F=[];   % Frequency bins
T=[];   % Time bins
P=[];   % PSD (in decibels). Used for plotting.

% Loop through all data series (typically subjects)
for m=1:size(X,3)
    
    % Loop through all traces (typically bins or averaged responses)
    for n=1:size(X,2)
        
        % Compute spectrogram
        %   Different calls depending on window information.
        %   If it's a time (in sec), convert to samples
        if numel(p.window)==1
            w=size(X,1)/FS*p.window;
        else
            w=p.window;
        end % if numel(p.window)==1 ...
        
        % Compute spectrogram
        [s,F,T,o]=spectrogram(double(X(:,n,m)), w, p.noverlap, p.nfft, FS);
        
        % Put data back into return structures
        S(:,:,n,m)=s;      
        P(:,:,n,m)=10.*log10(abs(o)); % Transform PSD into decibels   
                                      % abs necessary in case the signal is 
                                      % complex.
    end % for n=1:size(X,2)
    
end % for s=1:size(X,3)

%% PLOTTING FUNCTIONS

% Plot PSD vs time vs freq
if p.plev>0
   
    
    % Create time and frequency masks
    %   We adjust the plotted data so the data are scaled sensibly instead
    %   of resetting x and ylim after the fact. 
    tmask=AA_maskdomain(T, p.trange);
    fmask=AA_maskdomain(F, p.frange); 
    
    % Compute mean across subjects for each trace
    for n=1:size(P,3)
         figure, hold on
         x=mean(P(:,:,n,:),4);
         x=squeeze(x); 
         
         surf(T(tmask), F(fmask), x(fmask, tmask), 'edgecolor', 'none');
         view(0,90);
         axis tight
         % Figure axis labels
         xlabel('Time (s)');
         ylabel('Frequency (Hz)');
         
         % Maximum value
         mval=ceil(max(max(abs(x(fmask, tmask)))));
         
         % Set colorbar
         if strcmpi(p.caxis, 'symmetric')
            caxis([-1*mval; mval]);
         end % if strcmpi(p.caxis ...
         colorbar
         
         % Set title
         title(['N=' num2str(size(P,4)) ' | ' LABELS{n}]);
         
    end % for n=1:size(P,3)
end % if p.plev