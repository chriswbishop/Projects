function [SORDER]=AA04_SESSORDER(SESSTYPE, REPS)
%% DESCRIPTION:
%
%   Function to create randomized session order for experiment AA04. 
%
% INPUT:
%
%   SESSTYPE:   integer array, session codes to randomize (e.g., [1 5])
%   REPS:       integer, number of times each session type will be run.
%
% OUTPUT:
%
%   SORDER:     integer array, session order.
%
% Christopher W. Bishop
%   University of Washington
%   1/14

%% DEFAULTS
% Valid session TYPES
VALIDTYPES=1:5;

%% INPUT CHECK
%   Confirm that no inappropriate codes are entered
if ~isempty(find(ismember(SESSTYPE, VALIDTYPES)==0,1))
    error('AA04:InvalidSessionType', ...
        'Invalid session type entered. Please check your inputs and try again.');     
end % if ~isempty(find ...

% Make sure we have an 1xC array
if size(SESSTYPE,1)>1, SESSTYPE=SESSTYPE'; end

%% ADD IN REPETITIONS
SORDER=repmat(SESSTYPE,1,REPS);

% RANDOMIZE
o=randperm(length(SORDER)); 
SORDER=SORDER(o); 
