function [LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM]=PEABR_exp01E(P, SID)
%% DESCRIPTION:
%
%   Hold over function while I'm on vacation to conduct Experiment 01E in a
%   slightly less than ideal way.  The idea is to replicate as closely as
%   possible the experiment in Presentation. I didn't bring the
%   Presentation dongle ::smacks forehead::.  Essentially handles basic
%   stimulus presentation and response gathering. Also saves output data to
%   a MATFILE.
%
% INPUT:
%   
%   P:  path to MATFILE to play.
%   SID:    Subject ID, used when writing log files.
%   
% OUTPUT:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS
FS=48000;
DATA=[];

%% LOAD MAT-FILE
load(P, 'IN', 'RP', 'ADDCUE'); 

%% CREATE SESSION
[OUT ORDER]=PEABR_session(IN, RP, 1); % fixed threshold to 1..doesn't really matter anyway

%% PLAY STIMULI, COLLECT RESPONSES
LAC=[];
RAC=[];
ALAG=[];
VCOD=[];
COND=[];
LJIT=[];
UJIT=[];
NSTIM=[];
NBREAKS=[];
MINCHUNK=[];
COFFSET=[];

%% RESPONES VARIABLE
RESP_NSTIM=[];
for i=1:length(ORDER)
    
    % Make stimulus
    [ASTIM FS]=PEABR_stim(OUT{ORDER(i)}, DATA, FS); 
    
    % Store stimulus parameters
    LAC(i)=OUT{ORDER(i)}(1);
    RAC(i)=OUT{ORDER(i)}(2);
    ALAG(i)=OUT{ORDER(i)}(3);
    VCOD(i)=OUT{ORDER(i)}(4);
    COND(i)=OUT{ORDER(i)}(5);
    LJIT(i)=OUT{ORDER(i)}(6);
    UJIT(i)=OUT{ORDER(i)}(7);
    NSTIM(i)=OUT{ORDER(i)}(8);
    NBREAKS(i)=OUT{ORDER(i)}(9);
    MINCHUNK(i)=OUT{ORDER(i)}(10);
    COFFSET(i)=OUT{ORDER(i)}(11);
    
    % Play stimulus
    wavplay(ASTIM, FS);
    
    % Gather response
    resp_nstim=input('Number of sounds on LEFT?', 's');
    
    % Store response
    RESP_NSTIM(i)=str2double(resp_nstim);
    
end % end 

%% SAVE DATA
A=0;
FLAG=0;

while ~FLAG
    if ~exist([SID '-' num2str(A)], 'file')
        FLAG=1;
    else 
        A=A+1;
    end % if 
end % WHILE

save([SID '-' num2str(A)], 'LAC', 'RAC', 'ALAG', 'VCOD', 'COND', 'LJIT', 'UJIT', 'NSTIM', 'NBREAKS', 'MINCHUNK', 'COFFSET', 'RESP_NSTIM');
