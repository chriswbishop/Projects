function [OUT]=PEABI_session(IN, RP, T, T2)
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
% OUTPUT:
%   
%   OUT:    pseudorandomized stimulus specifications formatted as IN. See
%           MSPE_stim.m for details.
%
% Bishop, Chris Miller Lab 2010

%% DEFAULTS
if ~exist('T', 'var') || isempty(T), T=1; end

%% MULTIPLY LAGS BY T
if ~exist('T2', 'var') || isempty(T2)
    IN(3,:)=IN(3,:).*T;
else
    for i=1:2:size(IN,2), IN(3,i)=IN(3,i).*T; end
    for i=2:2:size(IN,2), IN(3,i)=IN(3,i).*T2; end
end

%% REPLICATE TRIAL TYPES
in=[];
for i=1:size(IN,2)
    in=[in IN(:,i)*ones(1,IN(end,i))]; 
end % for

%% PSEUDORANDOMIZE
rp=[]; flag = 0;
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

%% ASSIGN OUT
OUT=in;