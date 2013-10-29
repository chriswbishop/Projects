function [X FS]=MSPE_fMRI_stim(IN, HDS, D, N, DATA, PL, PR, RMSNORM)
%% DESRIPTION:
%
%   Function to create Echo Suppression stimuli filtered with HRTFs.  This
%   relies on several other functions, including MSPE_stim and hrtf_filt.  
%
% INPUT:
%
%   IN:     (6 OR 7,1) stimulus structure.  Each row specifies a specific 
%           stimulus parameter. See below for a detailed treatment.  
%           See MSPE_stim for details.
%
%           NOTE: IN(1:2) are now RMS normalization targets rather than
%           direct maximum amplitude scaling factors.  This proved
%           necessary as scaling max amplitude to 1 led to 4-6 dB range of
%           stimulus loudness levels. With the RMS normalization, this is
%           instead about 1-1.5 dB.  
%
%   HDS:    HRTF structure.  See hrtf_filt.m for details.
%   D:      2x1 (or 1x2) double array with angles to present sounds at.
%           (e.g. [-45 45] to present at +/-45 degrees).
%   N:      Number of samples of filter to use (default 8000, or 0.083
%           sec at 96 kHz).
%   DATA:   Mx1, data to be presented.  This is passed to MSPE_stim for
%           processing
%
%   PL:     cell array, each element is a filename to a filter that will be
%           applied to the left CHANNEL (not location).
%   PR:     cell array, each element is a filename to a filter that will be
%           applied to the right CHANNEL (not location).
%
%   RMSNORM:    Flag, RMS Normalize rather than scale maximum.  This proved
%               useful for MSPE_fMRI when multiple, compensatory filters
%               had to be applied that introduced sporadic large values
%               that rendered a more typical maximum scaling unuseful
%               because it introduced a lot of trial to trial variance. 
% OUTPUT:
%
%   X:      M+N x 2 double array, stereo sound.
%   FS:     double, sample rate.
%   ASTIM:  Wave file written to MSPE/stims
%   ASTIM_cue:  Wave file with cue written to file.
%
%
% EXAMPLES:
%
%   ETYMOTICS:
%
%   Note: This example applies the same filter to both ears. Turns out,
%   for this set of Etymotics, the differences between ear buds is quite small.
%   Subjectively sounds externalize and localize just as well with any
%   combination of left/right compensatory filters (see OneNote for more
%   details). 
%
%   IN=[0.1;0.1;0.040;0;0;1];PL={'ETY-4B-R.mat'};PR={'ETY-4B-R.mat'}; D=[-20 20]; N=8000; DATA=[]; 
%
%   SENSIMETRICS S14 (#102):
%
%   Sounds are a bit quieter so will have to be careful to calibrate output
%   levels at the scanner. 
%
%   IN=[0.1;0.1;-0.040;0;0;1];PL={'S14-102-L.mat'};PR={'S14-102-R.mat'}; D=[-20 20]; N=8000; DATA=[];
%
%
% DEVELOPMENT NOTES AND BUGS:
%
%   These noise burst stims are still pretty jarring...I gotta figure out a
%   way to make them less "intense" but still get the same behavioral
%   effects. 
%
%   It seems like most of the "jarring" effect happens after prolonged
%   periods of silence.  For instance, after a long period of blank trials,
%   I even get a really large startle reflex.  However, after several
%   repetions on consecutive trials, I don't get it anymore.
%
%   I tried playing around with the stimulus ramp up and duration, but I
%   still got similar effects. 
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

    %% DEFAULTS AND ERROR CHECKING
    % Use whatever MSPE_stim does by default. Easy enough to change later.
    if ~exist('DATA', 'var'), DATA=[]; end;
    if ~exist('RMSNORM', 'var') || isempty(RMSNORM), RMSNORM=1; end;
    
    % Make sure the input data are only 1 column (one channel).  
    if size(DATA,2)>1, DATA=DATA(:,1); end;

    % Default to 8000 samples (0.0833 msec HRIR with HRTFs at 96000 Hz sampling
    % rate).  With my HRTF setup, anything longer than this starts to introduce
    % anomalies into the filtered sounds.  
    if ~exist('N', 'var'), N=8000; end;

    % Want to control FS independently of MSPE_stim just in case it changes.
    if ~exist('FS', 'var') || isempty(FS), FS=96000; end; 

    % No filters by default
    if ~exist('PL', 'var'), PL={}; end
    if ~exist('PR', 'var'), PR={}; end
    
    %% CREATE STIMULUS
    %   Make the stimulus with MSPE_stim.
    %   Note: Stimuli are scaled here, but will be RMS normalized later.  
    [ASTIM FS LEDo LEDs]=MSPE_stim(IN,DATA,FS);
%     [ASTIM FS LEDo LEDs]=MSPE_stim([1;1;IN(3);IN(4);IN(5);IN(6)], DATA, FS); 
    LEDo=LEDo-0.001*FS; % remove 1 msec offset. Don't need it with arduino
    
    %% DETERMINE NUMBER OF SAMPLES IN THE STIMULUS
    %   We need this information to figure out the window over which to
    %   perform normalization later.
    SLEN=length(ASTIM)-(abs(IN(3))*FS);

    % Zero pad a to allow filter to run its course.
    ASTIM=[ASTIM; zeros(N,2)];

    %% EDIT HRIR
    %
    %   I was hearing what I initially thought was a prominent acoustic
    %   reflection off the back wall (heard a sound near the back left corner
    %   of my head, almost intracranial).  Thought there might be some phase
    %   discontinuities introduced depending on how the HRIR is subsampled.
    %   For instance, if the HRIR is truncated to N samples, the last sample
    %   might not be 0, which will very likely introduce a perceptible phase
    %   discontinuity that could sound like what I was hearing.
    %
    %   Adding in this little diddy really helped a ton in combination with
    %   truncating the HRIR to somewhere between 5000<= N <=8000 (0.0521 sec
    %   <=N<=0.0833 sec at 96 kHz). Any longer than about 8000 taps and I start
    %   hearing prominent anomalies. 
    %
    %   NOTE: Might be worth wrapping this windowing section into hrtf_filt
    %   since this issue is highly unlikely to be isolated to this case.
    
    % For HRIR normalization.
    %   Dynamic normalization for subject specific HRTFs won't work so well
    %   if for some reason I screw up setting the average volume levels
    %   during the HRTF estimation procedure.  So, for now, I'll hard code
    %   it for consistency. 
%     hrTARG=mean(mean((squeeze(rms(HDS.hrir)))));
    hrTARG=0.0124; % based on load('C:\hrtfs\110527CWB-Click2\110527CWB-Click2-hds.mat')
    
    % Allocate
    HRIR=nan(N, size(HDS.hrir,2), size(HDS.hrir,3)); 
    for i=1:size(HDS.hrir,3)
        HRIR(:,:,i)=HDS.hrir(1:N,:,i); 
        
        % Window HRIR
        RAMP=0.005; % 5 msec ramp        
        W=[ones(1,round(RAMP*FS))'; ones(size(HRIR,1)-round(2*RAMP*FS),1);flipud(linspace(0,1,round(RAMP*FS))')];
        W=W*ones(1,size(HRIR,2)); 
        HRIR(:,:,i)=HRIR(:,:,i).*W;  
        
        % Scale HRIR
        [S(i)]=scalefact(HRIR(:,:,i), hrTARG, 0, size(HRIR,1));
        HRIR(:,:,i)=HRIR(:,:,i).*S(i);
        
    end % i   
    HDS.hrir=HRIR;

    %% FILTER WITH HRTF
    [POUT L]=hrtf_filt(HDS, D(1), ASTIM(:,1), N);
    [POUT R]=hrtf_filt(HDS, D(2), ASTIM(:,2), N); 

    %% MIX SOUNDS
    X=L+R; 

    %% REFERENCE SOUND (For Normalization purposes)
    %   There's an oversight here.  Current implementation does not allow
    %   for independent normalization of each location.  HM. 
    if IN(1)~=0, 
        REF=L; TARG=IN(1);
        if IN(3)>0, OFFSET=abs(IN(3)*FS); else OFFSET=0; end 
    elseif IN(2)~=0,
        REF=R; TARG=IN(2);
        if IN(3)<0, OFFSET=abs(IN(3)*FS); else OFFSET=0; end
    else
        REF=ones(size(L)).*IN(1); TARG=0; OFFSET=0;        
    end %
    
    %% APPLY CORRECTIVE FILTERS
    %   All filters assume a 96 kHz sampling rate.

    % Resample sounds to 96 kHz. 
    X=resample(X, 96000, FS); 
    REF=resample(REF, 96000, FS);   
    
    % Filter left channel, both locations and mixed sound
    for i=1:length(PL)
        load(PL{i}, 'Hd');
    
        % Check to make sure filtfilt isn't going to cough up an error
        if length(X)<3*length(Hd.Numerator)
            X=[X; zeros(3*length(Hd.Numerator)-length(X), size(X,2))];
        end % if length(X)
    
        % Check to make sure filtfilt isn't going to cough up an error
        if length(REF)<3*length(Hd.Numerator)
            REF=[REF; zeros(3*length(Hd.Numerator)-length(REF), size(REF,2))];
        end % if length(X)       
    
        % Need to filter L and R locations separately for normalization
        % purposes...dumb, yes, but I think very necessary. 
        REFf(:,1)=filtfilt(Hd.Numerator, 1, REF(:,1));
        Xf(:,1)=filtfilt(Hd.Numerator, 1, X(:,1));
        clear Hd;
    end % i=length(PL)

    % Filter right channels
    for i=1:length(PR)
        load(PR{i}, 'Hd'); 
    
        % Check to make sure filtfilt isn't going to cough up an error
        if length(X)<3*length(Hd.Numerator)
            X=[X; zeros(3*length(Hd.Numerator)-length(X), size(X,2))];
        end % if length(X)
    
        if length(L)<3*length(Hd.Numerator)
            REF=[REF; zeros(3*length(Hd.Numerator)-length(REF), size(REF,2))];
        end % if length(X)
        
        % Need to filter L and R locations separately for normalization
        % purposes...dumb, yes, but I think very necessary. 
        REFf(:,2)=filtfilt(Hd.Numerator, 1, REF(:,2));    
        Xf(:,2)=filtfilt(Hd.Numerator, 1, X(:,2)); 
        clear Hd;
    end % i=1:length(PR)
    if exist('REFf', 'var'),REF=resample(REFf, FS, 96000); else REF=resample(REF, FS, 96000); end
    if exist('Xf', 'var'),X=resample(Xf, FS, 96000); else X=resample(X, FS, 96000); end

    %% NORMALIZATION
