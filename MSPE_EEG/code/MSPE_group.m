function [gSRATE gNRATE gRESP gRT rmSRATE rmNRATE SCON]=MSPE_group(SID, EXPID, F, IND)
%% DESCRIPTION:
%
%   This function creates figures at both the subject and group level.
%   
% INPUT:
%
%   SID:    string array, each row is a subject ID.
%   EXPID:  string, experiment ID (appended to subject ID)
%   F:      Flag, integer. If you want to plot the data, set F. If not,
%           set it to 0 (default).
%   IND:    integer matrix, conditions to analyze. 
%
% OUTPUT:
%
%   gSRATE: group structure for SRATE. gSRATE is a Cx2xS matrix, where C is
%           the number of conditions defined in MSPE_DEFS and S is the
%           number of subjects. gSRATE(:,1,:) is the number of ONE
%           LOCATION responses. gSRATE(:,2,:) is the total number of
%           responses (excludes misses, so not equivalent to the number of
%           trials). see MSPE_analysis for most accurate description.
%
%   gNRATE: group structure for NRATE. gNRATE is a CxNx2xS structure, where
%           C is the number of conditions defined by MSPE_DEFS, N is the
%           number of possible responses to the SIDE question (currently
%           left, right, or both), and S is the number of subjects. 
%
%   gRESP:
%   gSRT:   
%   rmSRATE:   Repeated measures ANOVA structure for SRATE. Each row is a
%              subject, each row is a condition. Conditions defined on an
%              experiment specific basis.
%   rmNRATE:   " " for NRATE 
%
%   FIGURES:
%
%       Figure 01:  
%       Figure 02:
%       Figure 03:
%       Figure 04:
%       Figure 05:
%
% Bishop, Chris Miller Lab 2010

% close all;

%% LOAD DEFAULTS
MSPE_DEFS;

if ~exist('F', 'var') || isempty(F), F=0; end 
if ~exist('IND', 'var') || isempty(IND), IND=1:length(rCOND); end 

%% DECLARE VARIABLES
gSRATE=[];
gNRATE=[];
gRESP=[];
gSRT=[];
gDTIME=[];
rmSRATE=[];
rmNRATE=[];
rmRESP=[];
rmRT=[];

for s=1:size(SID,1)
    sid=deblank(SID(s,:));
    
    % LOAD DATA
    
    for j=1:size(EXPID,1)
        load([sid deblank(EXPID(j,:))], 'SRATE', 'NRATE', 'RESP', 'RT');
        if j==1
            srate=zeros(size(SRATE))+SRATE;
            nrate=zeros(size(NRATE))+NRATE;
            resp=zeros(size(RESP))+RESP;
            rt=zeros(size(RT))+RT;
        else
            srate=srate+SRATE;
            nrate=nrate+NRATE;
            resp=resp+RESP;
            rt=rt+RT;
        end % j
    end % Allows us to collapse across multiple experimental conditions.
    
    % Reassign variables and clear temporary ones
    SRATE=srate(IND,:);
    NRATE=nrate(IND,:,:);
    RESP=resp(IND,:,:);
    RT=rt(IND,:,:);
    clear srate nrate resp rt;
    
    % INCLUDE IN GROUP MATRICES
    gSRATE(:,:,s)=SRATE;
    gNRATE(:,:,:,s)=NRATE;
    gRESP(:,:,:,s)=RESP;
    gRT(:,:,:,s)=RT;

    %% REPEATED MEASURES ANOVA
    %   Only the first 6 conditions are included in the RMANOVA.  The other
    %   6 conditions are control conditions that need not necessarily be
    %   subjected to the ANOVA.
    
    % FIRST FACTOR: Condition (3 levels)
    %   1:  Primary and Echo, no LED
    %   2:  Primary and Echo, LED on Primary side
    %   3:  Primary and Echo, LED on Echo Side
    for c=IND
        switch c
            %   1:  Primary and Echo, no LED
            case {1, 2}
                C=1;
            %   2:  Primary and Echo, LED on Primary side
            case {3, 4}
                C=2;
            %   3:  Primary and Echo, LED on Echo Side
            case {5, 6}
                C=3;
        end % switch
            
        % NRATE
        %   For NRATE, we need to know which of the three possible
        %   responses corresponds to a suppressed percept.  This switch
        %   controls that.
        %       ind:    response index (1=left, 2=both, 3=right)
        
        switch c
            %   Right leading
            case {1,3,5}
                ind=3;
            %   Left leading
            case {2,4,6}
                ind=1;
        end % switch
        
        % SECOND FACTOR: Side
        %   Suppression rates are grouped by a second (2 level) factor of
        %   side.  Side is either Left leading (1) or Right leading (2)
        %       1:  Left leading
        %       2:  Right Leading
        if rCOND{c}(1)=='L'
            S=1;
        elseif rCOND{c}(1)=='R'
            S=2;
        end % if
        
        rmSRATE=[rmSRATE; ...
            [squeeze(sum(SRATE(c,1)))./squeeze(sum(SRATE(c,2))) C S s]];
        rmNRATE=[rmNRATE; ...
            [squeeze(sum(NRATE(c,ind,1)))./squeeze(sum(NRATE(c,ind,2))) C S s]];
    end % c    
    
    clear SRATE NRATE RESP RT;
