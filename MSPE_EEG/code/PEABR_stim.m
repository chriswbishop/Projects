function [ASTIM FS OUT SIND TOUT COUT]=PEABR_stim(IN, DATA, FS, ADDCUE, WRITE)
%% DESCRIPTION:
%   
%   Create stimulus trains for Precedence Effect Auditory Brainstem
%   Response (PEABR) project.  This piggybacks off of MSPE_stim, but takes
%   into account many new stimulus parameters that are not handled in
%   MSPE_stim. It would be way too messy to try to get MSPE_stim to handle
%   all of these while maintaining reverse compatibility, so it required a
%   bit of a branch point. 
%
% INPUT:
%
%   IN: (X,Y) stimulus structure.  Each row specifies a specific stimulus
%       parameter while each column specifies a species of stimuli used in
%       the stimulus train. X is the number of stimulus parameters (below)
%       and Y is the number of stimulus species. 
%
%       IN(1,:) (LAC)
%           Left audio channel, integer used to determine whether or not a
%           sound should be played from the left audio channel. Input is
%           binary (0=no sound; 1=sound).  Note that this will also allow
%           the user to scale the output level of each channel
%           independently (e.g. 0.5 will scale for a max volume of 0.5). 
%       IN(2,:) (RAC)
%           Right audio channel, integer used to determine whether or not a
%           sound should be played from the right audio channel.  Input is
%           binary (0=no sound; 1=sound)
%       IN(3,:) (ALAG)
%           Audio lag (sec), double used to determine audio lag.  Assumes a
%           RIGHT LEADING sound.  For instance, a lag of 0.002 sec will
%           result the left channel's output being delayed by ~2 msec
%           relative to the right channel. This is arbitrary, but conforms
%           to SL's study (I think). If lag is -0.002 sec, then LEFT
%           channel leads by 2 msec (right delayed).
%       IN(4,:) VCOD
%           Video port code, double.  Paradigm currently powers LEDs
%           through Parallel port.  VCOD specifies both which light flashes 
%           and the flash timing relative to the primary and secondary.
%               12:     Right light, timed with primary.
%               14:     Left light, timed with secondary.
%               22:     Right light, timed with secondary.
%               24:     Left light, timed with secondary.
%       IN(5,:) COND
%           Condition code, double.
%       IN(6,:) LJIT
%           Lower bound for temporal jitter (sec; e.g. LJIT=0.150;)
%       IN(7,:) UJIT
%           Upper bound for temporal jitter (sec; e.g. LJIT=0.250;)
%       IN(8,:) NSTIM
%           Number of stimuli per stimulus train (i.e. the number of clicks
%           for this particular stimulus configuration). 
%       IN(9,:) NBREAKS
%           Number of break points in stimulus train. 
%       IN(10,:) MINIMUM CHUNK SIZE
%           The minimum number of stims that can be in each chunk of the
%           stimulus.  This parameter helps protect from selecting a switch
%           event at the edge of the stimulus train (will cause an error)
%           and allows some additional control of the complexity of the
%           stimulus.
%       IN(11,:) CODE OFFSET
%       IN(end,:) NTRLS
%           Trial number, integer.  Not explicitly used here, but is part of
%           the structure so it's listed.  This should ALWAYS be the last
%           row value for the stimulus definition.  
%
%   DATA:
%   FS: sampling rate in Hz (e.g. FS=96000; default=96000); 
%   ADDCUE: integer, flag to write wave cues or not.  This takes
%           substantially more time to do since AddWavCue is a slow
%           function that I don't care to deal with.  For experiments that
%           do not require the cues, it might be advantageous to disable
%           this feature (0=no cues written; 1=cues written (default)).
%           *NOTE*: The "ASTIM_cue.wav" file will STILL BE WRITTEN, it just
%           won't contain any cues. Be careful.  This is the lesser of two
%           evils (changing presentation code to play a different stim is
%           never a good idea, but not having cues drop would be
%           immediately obvious in an EEG session for instance).
%   WRITE:  bool, flag to write wave files or not. This prooved useful for
%           paradigms that do not need wav files written to disk, but
%           rather rely on the get_wave_data operation through the MATLAB
%           extension. (default = true)
% OUTPUT:
%
%   ASTIM:  Jx2 double array, where J is the number of samples and 2 is the 
%           number of channels in the data written to file.
%   FS:     integer, sampling rate in Hz (e.g. 96000)
%   OUT:    cell array, this is the stimulus train for each species
%           specified by IN.
%   SIND:   
%   TOUT:   Timing OUT (TOUT), this is a double array with the sample
%           number when codes in COUT are embedded in the WAV file.
%   COUT:   Code OUT (COUT), this is a cell array of codes embedded in the
%           WAV file.
%   
% EXAMPLES:
% 
% 1.Create a mix of left-only and right-only stimulus trains with 1 break
%   in each stimulus species.  SOA ranges from 0.15-0.25 sec, uniform
%   distribution. CODE OFFSET is set to -0.001 to offset an assumed delay
%   present in MSPE_stim (see MSPE_stim for details).  Codes are embedded
%   at the start of the leading (right) and lagging (left) sound onset by
%   prepending a 1 or 2 to the VCOD (see above for details).DATA and FS are
%   set to default values. 
%
%   IN=[[1;0;0.001;21;1;0.15;0.25;20;1;0;-0.001;1] [0;1;0.001;12;1;0.15;0.25;20;1;0;-0.001;1]];
%   DATA=[];
%   FS=[];
% 
%   [ASTIM FS OUT SIND TOUT COUT]=PEABR_stim(IN, DATA, FS);
%
% NOTES:
%
%   111026 CWB: Added in code writing abilities!  This is definitely not 
%               an easy thing to do with stimulus trains like this, but I
%               think I got it down.  Need to do more testing to be sure. 
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
%   Default inputs, at least what I can actually reasonably assume is a
%   default.
if ~exist('DATA', 'var') || isempty(DATA), DATA=ones(5,1); end 
if ~exist('FS', 'var') || isempty(FS), FS=96000; end 
if ~exist('ADDCUE', 'var') || isempty(ADDCUE), ADDCUE=1; end
if ~exist('WRITE', 'var') || isempty(WRITE), WRITE=true; end