%     if IN(3)>0, OFFSET=FS*IN(3); else OFFSET=0; end
    if RMSNORM
        [S]=scalefact(REF, TARG, OFFSET, SLEN);        
    else
        % Maximum scaling
%         display('not implemented'); 
        S=TARG./max(max(abs(REF)));
%         X(:,1)=X(:,1)./max(abs(X(:,1))); X(:,1)=X(:,1).*IN(1);
%         X(:,2)=X(:,2)./max(abs(X(:,2))); X(:,2)=X(:,2).*IN(2);
    end % RMSNORM
    X=X.*S; 
    
    % Write ASTIM.wav
    wavwrite(X, FS, '../stims/ASTIM.wav');

    %% ADJUST LEDo
%     LEDo=LEDo+0.029*FS; 
    LEDo=LEDo+0.0001*FS; 
    
    % Add cue and write file.
    addWavCue('../stims/', 'ASTIM.wav', LEDo, {LEDs}, 'ASTIM_cue.wav');

end % MSPE_fMRI_stim

function [S]=scalefact(DATA, TARG, OFFSET, SLEN)
%% DESCRIPTION
%
%   Determine scaling factor to apply to stimuli.  Notice that this scaling
%   procedure maintains inter-location differences (I think). Wow, this
%   code really needs some better commenting. I'll add it to my list of
%   shit I don't have time to do. 
%
% INPUT:
%
%   DATA:       Nx2 double array, where N is the number of stimulus time
%               points and 2 is the number of channels.
%   TARG:       double, target RMS value
%   OFFSET:     integer, sample number offset for window used to calculate
%               RMS of the stimulus. 
%   SLEN:       integer, window size (in samples)
%
% OUTPUT:
%
%   S:      double, scaling factor to apply to DATA to ensure RMS of DATA
%           is equal to TARG.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu
    S=TARG./mean((rms(DATA(1+OFFSET:OFFSET+SLEN,:))));
end % scalefact