end % s

%% RESHAPE REPEATED MEASURES ANOVAs
%   Data must be in a specific format for Statistica.  This chunk of code
%   takes care of that.
%       Convert to SxC matrix, where S is the number of subjects, and C is
%       the number of conditions analyzed. 
rmNRATE=reshape(rmNRATE(:,1), length(IND), size(SID,1))';
rmSRATE=reshape(rmSRATE(:,1), length(IND), size(SID,1))';

%% PLOT SRATE
if F
    figure, hold on
    tmp=gSRATE(:,1,:)./gSRATE(:,2,:);
%     tmp=squeeze(tmp)-ones(size(squeeze(tmp),1),1)*squeeze(nanmean(tmp))';
    ndim=length(size(tmp));
    if ndim<3
        errorbar(1:size(gSRATE,1), squeeze(nanmean(tmp,ndim)), nanstd(tmp,0,ndim)./sqrt(size(tmp,ndim)), 'ks-');
        title(['Number of Objects vs. Condition (n=1)']);
    else
        errorbar(1:size(gSRATE,1), squeeze(nanmean(tmp,ndim)), nanstd(tmp,0,ndim)./sqrt(size(tmp,ndim)), 'ks-');
        title(['Number of Objects vs. Condition (n=' num2str(size(tmp,ndim)) ')']);
    end % if
    errorbar(1:size(gSRATE,1), squeeze(nanmean(tmp,ndim)), nanstd(tmp,0,ndim)./sqrt(size(tmp,ndim)), 'ks-');
    axis([0 size(tmp,1)+1 0 1.2])
    set(gca, 'XTick', 1:size(tmp,1))
    set(gca, 'XTickLabel', rCOND)
    set(gca, 'YTick', 0:0.1:1.2);
    set(gca, 'YTickLabel', 0:0.1:1.2);
    ylabel('% ONE');
    xlabel('Condition');
    clear tmp;
end % F

%% PLOT NRATE
if F
    figure, hold on
    tmp=gNRATE(:,:,1,:)./gNRATE(:,:,2,:);
    ndim=length(size(tmp)); 
    if ndim<3
        barweb(tmp, zeros(size(tmp)));
        title(['Side vs. Condition (n=1)']);
    else
        barweb(nanmean(tmp,ndim), nanstd(tmp,0,ndim)./sqrt(size(tmp,ndim)));
        title(['Side vs. Condition (n=' num2str(size(tmp,ndim)) ')']);
    end % if
    set(gca, 'XTickLabel', rCOND);
    legend('Left', 'Both', 'Right', 'location', 'best')
end % F

%% PLOT RESP
if F
    figure, hold on
    tmp=gRESP(:,:,1,:)./gRESP(:,:,2,:);
    ndim=length(size(tmp)); 
    if ndim<3
        barweb(tmp, zeros(size(tmp)));
        title(['Response Combination vs. Condition (n=1)']);
    else
        barweb(nanmean(tmp,ndim), nanstd(tmp,0,ndim)./sqrt(size(tmp,ndim)));
        title(['Response Combination vs. Condition (n=' num2str(size(tmp,ndim)) ')']);
    end % if
    set(gca, 'XTickLabel', rCOND);
    legend('OL', 'OB', 'OR', 'TL', 'TB', 'TR', 'location', 'best')
end % F

%% PLOT RT
if F
    figure, hold on
    tmp=gRT(:,:,1,:)./gRT(:,:,2,:);
    ndim=length(size(tmp)); 
    if ndim<3
        barweb(tmp, zeros(size(tmp)));
        title(['Reaction Time vs. Condition (n=1)']);
    else
        barweb(nanmean(tmp,ndim), nanstd(tmp,0,ndim)./sqrt(size(tmp,ndim)));
        title(['Reaction Time vs. Condition (n=' num2str(size(tmp,ndim)) ')']);
    end % if
    set(gca, 'XTickLabel', rCOND);
    ylabel('Reaction Time (msec)');
    xlabel('Condition');
    legend('OL', 'OB', 'OR', 'TL', 'TB', 'TR', 'location', 'best')
