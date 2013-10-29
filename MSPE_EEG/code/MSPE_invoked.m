function [results X]=MSPE_invoked(args)
%% DESCRIPTION:
%
%   Function estimates the trial to trial "ERSP".  Since these are single
%   trial estimates, out of phase signals that would otherwise be missed in
%   the classic ERSP estimation are present.  In other words, this is a way
%   to estimate the "INVOKED" activity.
%
%   Importantly, these data are ENORMOUS, so the power spectra are averaged
%   across all channels entered in args.chanArray.
%
% INPUT:
%
%   Note: Input is identical to MSPE_spect.
%
%   args.
%       chanArray:  integer array, list of channels to perform
%                   spectrotemporal analysis on.  
%       binArray
%       filepath
%       filename
%       baseline
%       cycles
%       plotphase
%       padratio
%       freqs
%       timesout
%
% OUTPUT:
%
%   results:
%   X:
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% LOAD GLOBALS
global EEG;

%% ERROR CHECKING
%   Maybe I should check some things.
%% EXTRACT EPOCHS BASED ON BIN GROUPING
%   I stole some code from ERPLAB to figure out which trials are rejected.
% averager.m (80-
F = fieldnames(EEG.reject);
sfields1 = regexpi(F, '\w*E$', 'match');
sfields2 = [sfields1{:}];
fields4reject  = regexprep(sfields2,'E','');

for c=1:length(args.chanArray)
    X=[];
    trls=0;
    for i=1:length(EEG.EVENTLIST.eventinfo)
        bini=EEG.EVENTLIST.eventinfo(i).bini;
        
        % Flag set to 1 if included, set to 0 if rejected.
        %   Recall that rejection information is stored based on EPOCH
        %   information, not on individual eventinfo.
        bepoch=EEG.EVENTLIST.eventinfo(i).bepoch;
        try
            flag = eegartifacts(EEG.reject, fields4reject, bepoch);
        catch
            flag=0; % toss trial if we can't be sure it's OK.
        end; 
        
        if ~isempty(find(ismember(bini, args.binArray),1)) && flag
            X=[EEG.data(args.chanArray(c),:,bepoch)]; 
            trls=trls+1;
            [ersp(:,:,c,trls) itc(:,:,c,trls) powbase(:,:,c,trls) times freqs]=newtimef(X, EEG.pnts, [EEG.xmin EEG.xmax]*1000, EEG.srate, args.cycles, 'baseline', args.baseline, 'freqs', args.freqs, 'plotphase', args.plotphase, 'padratio', args.padratio, 'timesout', args.timesout, 'plotersp', 'off', 'plotitc', 'off', 'verbose', 'off');
        end % if         
    end % i    
end % c

%% Average across channels
%   Needed to save space, these things are ridiculously huge.
% ERSP=squeeze(mean(ersp,3)); 

%% SAVE TIME-FREQUENCY DATA
save(fullfile(args.filepath, args.filename), 'ersp', 'itc', 'powbase', 'times', 'freqs', 'args', 'trls');

results='done';
