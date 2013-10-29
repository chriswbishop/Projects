function [OUT ORDER]=PEABR_session(IN, RP, T, MIXUP)
%% DESCRIPTION:
%
%   Generate stimulus presentation order for PEABR experiment.  The real
%   workhorse here is actually MSPE_session, which handles the
%   randomization, etc.  As with MSPE_session, the user can impose
%   restrictions on the number of consecutive stimulus attributes (rows of
%   IN).  There are a few added features here, including being able to
%   independently shuffle and interleave different stimulus configurations.
%   Basically, each row of the cell array IN is shuffled independently of
%   all other rows. Presentation ORDER is then constructed by interleaving
%   the shuffled rows.  
%
%   Importantly, this code requires each element of IN to have a unique
%   condition code. If members of IN share condition codes, then it will
%   break. 
%
% INPUT:
%
%   IN:     cell array of stimulus attributes to shuffle.  
%   RP:     cell array of pseudorandomization specifications
%   T:      integer, threshold (default T=1).  The THRESHOLD value stored
%           in the IN stimulus parameters are scaled by T.  1 means no
%           scaling. 
%   MIXUP:  integer, specifies the type of randomization employed.  
%           Three different levels of randomization used here. 
%               0: No randomization at all.
%               1: Randomization as it is normally done across trials
%               2: Randomization across trial TYPES. This is only intended to
%               be used if IN is a 1xN cell array (that is, we aren't
%               interleaving different trial types). This is the least
%               tested parameter, so use with caution. 
%
% OUTPUT:
%   
%   OUT:    Cell array of all stimulus configurations.  All elements of IN
%           are concatenated into a single cell array, OUT, which is then
%           indexed by ORDER.
%   ORDER:  integer array, indices into OUT stimulus configuration. This
%           specifies the order in which to play stimuli.
%
% EXAMPLE 1:
% 
%   In this example, I configure IN to play stimuli at with multiple,
%   obvious doubles ([2:2:18]) mixed with enough obvious singles to get 20 
%   stims per train, at various volume levels ([0 0.03]) and 
%   with a varying number of breaks ([0 1]).  These stimulus configurations
%   are specified in the first ROW of IN (IN{1,:}).  
%
%   These mixes of obvious singles and obvious doubles will be interleaved
%   with lead/lag-only stimuli, specified in IN{2,1} and IN{2,2}.  
%
%   NOTE: These have a -1 msec CODE OFFSET to compensate for a 1 msec
%   offset hard coded into MSPE_stim, which is (again) the work horse of
%   PEABR_stim. 
%
% N=2:2:18; L=[0.03]; B=[0 1];
% for n=1:length(N)
%   for q=1:length(L)
%       for b=1:length(B)
%           IN{1,end+1}=[[L(q);1;0.03;0;L(q)+100*N(n)+B(b);0.15;0.25;N(n);B(b);0;-0.001;2] [0;1;0.03;0;(L(q))+100*N(n)+B(b);0.15;0.25;20-N(n);B(b);0;-0.001;2]];
%       end
%   end
% end
%
% IN{2,1}=[0;1;0.03;0;201;0.15;0.25;10;1;1;-0.001;18];
% IN{2,2}=[1;0;0.03;0;202;0.15;0.25;10;1;1;-0.001;18];
%
%
% EXAMPLE 2:
%
%   This example is one of my first attempts at creating ABR quality
%   stimuli for this experiment.  Basically, we have the standard lead-lag
%   auditory pairs set at 0.004 sec (4 msec) echo delay.  We then have lead
%   then lag and lag then lead breakdown stimulus trains.  All of these are
%   counterphased as well.  The VCODES are set such that each stimulus is
%   given a unique code based on if it's lead-only, lag-only, or lead-lag,
%   it's position in the train (at least for lead-only and lag-only...need
%   to fix this for lead-lag pairs, my bad). 
% 
% %% CREATE LEAD-LAG PAIRS, POSITIVE AMPLITUDE
% LL=[51:70];
% tmp=[];
% for i=1:length(LL)
%   tmp=[tmp [1;1;0.004;100+LL(i);51;0.15;0.25;1;0;0;0.00005;14]];
% end
% IN{1,1}=tmp;
% 
% %% CREATE LEAD-LAG PAIRS, NEGATIVE AMPLITUDE
% LL=[71:90];
% tmp=[];
% for i=1:length(LL)
%   tmp=[tmp [1;1;0.004;100+LL(i);52;0.15;0.25;1;0;0;0.00005;14]];
% end
% IN{1,2}=tmp;
% 
% %% CREATE LEAD- then LAG-ONLY STIMULUS TRAIN, POSITIVE AMPLITUDE
% tmp=[];
% LEAD=[101:110]; LAG=[211:220];
% for d=1:length(LEAD)
%   tmp=[tmp [0;1;0.004;1000+LEAD(d);151;0.15;0.25;1;0;0;0.00005;7]];
% end
% for g=1:length(LAG)
%   tmp=[tmp [1;0;0.004;1000+LAG(g);151;0.15;0.25;1;0;0;0.00005;7]];
% end
% IN{2,1}=tmp;tmp=[];
% 
% %% CREATE LEAD- then LAG-ONLY STIMULUS TRAIN, NEGATIVE AMPLITUDE
% LEAD=[121:130]; LAG=[231:240];
% for d=1:length(LEAD)
%   tmp=[tmp [0;-1;0.004;1000+LEAD(d);152;0.15;0.25;1;0;0;0.00005;7]];
% end
% for g=1:length(LAG)
%   tmp=[tmp [-1;0;0.004;1000+LAG(g);152;0.15;0.25;1;0;0;0.00005;7]];
% end
% IN{2,2}=tmp;
% 
% %% CREATE LAG- then LEAD-ONLY STIMULUS TRAIN, POSITIVE AMPLITUDE 
% tmp=[];
% LEAD=[111:120]; LAG=[201:210];
% for g=1:length(LAG)
%   tmp=[tmp [1;0;0.004;1000+LAG(g);251;0.15;0.25;1;0;0;0.00005;7]];
% end
% for d=1:length(LEAD)
%   tmp=[tmp [0;1;0.004;1000+LEAD(d);251;0.15;0.25;1;0;0;0.00005;7]];
% end
% IN{2,3}=tmp;
% 
% %% CREATE LAG- then LEAD-ONLY STIMULUS TRAIN, NEGATIVE AMPLITUDE 
% tmp=[];
% LEAD=[131:140]; LAG=[221:230];
% for g=1:length(LAG)
%   tmp=[tmp [-1;0;0.004;1000+LAG(g);252;0.15;0.25;1;0;0;0.00005;7]];
% end
% for d=1:length(LEAD)
%   tmp=[tmp [0;-1;0.004;1000+LEAD(d);252;0.15;0.25;1;0;0;0.00005;7]];
% end
% IN{2,4}=tmp;
%
%
%% EXAMPLE 3:
%
%   This is almost identical to Example 2, except there's a dummy "sound"
%   at the beginning of the train that is there to account for some slop in
%   the alignment between the port codes and sound output that only affects
%   the first sound in the stimulus train.  For further discussion, see the
%   URL below:
%
%       http://www.neurobs.com/menu_support/menu_forums/view_thread?id=6937
%
%   I also reduced the playback volume from 1 to 0.98 (0.17 dB quieter) to
%   avoid a warning I was getting Presentation suggesting that the sounds
%   were being clipped or "too loud" to play.
%
% % CREATE LEAD-LAG PAIRS, POSITIVE AMPLITUDE
% LL=[51:70];
% tmp=[];
% for i=1:length(LL)
% tmp=[tmp [0.98;0.98;0.004;100+LL(i);51;0.15;0.25;1;0;0;0.00005;14]];
% end
% tmp=[[0;0;tmp(3);10;tmp(5);0;0;1;0;0;tmp(11);tmp(end)] tmp];
% IN{1,1}=tmp;
% 
% 
% %% CREATE LEAD-LAG PAIRS, NEGATIVE AMPLITUDE
% LL=[71:90];
% tmp=[];
% for i=1:length(LL)
%   tmp=[tmp [-0.98;-0.98;0.004;100+LL(i);52;0.15;0.25;1;0;0;0.00005;14]];
% end
% tmp=[[0;0;tmp(3);10;tmp(5);0;0;1;0;0;tmp(11);tmp(end)] tmp];
% IN{1,2}=tmp;
% 
% %% CREATE LEAD- then LAG-ONLY STIMULUS TRAIN, POSITIVE AMPLITUDE
% tmp=[];
% LEAD=[101:110]; LAG=[211:220];
% for d=1:length(LEAD)
%   tmp=[tmp [0;0.98;0.004;1000+LEAD(d);151;0.15;0.25;1;0;0;0.00005;7]];
% end
% for g=1:length(LAG)
%   tmp=[tmp [0.98;0;0.004;1000+LAG(g);151;0.15;0.25;1;0;0;0.00005;7]];
% end
% tmp=[[0;0;tmp(3);10;tmp(5);0;0;1;0;0;tmp(11);tmp(end)] tmp];
% IN{2,1}=tmp;tmp=[];
% 
% %% CREATE LEAD- then LAG-ONLY STIMULUS TRAIN, NEGATIVE AMPLITUDE
% LEAD=[121:130]; LAG=[231:240];
% for d=1:length(LEAD)
%   tmp=[tmp [0;-0.98;0.004;1000+LEAD(d);152;0.15;0.25;1;0;0;0.00005;7]];
% end
% for g=1:length(LAG)
%   tmp=[tmp [-0.98;0;0.004;1000+LAG(g);152;0.15;0.25;1;0;0;0.00005;7]];
% end
% tmp=[[0;0;tmp(3);10;tmp(5);0;0;1;0;0;tmp(11);tmp(end)] tmp];
% IN{2,2}=tmp;
% 
% %% CREATE LAG- then LEAD-ONLY STIMULUS TRAIN, POSITIVE AMPLITUDE 
% tmp=[];
% LEAD=[111:120]; LAG=[201:210];
% for g=1:length(LAG)
%   tmp=[tmp [0.98;0;0.004;1000+LAG(g);251;0.15;0.25;1;0;0;0.00005;7]];
% end
% for d=1:length(LEAD)
%   tmp=[tmp [0;0.98;0.004;1000+LEAD(d);251;0.15;0.25;1;0;0;0.00005;7]];
% end
% tmp=[[0;0;tmp(3);10;tmp(5);0;0;1;0;0;tmp(11);tmp(end)] tmp];
% IN{2,3}=tmp;
% 
% %% CREATE LAG- then LEAD-ONLY STIMULUS TRAIN, NEGATIVE AMPLITUDE 
% tmp=[];
% LEAD=[131:140]; LAG=[221:230];
% for g=1:length(LAG)
%   tmp=[tmp [-0.98;0;0.004;1000+LAG(g);252;0.15;0.25;1;0;0;0.00005;7]];
% end
% for d=1:length(LEAD)
%   tmp=[tmp [0;-0.98;0.004;1000+LEAD(d);252;0.15;0.25;1;0;0;0.00005;7]];
% end
% tmp=[[0;0;tmp(3);10;tmp(5);0;0;1;0;0;tmp(11);tmp(end)] tmp];
% IN{2,4}=tmp;
% 
%
%% EXAMPLE 4:
%
%   This is an example of how to create a session with variable ISIs and
%   various lead-lag delays.  Originally intended for use in Exp01D 
%   (PEABR_07.mat).
%
% D=[0.001:0.002:0.013]; % Lead-Lag Delay
% R=[1 2.5 6.25]; % Rate (Hz)
% IN={};
% for d=1:length(D)
%   for r=1:length(R)+1
%       if r<=length(R)
%           tmp=[0.98;0.98;D(d);1000+100*r+D(d)*1000;100*r+D(d)*1000;1/R(r);1/R(r);20;0;0;-0.001;1];
%       else
%           tmp=[0.98;0.98;D(d);1000+100*r+D(d)*1000;100*r+D(d)*1000;1/R(end);1/R(1);20;0;0;-0.001;1];
%       end
%       IN{end+1}=tmp;
%   end
% end
% 
%% EXAMPLE 5
%
%   An example used in Experiment 01D Training (TR06)
%
% R=6.25
% N=2:2:18;
% L=[0.1 0.98];
% D=0.03;
% IN={};
% for n=1:length(N)
%   for q=1:length(L)
%       tmp=[[L(q);0.98;D;1200+L(q)+N(n);1200+L(q)+N(n);1/R(end);1/R(1);N(n);0;0;-0.001;1] [[0;0.98;D;1200+L(q)+N(n);1200+L(q)+N(n);1/R(end);1/R(1);20-N(n);0;0;-0.001;1]]];
%       IN{1,end+1}=tmp;
%   end
% end
%
%% EXAMPLE 06:
%
%   This is the code used to construct TR05.  
%
% R=5.0
% N=2:2:18;
% L=[0.1 0.98];
% D=0.03;
% IN={};
% for n=1:length(N)
%   for q=1:length(L)
%       tmp=[[L(q);0.98;D;1200+L(q)+N(n);1200+L(q)+N(n);1/R(end);1/R(1);N(n);0;0;-0.001;1] [[0;0.98;D;1200+L(q)+N(n);1200+L(q)+N(n);1/R(end);1/R(1);20-N(n);0;0;-0.001;1]]];
%       IN{2,end+1}=tmp;
%   end
% end
% IN{1,1}=[0;0.98;D;1201+N(n);201;1/R(end);1/R(1);20;0;0;-0.001;6]; IN{1,2}=[0.98;0;D;1202+N(n);202;1/R(end);1/R(1);20;0;0;-0.001;6]; IN{1,3}=[0;0;D;1203+N(n);203;1/R(end);1/R(1);20;0;0;-0.001;6]; 
%   
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
%   T (threshold scaling factor): set to 1 (use whatever is in the mat
%   files) by default
%   MIXUP:  Flag, type of pseudorandomization employed. See help for
%           details
if ~exist('T', 'var') || isempty(T), T=1; end
if ~exist('MIXUP', 'var') || isempty(MIXUP), MIXUP=1; end 

