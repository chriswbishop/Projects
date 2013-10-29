function [gRIGHT_GAZE_X gRIGHT_GAZE_Y gRIGHT_IN_BLINK gRIGHT_IN_SACCADE gAVERAGE_SACCADE_AMPLITUDE gBLINK_COUNT gFIXATION_COUNT gSACCADE_COUNT gSMP_BLINK_COUNT gSMP_SACCADE_COUNT ]=MSPE_EEG_ET_group(SID, PFLAG)
%% DESCPRIPTION:
%
%   Function to compile group data and generate group plots for
%   eye-tracking data.  
%
% INPUT:
%
%   SID:    SxM character matrix, with each row corresponding to a specific
%           subject ID (e.g. SID=strvcat('s2607', 's2608', ...); 
%
%   PFLAG:  Integer, flag to indicate level of plotting detail. 
%               0:  No plotting
%               ~0:  All group plots
%
% OUTPUT:
%
%   gRIGHT_GAZE_X:  T x C x R x S data matrix, where T is the number of
%                   time bins, C is the number of conditions, R is the
%                   number of response possibilities, and S is the number
%                   of subjects.  Recall that the response index (dimension
%                   R) is incremented 1 to allow us to save data for MISS
%                   trials (a 0 response in log files).  Data are stored as
%                   VISUAL ANGLE. Importantly, the T dimension may not
%                   match an individual's RIGHT_GAZE_X because we may clip
%                   the data here while importing it to simplify our
%                   analysis. 
%
%   gRIGHT_GAZE_Y:  Same as gRIGHT_GAZE_X, but with Y information.
%
%   gRIGHT_IN_BLINK:    Same dimensions as gRIGHT_GAZE_X, but with binary
%                       data indicating whether the right eye is in a blink
%                       (1) or not (0).  
%
%   gRIGHT_IN_SACCADE:  Similar to gRIGHT_IN_SACCADE, but binary time
%                       series indicates whether the right eye is in a
%                       saccade (1) or not (0). 
%
%   gAVERAGE_SACCADE_AMPLITUDE: 1xCxRxS, where C,R,S defined as for
%                               gRIGHT_GAZE_X.  Data are the average
%                               saccade amplitude (in degrees) for a given
%                               trial recorded by the eye-tracker software.
%                               Recall that these data are based on the
%                               data from all data recorded during the
%                               trial (i.e. not only during the time window
%                               of interest). So, not necessarily the best
%                               metric. 
%
%   gBLINK_COUNT:   Same dimensions as gAVERAGE_SACCADE_AMPLITUDE, except
%                   data reflect the total blink count during a trial.
%                   These data are based on the output from the TRIAL
%                   REPORT (i.e. the entire duration of the trial is used
%                   in calculating this instead of the specified time
%                   window).  See also gSMP_BLINK_COUNT, which is based off
%                   of the SAMPLE REPORT.
%
%   gFIXATION_COUNT:    XXX
%
%   gSACCADE_COUNT: Same as gBLINK_COUNT, but for SACCADES.
%
%   gSMP_BLINK_COUNT:   Same as gBLINK_COUNT except based off of the SAMPLE
%                       REPORT, which typically gives a more conservative
%                       (and accurate) estimate of relevant blinks.  
%
%   gSMP_SACCADE_COUNT: Same as gSMP_BLINK_COUNT, but for saccades.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
MSPE_DEFS;
% C=[1:4 7 8 24 25]; 
C=[1 3]; 
% Default analysis time. 
SMP_ANAL_TIME=[0 200];
% SMP_RATE = 1000;
% SMP_ANAL_SMPS=(SMP_ANAL_TIME*SMP_RATE)/1000;

% Borrowed from ERPLAB's ploterps.m.
colorDef =['k  ';'r  ';'b  ';'g  ';'c  ';'m  '];
styleDef ={'- ';'- ';'- ';'- ';'- ';'- ';'-.';'-.';'-.';'-.';'-.';'-.';...
      '--';'--';'--';'--';'--';'--';': ';': ';': ';': ';': ';': '};
styleDef = repmat(styleDef, 7,1);  % Until 168 bins
colorDef = repmat(colorDef, 28,1); % Until 168 bins

% C=[1 3]; 
if ~exist('PFLAG', 'var') || isempty(PFLAG), PFLAG=1; end % plot flag.

%% GROUP VARIABLES
%   See help for details
gRIGHT_GAZE_X=[]; 
gRIGHT_GAZE_Y=[];
gRIGHT_IN_BLINK=[];
gRIGHT_IN_SACCADE=[]; 
gAVERAGE_SACCADE_AMPLITUDE=[];
gBLINK_COUNT=[];
gFIXATION_COUNT=[];
gSACCADE_COUNT=[];
gSMP_BLINK_COUNT=[];
gSMP_SACCADE_COUNT=[]; 

%% COMPILE DATA
for s=1:size(SID,1)
    
    %% LOAD SAVED DATA
    sid=deblank(SID(s,:));  
    load([sid '_ET']); 

    %% GAZE POSITION
    %   Convert GAZE (Pixels) to visual angle, assuming 120 cm from eyes to
    %   screen and screen size of 52 cm side to side and 32.5 cm from top
    %   to bottom of the display surface. Screen resolution assumed to be
    %   1920x1200 pixels
    %
    %   For some of these details, see:
    %
    %       Bishop, C. W., S. London, et al. (2011). "Visual influences
    %       on echo suppression." Curr Biol 21(3): 221-225.
    %
    %   Also, subtract the middle of the screen so (0,0) is in the center
    %   of the screen. 
    RIGHT_GAZE_X(:,:,:)=atan( ((RIGHT_GAZE_X-960).*(52/1920))./120 ) .* 180/pi; 
    RIGHT_GAZE_Y(:,:,:)=(atan( ((RIGHT_GAZE_Y-600).*(52/1920))./120 ) .* 180/pi).*-1; % maybe need to invert sign here? 
    SMP_ANAL_SMPS=[find(SMP_TIME>=SMP_ANAL_TIME(1), 1, 'first') find(SMP_TIME>=SMP_ANAL_TIME(2), 1, 'first')];
    
    % Assign to group variables and clear
    gRIGHT_GAZE_X(:,:,:,s)=RIGHT_GAZE_X(SMP_ANAL_SMPS(1):SMP_ANAL_SMPS(2),:,:);
    gRIGHT_GAZE_Y(:,:,:,s)=RIGHT_GAZE_Y(SMP_ANAL_SMPS(1):SMP_ANAL_SMPS(2),:,:);
    clear RIGHT_GAZE_X RIGHT_GAZE_Y;
    
    %% BLINK DATA    
    % Assign to group variables and clear
    gRIGHT_IN_BLINK(:,:,:,s)=RIGHT_IN_BLINK;
    gBLINK_COUNT(:,:,:,s)=BLINK_COUNT;  
    gSMP_BLINK_COUNT(:,:,:,s)=SMP_BLINK_COUNT;
    clear RIGHT_IN_BLINK BLINK_COUNT SMP_BLINK_COUNT;
    
    %% SACCADE DATA    
    % Assign to group variables and clear
    gRIGHT_IN_SACCADE(:,:,:,s)=RIGHT_IN_SACCADE; 
    gAVERAGE_SACCADE_AMPLITUDE(:,:,:,s)=AVERAGE_SACCADE_AMPLITUDE; %#ok<*AGROW>
    gSACCADE_COUNT(:,:,:,s)=SACCADE_COUNT(:,:,:); 
    gSMP_SACCADE_COUNT(:,:,:,s)=SMP_SACCADE_COUNT(:,:,:);  %#ok<*NODEF>
    clear RIGHT_IN_SACCADE AVERAGE_SACCADE_AMPLITUDE SACCADE_COUNT SMP_SACCADE_COUNT;     
    
end % for s=1: ...

%% DATA TYPES ARE IN PAIRS, NEED TO COLLAPSE ACROSS SIDES
%
%   This makes group figures a lot easier to look at when not all subjects
%   have the same leading side condition (i.e. in pretty much all of our
%   MSPE_EEG experiments) 
for c=[1:2:13 16:2:24] % average over the just the pairs, recall that 15 is a BLANK (obnoxious in hindsight)        
    
    %%  GAZE INFORMATION
    
    % X
    gRIGHT_GAZE_X(:,c+1,:,:)=gRIGHT_GAZE_X(:,c+1,:,:).*-1; % change direction of one side.
    gRIGHT_GAZE_X(:,c,:,:)=nanmean(gRIGHT_GAZE_X(:,[c c+1],:,:),2); % change direction of one side.
    gRIGHT_GAZE_X(:,c+1,:,:)=nan(size(gRIGHT_GAZE_X(:,c+1,:,:))); % replace data with NaNs.
    
    % Y    
    %   Whoops, we don't need to flip the Y-axis for these guys, just the
    %   x-axis so we can plot towards primary and away from primary. 
%     gRIGHT_GAZE_Y(:,c+1,:,:)=gRIGHT_GAZE_Y(:,c+1,:,:).*-1; % change direction of one side.
    gRIGHT_GAZE_Y(:,c,:,:)=nanmean(gRIGHT_GAZE_Y(:,[c c+1],:,:),2); % change direction of one side.
    gRIGHT_GAZE_Y(:,c+1,:,:)=nan(size(gRIGHT_GAZE_Y(:,c+1,:,:))); % replace data with NaNs.
    
    %% BLINK INFORMATION
    %   Don't need to invert sign, just collapse across sides. 
    gRIGHT_IN_BLINK(:,c,:,:)=nanmean(gRIGHT_IN_BLINK(:,[c c+1],:,:),2); % Average
    gRIGHT_IN_BLINK(:,c+1,:,:)=nan(size(gRIGHT_IN_BLINK(:,c+1,:,:))); % wipe out redundant info
    
    gBLINK_COUNT(:,c,:,:)=nanmean(gBLINK_COUNT(:,[c c+1],:,:),2); % Average
    gBLINK_COUNT(:,c+1,:,:)=nan(size(gBLINK_COUNT(:,c+1,:,:))); % wipe out redundant info
    
    gSMP_BLINK_COUNT(:,c,:,:)=nanmean(gSMP_BLINK_COUNT(:,[c c+1],:,:),2); % Average
    gSMP_BLINK_COUNT(:,c+1,:,:)=nan(size(gSMP_BLINK_COUNT(:,c+1,:,:))); % wipe out redundant info
    
    %% SACCADE INFORMATION
    gRIGHT_IN_SACCADE(:,c,:,:)=nanmean(gRIGHT_IN_SACCADE(:,[c c+1],:,:),2); % Average
    gRIGHT_IN_SACCADE(:,c+1,:,:)=nan(size(gRIGHT_IN_SACCADE(:,c+1,:,:))); % wipe out redundant info
    
    gSACCADE_COUNT(:,c,:,:)=nanmean(gSACCADE_COUNT(:,[c c+1],:,:),2); % Average
    gSACCADE_COUNT(:,c+1,:,:)=nan(size(gSACCADE_COUNT(:,c+1,:,:))); % wipe out redundant info
    
    gSMP_SACCADE_COUNT(:,c,:,:)=nanmean(gSMP_SACCADE_COUNT(:,[c c+1],:,:),2); % Average
    gSMP_SACCADE_COUNT(:,c+1,:,:)=nan(size(gSMP_SACCADE_COUNT(:,c+1,:,:))); % wipe out redundant info
end % c

%% PLOT AVERAGE GAZE POSITION vs. TIME
%   Need this broken down by each condition/response.
%
%   NOTE: Would also be useful to see summary plots ignoring time (just an
%   X-Y plane with average gaze position over trials. 
%
%   ALSO! It would be a MISTAKE to simply average across left and right
%   leading, as any predictive change might cancel out.  SO, will need to
%   flip the azimuthal angle of one of them BEFORE combining the data.
if PFLAG~=0
    
    % New Figure
    figure, hold on;
    
    % Get X/Y Gaze Data
    X=nanmean(gRIGHT_GAZE_X,4); 
    Y=nanmean(gRIGHT_GAZE_Y,4); 
    
    % Standard error.
    SX=nanstd(gRIGHT_GAZE_X,0,4)./sqrt(size(gRIGHT_GAZE_X,4)); 
    SY=nanstd(gRIGHT_GAZE_Y,0,4)./sqrt(size(gRIGHT_GAZE_Y,4));
    
    % Plot in 3D. 
    plot3(SMP_TIME(SMP_ANAL_SMPS(1):SMP_ANAL_SMPS(2)), X(:,C,2), Y(:,C,2), 'linewidth', 2); % suppressed
    plot3(SMP_TIME(SMP_ANAL_SMPS(1):SMP_ANAL_SMPS(2)), X(:,C,3), Y(:,C,3), '--', 'linewidth', 2); % not suppressed 
    
    % Mark up figure. 
    legend(rCOND(C));  
    axis([min(SMP_TIME(SMP_ANAL_SMPS(1):SMP_ANAL_SMPS(2))) max(SMP_TIME(SMP_ANAL_SMPS(1):SMP_ANAL_SMPS(2))) -12.5 12.5 -8 8]); % axes set at screen size.
    xlabel('Time (msec)'); 
    ylabel('GAZE\_X (degres; (+)Towards Primary)'); 
    zlabel('GAZE\_Y (degrees)'); 
    title(['Gaze Position - Time Course (N=' num2str(size(gRIGHT_GAZE_X,4)) ')']); 
    set(gca, 'YGrid', 'on', 'XGrid', 'on', 'ZGrid', 'on');
end % PFLAG


%% AVERAGE GAZE POSITION (averaged over time)
%   I think this is a helpful plot to see if there are any obvious
%   differences in gaze behavior in a condtion or percept across subjects.
%   
%   Relies on errorbarxy, a function I downloaded from MATLAB CENTRAL
%   http://www.mathworks.com/matlabcentral/fileexchange/4065
%       I modified line 24 to be this 'plot(x,y,['s' linecol])'. 
if PFLAG~=0
    
    % Start a new Figure
    figure, hold on    
    
    % Average over first dimension (time) of matrix
    X=((nanmean(gRIGHT_GAZE_X(:,:,:,:),1))); 
    Y=((nanmean(gRIGHT_GAZE_Y(:,:,:,:),1)));
    
    % Find Standard Error of the Mean (SEM).
    SX=squeeze(nanstd(X,0,4))./sqrt(size(X,4));
    SY=squeeze(nanstd(Y,0,4))./sqrt(size(Y,4)); 
    
    % Average over Subjects
    X=squeeze(nanmean(X,4));
    Y=squeeze(nanmean(Y,4));
    
    % Plot Means
    plot(X(C,2), Y(C,2), 'b^'); % suppressed
    plot(X(C,3), Y(C,3), 'rs');    
    
    % Plot XY errorbars
    errorbarxy(X(C,2), Y(C,2), SX(C,2), SY(C,2), [], [], 'b', 'b'); 
    errorbarxy(X(C,3), Y(C,3), SX(C,3), SY(C,3), [], [], 'r', 'r');    
    
    % Markup figure
    legend('TL', 'OL'); 
    xlabel('RIGHT\_GAZE\_X (degrees)');
    ylabel('RIGHT\_GAZE\_Y (degrees)');
    title(['Average Gaze Position (N=' num2str(size(gRIGHT_GAZE_X,4)) ')']);
    set(gca,'XGrid','on','YGrid','on'); 
    axis([-12.5 12.5 -8 8]);    
    
end % PFLAG


%% BLINK FREQUENCY vs. TIME
if PFLAG~=0
%     C=[1 3]; 
    
    % Open new figure
    figure, hold on
    
    % Average over subjects
    X=nanmean(gRIGHT_IN_BLINK,4);    
    
    % Standard error of mean (SEM) 
    SX=nanstd(gRIGHT_IN_BLINK,0,4)./sqrt(size(gRIGHT_IN_BLINK,4)); 
    
    % Plot data
    %   Confidence intervals would also be helpful
    plot(SMP_TIME, X(:,C,2)); 
    plot(SMP_TIME, X(:,C,3), '--');   
    
    % Markup
    %   Should we set the axis?
    legend(rCOND{C}); 
    xlabel('Time (msec)'); 
    ylabel('Average Blink Frequency (BLINKS/TRIAL)');
    title(['Blink Frequency vs Time (N=' num2str(size(gRIGHT_IN_BLINK,4)) ')']);    
    
end % PFLAG

%% BLINK FREQUENCY SUMMARY (BASED ON TRIAL REPORT)
%   I had to grab this information from the Trial Report because it was
%   really easily available there.  However, it does leave out some
%   important information, like "when does the blink occur?" It also
%   doesn't let me pick a time window for analysis, it's averaged over the
%   whole data collection period.  This isn't the best solution because we
%   only really care about blinks at or near stimulus presentation time.
%   So, to that extent, the time-average information might actually be more
%   useful from an interpretational standpoint.  
if PFLAG~=0
    C=[1 3];
    figure, hold on;
    
    % Average over subjects
    X=nanmean(gBLINK_COUNT,4); 
    
    % SEM
    SX=nanstd(gBLINK_COUNT,0,4)./sqrt(size(gBLINK_COUNT,4)); 
    
    % Plot
    errorbar(C, X(:,C,2), SX(:,C,2), 'bs-');
    errorbar(C, X(:,C,3), SX(:,C,3), 'r^--');    
    
    % Markup Figure    
    xlabel('Condition');
    ylabel('Blink Count Average (Blinks/Trial)'); 
    set(gca, 'XTick', C); 
    set(gca, 'XTickLabel', rCOND(C)); 
    title(['Average Blink Frequency (Trial Report; N=' num2str(size(gBLINK_COUNT,4)) ')']);
    legend('show'); % need to refine this, just not sure how
end % PFLAG

%% BLINK FREQUENCY SUMMARY (BASED ON SAMPLE REPORT)
%   I devised a different way to count up saccade and blink events using
%   the SAMPLE REPORT data.  Specifically, I look for change in the
%   RIGHT_IN_BLINK and RIGHT_IN_SACCADE variables within each trial and
%   count up how many events there are. The advantage of such a method is
%   that we can feed the change detection script (ET_DETECT_CHANGE.m) a
%   time course of states (e.g. 0 for no blink, 1 for in blink) and count
%   up how many times a change is detected (from no blink to a blink, or
%   vice versus).  The cool thing is that we can trim these data however we
%   want (e.g. based on the sample time) and count up events within the
%   trimmed data.  This makes it super easy to look for events within a
%   specified time window. 
if PFLAG~=0
    
    C=[1 3]; 
    figure, hold on
    
    % Average over subjects
    X=nanmean(gSMP_BLINK_COUNT,4); 
    
    % SEM
    SX=nanstd(gSMP_BLINK_COUNT,0,4)./sqrt(size(gSMP_BLINK_COUNT, 4));
    
    % Plot it out     
    errorbar(C, X(:,C,2), SX(:,C,2), 'bs-');
    errorbar(C, X(:,C,3), SX(:,C,3), 'r^--');     
    
    % Markup Figure    
    xlabel('Condition');
    ylabel('Blink Count Average (Blinks/Trial)'); 
    set(gca, 'XTick', C); 
    set(gca, 'XTickLabel', rCOND(C)); 
    title(['Average Blink Frequency (Sample Report; N=' num2str(size(gBLINK_COUNT,4)) ')']);
    legend('show'); % need to refine this, just not sure how
end % PFLAG

%% SACCADE Frequency vs. Time
if PFLAG~=0
    C=[1 3];
    
    % Open new figure
    figure, hold on
    
    % Average over subjects
    X=nanmean(gRIGHT_IN_SACCADE,4);    
    
    % Standard error of mean (SEM) 
    SX=nanstd(gRIGHT_IN_SACCADE,0,4)./sqrt(size(gRIGHT_IN_SACCADE,4)); 
    
    % Plot data
    %   Confidence intervals would also be helpful
    plot(SMP_TIME, X(:,C,2)); 
    plot(SMP_TIME, X(:,C,3), '--');    
    
    % Markup
    legend(rCOND{C}); 
    xlabel('Time (msec)'); 
    ylabel('Average Saccade Frequency (SACCADES/TRIAL)');
    title(['Saccade Frequency vs. Time (N=' num2str(size(gRIGHT_IN_SACCADE,4)) ')']);    
end % PFLAG

end % MSPE_EEG_ET_group