%% SET STATE OF RANDOM NUMBER GENERATOR 
rand('twister', sum(100*clock)); 

%% ASSIGN OUTPUT VARIABLES
% ASTIM={};
OUT={}; 
%% CREATE STIMULUS OF EACH SPECIES
for i=1:size(IN,2)
    %% STIMULUS INDEX (SIND)
    %   Gives us the first and last sample of each stimulus instance in the
    %   train. 
    SIND{i}=[];
    OUT{i}=[]; 
    LEDo{i}=[];
    LEDs{i}=[];
    
    %% MAKE SINGLE STIMULUS INSTANCE
    [ASTIM FS ledo leds]=MSPE_stim(IN([1:5 11 end],i) , DATA, FS, [], [], WRITE); 
    
    %% MAKE STIMULUS TRAIN
    for n=1:IN(8,i) % hard coded reference to NSTIMS   
        
        %% DETERMINE LENGTH OF STIMULUS (jittering)
        dur=(IN(6,i)+ ((IN(7,i)-IN(6,i))*rand(1))); % sec
        dur=round(dur*FS);
        astim=[ASTIM; zeros(dur-size(ASTIM,1),size(ASTIM,2))]; 
        
        if isempty(OUT) || isempty(OUT{i})
            SIND{i}(n,1)=1;
            SIND{i}(n,2)=length(astim);
        else
            SIND{i}(n,1)=size(OUT{i},1)+1;
            SIND{i}(n,2)=size(OUT{i},1)+length(astim); 
        end % length
        
        %% TRACK VCOD
        % Note: Order here is important, so don't mess with it unless you
        % are comfortable with it. 
        
        % Add 1 sample to align with start of the next section. 
        LEDo{i}=[LEDo{i}; size(OUT{i},1)+ledo+1];
        LEDs{i}=strvcat(LEDs{i}, leds); 
        
        %% APPEND TO GROWING STIMULUS TRAIN
        OUT{i}=[OUT{i}; astim];         
        
    end % n