%% OK, so IN is going to be a CELL array for this experiment, which makes
%% it really difficult to mess with things.  So, first thing is to reduce
%% things down to correct dimensions for MSPE_session 
for j=1:size(IN,1)
    in=[];
    for i=1:size(IN,2)
        if ~isempty(IN{j,i})
            in(:,i)=IN{j,i}(:,1); % grab first column since it will have similar code information
        end % if ~isempty
    end % for i
    
    % Grab condition codes
    COND=in(5,:); 
    
    %% MIX UP TRIALS
    %   Three different levels of randomization used here. 
    %       0: No randomization at all.
    %       1: Randomization as it is normally done across trials
    %       2: Randomization across trial TYPES. This is only intended to
    %       be used if IN is a 1xN cell array (that is, we aren;t
    %       interleaving different trial types). 
    if MIXUP==0
        out=MSPE_session(in, RP{j}, T, false);     
    elseif MIXUP==1
        out=MSPE_session(in, RP{j}, T, true);             
    elseif MIXUP==2            
        % Mixup trial types here. This effectively randomizes different
        % trial types, but ensures that trial types are presented together
        % (e.g. like a little blocked design).
        rand('twister',sum(100*clock));
        I=randperm(size(in,2));
        in=in(:,I);
        
        % Don't mixup individual trials.
        out=MSPE_session(in, RP{j}, T, false); 
               
    end % if MIXUP    
    out=out(5,:);  % just grab condition codes. 
    
    % Now we have to tell the order of trial types to play...
    %   Note, this will buck if more than one entry has the same condition
    %   code (lame, I know, but I'm in a hurry). 
    for z=1:length(out)
        order{j}(z)=find(COND==out(z)); 
    end % z
    
end % j

%% MIX ORDER
%   For now, just interleave things. 
ORDER=[];
OFFSET=0;
for i=1:length(order{1})
    OFFSET=0; 
    for j=1:length(order)
       ORDER=[ORDER; order{j}(i)+OFFSET]; % just interleave all of them.       
       OFFSET=OFFSET+length(unique(order{j})); 
    end % j        
end % i

%% CONCATENATE ALL STIMULUS PARAMETERS INTO SINGLE CELL ARRAY
OUT={};
for j=1:size(IN,1)
    for i=1:size(IN,2)
        if ~isempty(IN{j,i})
            OUT{end+1}=IN{j,i};
            
            %% APPLY THRESHOLD VALUE
            OUT{end}(3,:)=OUT{end}(3,:).*T; 
            
        end % if ~isempty 
    end % i

end % j