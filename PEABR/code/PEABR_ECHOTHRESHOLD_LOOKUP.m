function OUT=PEABR_ECHOTHRESHOLD_LOOKUP(SID)
%% DESCRIPTION
%
%   Function to lookup the echo threshold for a subject in an experiment.
%   Returned in seconds (s).
%
% INPUT:
%f
%   SID:    string, subject ID.
%   

SLIST=strvcat('s3160', 's3161', 's3162', 's3163', 's3167', 's3173', 's3174', 's3175', 's3179', 's3180', 's3184', 's3185', 's3188', 's3189', 's3190', 's3193', 's3194', 's3195', 's3196', 's3199', 's31100');
ALAG=[0.0045;0.004;0.0025;0.002;0.0051;0.0017;0.002;0.0015;0.00235;0.002;0.00375;0.005771;0.0038;0.00274;0.00355;0.007285;0.003125;0.0037;0.004533;0.0021;0.0025];

IND=strmatch(SID, SLIST);

% Some sanity checks
if isempty(IND)
    error('Subject not found'); 
elseif length(IND)>1
    error('Multiple matches, check your list, n00b'); 
end % isempty(IND)

OUT=ALAG(IND);