end % i

%% DETERMINE LOCATION OF BREAKPOINTS
%
%   For early pilot work, we needed to do some validation of our task to
%   make sure people are able to reliably detect at least one and up to
%   several changes in perception, even when they're randomly put in place,
%   like a bistable percept.  This was largely driven by some observations
%   I should come back to later on ... basically, suppression might be
%   bistable when it's relying on buildup.  This was most pronounced with
%   diotic presentation of stimuli using AKGs (circumaural headphones).
%   It's possible (actually likely) that these spontaneous changes are
%   linked to head movements or changes in how well the headphones are
%   coupled to the ears.  I know, anectdotally at least, that this explains
%   a lot of short latency switches in other bistable phenomena, such as
%   classic ABA streaming paradigms. 
%
%   This section of code allows chunks of different species of stimuli to
%   be interleaved.  The most obvious application is to intersperse obvious
%   singles and obvious doubles. 
%
%   This is done by breaking each stimulus species (each cell of OUT) into
%   NBREAKS+1 different fragments.  Fragments from each cell of OUT are
%   then interleaved to create the final stimulus with NBREAKs in the
%   stimulus train.  With 0 breaks, species are appended to one another.
%   
%   For example, if NBREAKs=0 for both species of OUT and OUT{1}=A and
%   OUT{2}=B, the final stimulus will be "AB".  Alternatively, if NBREAKS=1
%   for each species in OUT, the sequence A is broken into NBREAKS+1
%   smaller fragments (a). The same is done with B (fragments referred to
%   as 'b').  Fragments are then interleaved to give a sequence 'abab'.
%  
%   This strategy should generalize to any number of stimulus species, but
%   I've only tested it with two at a time, so proceed with caution if
%   you're doing more than this. 
%
%   NOTE:   Currently doesn't handle break points at the ends very well.
%           Need to put in a check during breakpoint selection to make sure
%           we don't do it on edges. Or, more generally, that they last X
%           number of stims total. 

% CHUNK INDEX (CIND)
%   This stores pairs of index values into each stimulus species within the
%   train (each cell of OUT).
CIND={}; 
for i=1:size(IN,2)
    
    CIND{i}=[]; % initialize CIND 
    
    %% SELECT BREAKPOINTS
    %   SELECTBP is a flag. If set (1), we continue looking for break
    %   points. If not set (0), we stop looking. 
    if IN(9,i)>0
        SELECTBP=1;
    else
        SELECTBP=0; 
        ind=[];
    end % ind
    
    %% SEARCH FOR BREAK POINTS
    %   This section tries to find suitable breakpoints to fragment
    %   individual species in OUT.  This is reasonably random, but has a
    %   few checks to make sure the last stimulus in the string is not
    %   selected (this causes some practical issues).  
    while SELECTBP
        %% GRAB BREAK POINTS
        ind=randperm(size(SIND{i},1));
        ind=sort(ind(1:IN(9,i))); 
        
        DUR=[diff(ind) size(SIND{i},1)-ind(end)];
        
        %% NEED ONE MORE CATCH HERE TO MAKE SURE WE DON'T GRAB THE LAST
        %% STIMULUS IN THE TRAIN.
        %   Because of indexing later on, this breaks if we happen to have
        %   a "break point" at the end of the stimulus train. There's likely
        %   a better way to do this, but I don't have time.  This works, so
        %   it is my solution.  If you don't like it, then write your own
        %   shit. 
        if ~ismember(1, DUR<IN(10,i)) && ind(end)~=size(SIND{i},1), SELECTBP=0; end 
    end % while
    
    %%  BUILDUP CIND
    %   Here, I store the edges of individual fragments. 
    for j=1:length(ind)
        if j==1
            CIND{i}(1,1:2)=[SIND{i}(1,1) SIND{i}(ind(j),2)];            
            try
                CIND{i}(2,1:2)=[SIND{i}(ind(j)+1,1) SIND{i}(ind(j+1),2)];
            catch
                CIND{i}(2,1:2)=[SIND{i}(ind(j)+1,1) SIND{i}(end,2)];
            end % try
        elseif j==length(ind)
            CIND{i}(end+1,1:2)=[SIND{i}(ind(j)+1,1) SIND{i}(end,2)];
        else
            CIND{i}(end+1,1:2)=[SIND{i}(ind(j)+1,1) SIND{i}(ind(j+1),2)];
        end % if j
    end % for j
    
    %% SPECIAL CASE IF THERE ARE NO BREAKS
    if isempty(ind)
        CIND{i}(end+1,1:2)=[SIND{i}(1,1) SIND{i}(end,2)];
    end % isempty(ind)
