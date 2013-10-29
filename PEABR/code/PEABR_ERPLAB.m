function results=PEABR_ERPLAB(args)
%% DESCRIPTION
%
% INPUTS:
%
%   args.BINLIST
%
%   args.Epoch
%
%   args.Baseline
%
%   args.threshold
%
%   args.FilterBandPass
%
%   args.FilterOrder
%
%   args.ERPFilename
%
%   args.ERPName
%
%   args.typef
%  
%   args.BINOPS
%
%   args.mainfield: overwrite event fields
%
% OUTPUTS:
%
% Bishop, Chris Miller Lab 2010

%% START EEG LAB
global EEG;

if ~isfield(args, 'mainfield') || isempty(args.mainfield), args.mainfield='binlabel'; end

% try 
    %% ERPLAB: Filter EEG
    
    %% LOOP FILTER DATA
    %   ERPLAB TRIES TO FILTER ALL CHANNELS SIMULTANEOUSLY.
    %   Doesn't work with big data sets like an ABR
    for c=1:length(args.chanArray)
        EEG = pop_basicfilter( EEG, args.chanArray(c), args.FilterBandPass(1), args.FilterBandPass(2), args.FilterOrder, args.typef, 1, args.boundary );
    end % c
%         EEG = eeg_checkset( EEG );

    %% ERPLAB: Create Event List
    EEG = pop_creabasiceventlist(EEG, '', {'boundary'}, {-99});
    EEG = eeg_checkset( EEG );

    %% ERPLAB: BINLISTER
    EEG = pop_binlister( EEG, args.BINLIST, 'no', '', 0, [], [], 0, 0, 0);
%     EEG = eeg_checkset( EEG );

    %% TRANSFER BINS TO EEG
    EEG = pop_overwritevent(EEG, args.mainfield); 
    
    %% ERPLAB: Epoch and Baseline Correct Data
    EEG = pop_epochbin( EEG , [args.Epoch(1)  args.Epoch(2)],  [args.Baseline(1) args.Baseline(2)]);
%     EEG = eeg_checkset( EEG );

    %% ERPLAB: Artifact Rejection (Simple Threshold)
%     EEG = pop_artextval( EEG, [args.Epoch(1) args.Epoch(2)], [args.threshold(1) args.threshold(2)],  args.chanArray, 8);
    EEG = pop_artextval( EEG, [args.artTwin(1) args.artTwin(2)], [args.threshold(1) args.threshold(2)],  args.chanArray, 8);
%     EEG = eeg_checkset( EEG );

    %% ADD IN ADDITIONAL REJECTION CRITERIA!
    %   For instance, rejecting additional trials rejected in a different
    %   EEG dataset. 
    if isfield(args, 'EEGREJ_filename') && ~isempty(args.EEGREJ_filename)
        EEGREJ=pop_loadset('filename', args.EEGREJ_filename, 'filepath', args.EEGREJ_filepath, 'loadmode', 'all');        
        EEG=MSPE_RejectBlinks(EEG, EEGREJ); 
    end % 
   
    %% ERPLAB: Compute Average ERPs
    ERP = pop_averager(EEG,1, args.artcrite, args.iswavg, args.stdev);

    %% BIN OPERATIONS
    if isfield(args, 'BINOPS') && ~isempty(args.BINOPS)
        % Code stolen from binoperGUI.m
%         fid_formula=fopen(args.BINOPS, 'r'); 
%         formcell    = textscan(fid_formula, '%s','delimiter', '\r');
%         formulas    = char(formcell{:});
        ERP = pop_binoperator(ERP, args.BINOPS);
    end % exist
    
    %% Name
    ERP.erpname=args.ERPName;
    
    %% ERPLAB: Save ERP set
    save(args.ERPFilename, 'ERP');
    
    results='done';
% catch
%     results='error';
% end % try