function [LAC RAC ALAG VCOD COND LJIT UJIT NSTIM NBREAKS MINCHUNK COFFSET RESP_NSTIM RESP_NGROUP STIME]=PEABR_read(P)
%% DESCRIPTION:
%
%   Parse subject log files.
%
% INPUT:
%
%   P:  character array, each row is a full path to the logfile.
%
% OUTPUT:
%
% STIMULUS DATA
%
%   LAC:    see MSPE_stim
%   RAC:    see MSPE_stim
%   ALAG:   see MSPE_stim
%   VCOD:   see MSPE_stim
%   COND:   see MSPE_stim
%   VOFF:   see MSPE_stim (Note: this will be full of NaNs if a Visual 
%                                OFFset (VOFF) is not defined for the
%                                experiment).
%
% RESPONSE DATA
%
%   NRESP:  Number of objects RESPonse (NRESP). Response to question of
%           number of objects (1 or 2).
%   SRESP:  Side RESPonse (SRESP). Response to side objects are heard.
%   NRT:    Number of objects Reaction Time (NRT).
%   SRT:    Side of response Reaction Time (SRT).
%   STIME:  Stimulus TIME (STIME). Time of stimulus presentation as recorded 
%           in log file.
%
% OTHER:
%
%   S:      Session (S). Index into which logfile stimulus was  read from.
%
% Bishop, Chris Miller Lab 2010

%% INITIALIZE VARIABLES
%
% STIMULUS DATA
%
%   LAC:    see MSPE_stim
%   RAC:    see MSPE_stim
%   ALAG:   see MSPE_stim
%   VCOD:   see MSPE_stim
%   COND:   see MSPE_stim
%   VOFF:   see MSPE_stim
%
% RESPONSE DATA
%
%   NRESP:  Number of objects RESPonse (NRESP). Response to question of
%           number of objects (1 or 2).
%   SRESP:  Side RESPonse (SRESP). Response to side objects are heard.
%   NRT:    Number of objects Reaction Time (NRT).
%   SRT:    Side of response Reaction Time (SRT).
%   STIME:  Stimulus TIME (STIME). Time of stimulus presentation as recorded 
%           in log file.
%
% OTHER
%
%   S:      Session (S). Index into which logfile stimulus was  read from.
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
STIME=[];

%% RESPONSE DATA
RESP_NSTIM=[];
RESP_NGROUP=[]; 

%% READ LOG FILE
for f=1:size(P,1)
    
    % Open file
    ptr=fopen(P(f,:),'r');
    display(P(f,:));
    
    % Skip over header information
    for i=1:5 fgetl(ptr); end
    nl=fgetl(ptr);
    while isstr(nl)
        
        % PARSE NEW LINE (nl)
        [SID,rmd]=strtok(nl);
        [TRL,rmd]=strtok(rmd);
        [ET,rmd]=strtok(rmd);
        [COD,rmd]=strtok(rmd);
        [TIME,rmd]=strtok(rmd);
        [TTIME,rmd]=strtok(rmd);
        
        % PARSE SOUND ENTRIES
        if strcmp(ET,'Sound')
            
            % PARSE CODE ENTRY FOR SOUND
            [lac,rmd]=strtok(COD,';');
            [rac,rmd]=strtok(rmd,';');
            [alag,rmd]=strtok(rmd,';');
            [vcod,rmd]=strtok(rmd,';');
            [cond,rmd]=strtok(rmd,';');
            [ljit,rmd]=strtok(rmd,';');
            [ujit,rmd]=strtok(rmd,';');
            [nstim,rmd]=strtok(rmd,';'); 
            [nbreaks,rmd]=strtok(rmd,';');
            [minchunk,rmd]=strtok(rmd,';'); 
            [coffset,rmd]=strtok(rmd,';');
            
            % ASSIGN TO DATA ARRAYS
            LAC(end+1)=str2num(lac);
            RAC(end+1)=str2num(rac);
            ALAG(end+1)=str2num(alag);
            VCOD(end+1)=str2num(vcod);
            COND(end+1)=str2num(cond);
            LJIT(end+1)=str2num(ljit);
            UJIT(end+1)=str2num(ujit);
            NSTIM(end+1)=str2num(nstim);
            NBREAKS(end+1)=str2num(nbreaks);
            MINCHUNK(end+1)=str2num(minchunk);
            COFFSET(end+1)=str2num(coffset);
            
            %% INITIALIZE RESPONSES
            RESP_NSTIM(length(LAC))=NaN; 
            RESP_NGROUP(length(LAC))=NaN; 
            
            % Stimulus time
            STIME(length(LAC))=str2num(TIME); 
        end % Sound
        
        if strcmp(ET, 'Manual') && ~isempty(strfind(nl, ';'))
            [resp_nstim rmd]=strtok(COD, ';');
            [resp_ngroup rmd]=strtok(rmd, ';');
            
            RESP_NSTIM(length(LAC))=str2num(resp_nstim);
            RESP_NGROUP(length(LAC))=str2num(resp_ngroup);
        end % Manual
        % Grab a new line
        nl=fgetl(ptr);
    end % while
    fclose(ptr);
end % f
        