end % for i

%% MAKE SURE CIND HAS INFO IN IT
%   This is clunky, but if CIND isn't assigned (e.g. NBREAKS=0), we need to
%   just set it to the whole length of the stims and stick the species
%   together.
if isempty(CIND)
    for i=1:size(IN,2)
        CIND{i}(1,1:2)=[SIND{i}(1,1) SIND{i}(end,2)]; 
    end % i
end % CIND

%% MIX CHUNKS INTO SINGLE STIMULUS TRAIN
%   This currently assumes that the number of break points in each stimulus
%   species will be equal. I'm really only writing this to mix two species
%   as well, so if you want more species, you'll probably have to do some
%   debugging of your own. Also currently just interleaves the chunks. This
%   was all I needed for a control experiment. 

% ASTIM:    This is the final stimulus train that is written to the WAV
%           file
% TOUT:     Timing OUT (TOUT), this is a double array with the sample
%           number when codes in COUT are embedded in the WAV file.
% COUT:     Code OUT (COUT), this is a cell array of codes embedded in the
%           WAV file.
ASTIM=[]; 
TOUT=[];
COUT={};
for j=1:size(CIND{1},1)
    for i=1:length(CIND)
        ind=find(LEDo{i}>=CIND{i}(j,1),1,'first'):find(LEDo{i}<=CIND{i}(j,2),1,'last');
        ledo=LEDo{i}(ind);        
        leds=LEDs{i}(ind,:);
        
        % Note that we use CIND{i}(j,1) as a reference here, otherwise the
        % codes that are not at sound onset lose their alignment within the
        % stimulus train.
        ledo=ledo-CIND{i}(j,1)+1+length(ASTIM); 
        TOUT=[TOUT; ledo];
        for s=1:size(leds,1)
            COUT{end+1}=leds(s,:); 
        end % s
        ASTIM=[ASTIM; OUT{i}(CIND{i}(j,1):CIND{i}(j,2),:)];        
    end %
end % i

if isempty(ASTIM)
    for i=1:size(OUT)
        ASTIM=[ASTIM; OUT{i}]; 
    end % i
end % if 



%% EMBED CODES AND WRITE FILE + CUES
%   Embed them by default, but if they aren't necessary, then the user can
%   opt to disable them. Could save time when many codes are embedded.
if ADDCUE && WRITE
    %% WRITE WAV FILE
    wavwrite(ASTIM, FS, '../stims/ASTIM.wav');
    if max(TOUT)>length(ASTIM), error('STIMULUS IS TOO SHORT TO EMBED CODES!'); end
    addWavCue('../stims/', 'ASTIM.wav', TOUT, COUT, 'ASTIM_cue.wav'); 
elseif WRITE % only if we need to write
    wavwrite(ASTIM, FS, '../stims/ASTIM_cue.wav'); 
end % ADDCUE