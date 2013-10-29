function [results X]=MSPE_EEG_amplitude(args)
%% DESCRIPTION:
%
%   Get amplitude measures for various time windows.
%
% INPUT:
%
%   args.
%       filename:   ERP files to load
%       latency:    time(s) of measurement. 
%       binArray:   bins to apply operations to.
%       chanArray:  channels to apply operations to.
%       txtfile:    
%       options:    see pop_geterpvalues for details.
%
% OUTPUT:
%
%   results:    'done', something for GAB
%   X:          matrix, values
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2010

%% Setup
if iscell(args.filename), args.filename=cell2mat(args.filename); end;
% default for txtfile should be set here.

%% Write filenames to text
dlmwrite(args.txtfile, args.filename, '');

% Average over a set of channels
for c=1:length(args.chanArray)
    for i=1:size(args.latency,1)
        x=pop_geterpvalues('', [args.latency(i,1) args.latency(i,2)], args.binArray, args.chanArray{c}, 'Erpsets', args.txtfile, 'Measure', 'meanbl', 'Baseline', args.Baseline);
        X(:,:,i,c)=squeeze(mean(x,2));
    end % i
end % c

results='done';