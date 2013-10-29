function [X]=MSPE_kolev(DATA, times, tBL)
%% DESCRIPTION:
%
%   This function implements a strategy to adjust phase locking factors
%   (PLFs) for the number of trials implemented.  
%
%   The Problem:
%   Fewer trials generally leads to greater PLFs while more trials leads to
%   smaller PLFs.  As a result, it's difficult to interpret a difference in
%   PLF values between two conditions with unequal trial numbers.  
%
%   The solution:
%   There are several strategies for correcting PLFs for trial number.
%   This function is one of them adapted from 
%
%   Kolev, V. and J. Yordanova (1997). "Analysis of phase-locking is 
%   informative for studying event-related EEG activity." Biol Cybern 
%   76(3): 229-235.
%
%   Breifly, the PLF within a predefined baseline period (e.g. prior to
%   stimulus onset) is used to divisively normalize all non-baseline data.
%   This effectively forces the number of trials and the PLF to be
%   uncorrelated. The great part of this is that it doesn't directly use 
%   the trial number information (less work for YOU).  
%
%   Analternative is Rayleigh's Z, which is not discussed here, but was
%   used recently in 
%   
%   Backer, K. C., K. T. Hill, et al. (2010). "Neural time course of echo 
%   suppression in humans." J Neurosci 30(5): 1905-1913.
%
%   I've used both on the same data, and Kolev's correction tends to be a
%   bit more conservative (others might call Rayleigh's Z more
%   "sensitive"). They both seem to give qualitatively similar results.
%
% INPUT:
%
%   DATA:   FxTxS data structure, with F frequency bins, T time bins, C
%           channels, and S subjects.
%   times:  array of T time points
%   freqs:  array of F frequency values
%   tBL:    2x1 array, time range for baseline correction (default: all
%           prestimulus time points; [1 find(times<0,1,'last')]).
%
% OUTPUT:
%
%   X:      FxTxS corrected data matrix.
%
% Bishop, Christopher W.
%   UC Davis
%   Miller Lab 2011
%   cwbishop@ucdavis.edu

%% DEFAULTS and ERROR CHECKING
if ~exist('tBL', 'var'), tBL=[times(1) times(find(times<0, 1, 'last'))]; end

%% CONVERT tBL
%   Convert to array so it's easier to user later.
tBL=find(times>=tBL(1), 1, 'first'):find(times<=tBL(2),1,'last');

%% DETERMINE DIVISIVE BASELINE
BL=mean(DATA(:,tBL,:),2);
BL=repmat(BL, [1 size(DATA,2)]); 

%% NORMALIZE
X=DATA./BL; 