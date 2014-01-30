function AA03_behavior(SID, LOCAL_AUDIO)
%% DESCRIPTION:
%
%   MATLAB based port of behavioral testing used in VOT training. This is
%   done using a combination of response tracking (PsychToolbox) and high
%   fidelity sound output recordings using TDT software. Local audio can be
%   used for testing purposes, but should *not* be used for experimental
%   purposes since the timing precision of the local audio drivers will
%   differ. PsychoPortAudio() has not been tested at all by CWB as of
%   1/30/2014, so don't trust it for experimental purposes.
%
% INPUT:
%
%   SID:    string, subject ID (e.g., SID='s0133'); 
%   LOCAL_AUDIO:    bool, present sounds via local Audio device. For
%                   debugging *ONLY*. Should not be used for psychophysical
%                   testing. (default=false)
%
% OUTPUT:
%
%   
%
% List of desired features
%
%   - Support TDT and local audio 
%   - 