function [OUT]=MSPE_session(IN, RP, T, MIXUP)
%% DESCRIPTION:
%
%   Function pseudorandomizes stimuli for MSPE experiment.
%
% INPUT:
%   
%   IN:     see MSPE_stim.m for details.
%   
%   RP:     integer array of [size(IN,1)-1,1], RePeats (RP).  Sets the
%           maximum number of consecutive trials that can have a stimulus
%           with the corresponding stimulus parameter.  For instance, if
%           you do not want to play sounds from the left speaker on more
%           than 5 consecutive trials, then set RP(1,1)=10.  Negative
%           values are ignored by the pseudorandomizer.  Example below.
%
%               RP=[-1;-1;-1;-1;3];
%                   RP(1,1) (LAC):  no constraints
%                   RP(2,1) (RAC):  no constraints
%                   RP(3,1) (ALAG): no constraints
%                   RP(4,1) (VOD):  no constraints
%                   RP(5:,1)(COND): condition can only be repeated 3
%                                   consecutive times.
%           
%   T:     double, number to multiply ALAG by.  This is very useful when
%          specifying subject specific thresholds.  In such a case, set the
%          values of ALAG in variable IN to a scalar (e.g. -1 or 1, when
%          multiplied by T, will now be the subject specific lags).
%          (default=1; accepts whatever is in ALAG)
%
%   MIXUP:  XXX
%
% OUTPUT:
%   
%   OUT:    pseudorandomized stimulus specifications formatted as IN. See
%           MSPE_stim.m for details.
%
% Bishop, Chris UC Davis Miller Lab 2010

%% DEFAULTS
%   T (threshold scaling factor): set to 1 (use whatever is in the mat
%   files) by default
%   MIXUP: pseudorandomization flag, Used in PEABR_session.
if ~exist('T', 'var') || isempty(T), T=1; end
if ~exist('MIXUP', 'var') || isempty(MIXUP), MIXUP=true; end 
    
%% MULTIPLY LAGS BY T
%   Makes it really easy to pass in subject specific parameters and use a
%   single mat file for the whole experiment describing generic stimulus
%   types.
IN(3,:)=IN(3,:).*T;

%% REPLICATE TRIAL TYPES
in=[];
for i=1:size(IN,2)
    tmp=IN(:,i); tmp(end)=1; 
    in=[in tmp*ones(1,IN(end,i))]; 
end % for i ...

%% PSEUDORANDOMIZE
rp=[]; flag = 0;
if MIXUP
    while flag==0
        mrp=zeros(size(RP));
        rand('twister',sum(100*clock));
        I=randperm(size(in,2));
        in=in(:,I);
        rp=ones(length(RP),1);
        % This is retarded, but I can't think of a better way to do it at the
        % moment. Counts repeats in randomized sequence.
        for i=1:length(rp)
            for o=1:size(in,2)-1
                if in(i,o)==in(i,o+1), rp(i)=rp(i)+1; end
                if in(i,o)~=in(i,o+1), rp(i)=1; end
                if rp(i)>mrp(i), mrp(i)=rp(i); end
            end % 
        end % r
    
        % Are specifications of RP met? Negative values are ignored.
        mrp=mrp(RP>=0);    
        if sum(mrp<=RP(RP>=0))==length(RP(RP>=0)), flag=1; end
    
    end % while
end % if MIXUP

%% ASSIGN OUT
OUT=in;