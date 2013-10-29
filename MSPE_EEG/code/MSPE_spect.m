function [results X ersp itc powbase times freqs]=MSPE_spect(args)
%% DESCRIPTION;
%
%   Assumes the EEG data have already been epoched and have been run
%   through ERPLAB's BinLister.
%
% INPUT:
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
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

global EEG;

%% DEFAULTS
if ~isfield(args, 'cycles'), args.cycles=[2 0.5]; end
if ~isfield(args, 'baseline') || isempty(args.baseline), args.baseline=0; end
if ~isfield(args, 'plotphase') || isempty(args.plotphase), args.plotphase='off'; end
if ~isfield(args, 'padratio') || isempty(args.padratio), args.padratio=1; end
if ~isfield(args, 'freqs') || isempty(args.freqs), args.freqs=[4 50]; end 
if ~isfield(args, 'timesout') || isempty(args.timesout), args.timesout=length(EEG.times); end % temporal resolution of spectrogram, go big if user doesn't care.

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
            X=[X EEG.data(args.chanArray(c),:,bepoch)]; % average over channels
            trls=trls+1; 
        end % if 
    end % i
    [ersp(:,:,c) itc(:,:,c) powbase(:,:,c) times freqs]=newtimef(X, EEG.pnts, [EEG.xmin EEG.xmax]*1000, EEG.srate, args.cycles, 'baseline', args.baseline, 'freqs', args.freqs, 'plotphase', args.plotphase, 'padratio', args.padratio, 'timesout', args.timesout);
end % c

%% SAVE TIME-FREQUENCY DATA
save(fullfile(args.filepath, args.filename), 'trls', 'ersp', 'itc', 'powbase', 'times', 'freqs', 'args');

results='done'; 