end % F

%% CONTEXT ANALYSIS
%   This should probably be done in MSPE_analysis, but I don't want to have
%   to recompile all the data for all my subjects. So, here it lives
%   forever.
try
    SCON=zeros(length(rCOND), length(rCOND), 2, 2, size(SID,1));
    for s=1:size(SID,1)
        load([deblank(SID(s,:)) EXPID], 'COND', 'NRESP'); 
        for i=2:length(COND)
            if NRESP(i)~=0 && NRESP(i-1)~=0
                SCON(COND(i), COND(i-1), NRESP(i-1), NRESP(i), s)=...
                    SCON(COND(i), COND(i-1), NRESP(i-1), NRESP(i), s)+1;
            end % NRESP(i)~=0
        end % i
        clear COND NRESP;
    end % s
end % try

%% PLOT CONTEXT ANALYSIS
if F
    SCON=SCON(IND,IND,:,:,:);
    figure, hold on
    for c=1:size(SCON,1)
        subplot(size(SCON,1)./2, 2, c); hold on
%         tmp=squeeze(SCON(c,:,1,1,:))'./squeeze(sum(squeeze((SCON(c,:,1,:,:))),2))';
        tmp=SCON(c,:,1,1,:)./sum(SCON(c,:,1,:,:),4);
        tmp1=SCON(c,:,2,2,:)./sum(SCON(c,:,2,:,:),4);
        
        if size(SCON,5)~=1
            tmp=squeeze(tmp)';
            tmp1=squeeze(tmp1)';
        end
        errorbar(1:size(SCON,1), nanmean(tmp,1), nanstd(tmp, 0, 1)./sqrt(size(SCON,5)), 'k^-');
        errorbar(1:size(SCON,1), nanmean(tmp1,1), nanstd(tmp1,0, 1)./sqrt(size(SCON,5)), 'rs-'); 
        title(rCOND{IND(c)}); 
        axis([0.5 size(SCON,1)+.5 0 1])
    end % c
end % F

%% PLOT CHANGE IN EFFECT SIZE FOR CONTROL EXPERIMENT
%   This is specific to the first DTIME experiment. We want to see how the
%   effect of condition varies with temporal offset.  This is going to be a
%   little wonky because I have to hard code a lot of things. SO, beware of
%   bugs, man. Bugs. 
%
%   Bishop, Chris 2010 UC Davis Miller Lab
if ~isempty(strfind(EXPID, 'DTIME01')) && F
    tmp=squeeze(gSRATE(:,1,:)./gSRATE(:,2,:))'; 
    OUT=[]; 
    
    % Leading Side
    OUT=[OUT [tmp(:, [3 4])-tmp(:, [1 2])]]; % leading side (0 msec lag)
    OUT=[OUT [tmp(:, [16 17])-tmp(:, [1 2])]]; % leading side (100 msec lag) 
    OUT=[OUT [tmp(:, [18 19])-tmp(:, [1 2])]]; % leading side (400 msec lag)
    
    % Lagging Side
    OUT=[OUT [tmp(:, [5 6])-tmp(:, [1 2])]]; % lagging side (0 msec lag) 
    OUT=[OUT [tmp(:, [20 21])-tmp(:, [1 2])]]; % lagging side (100 msec lag) 
    OUT=[OUT [tmp(:, [22 23])-tmp(:, [1 2])]]; % lagging side (400 msec lag)     

    figure, hold on
    errorbar([0 100 400], mean(OUT(:,[1 3 5]),1), std(OUT(:,[1 3 5]), 0, 1)./sqrt(size(OUT,1)), 'ks-'); % leading side, right
    errorbar([0 100 400], mean(OUT(:,[2 4 6]),1), std(OUT(:,[2 4 6]), 0, 1)./sqrt(size(OUT,1)), 'rs-'); % leading side, left
    errorbar([0 100 400], mean(OUT(:,[7 9 11]),1), std(OUT(:,[7 9 11]), 0, 1)./sqrt(size(OUT,1)), 'ko--'); % lagging side, right
    errorbar([0 100 400], mean(OUT(:,[8 10 12]),1), std(OUT(:,[8 10 12]), 0, 1)./sqrt(size(OUT,1)), 'ro--'); % lagging side, left
    
    legend('Right Lead, Right Light', 'Left Lead, Left Light', 'Right Lead, Left Light', 'Left Lead, Right Light', 'location', 'best');
    title(['Temporal Dependence of effect N=(' num2str(size(gSRATE,3)) + ')']);
    xlabel('Temporal Offset (msec)');
    ylabel('% Difference'); 
    axis([-50 450 -1 1]);
end % ~isempty(str ... 