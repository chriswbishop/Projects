function [DATA T]=MSPE_equalize(L, R, DATA)
%% DESCRIPTION:
%
%   Estimates the transfer function (T) from A to B.
%
% INPUT:
%
%   L:
%   R:
%   DATA:
%   FS:
%
% OUTPUT:
%
%   DATA:
%   T:
%
% Bishop, Chris Miller Lab 2010

%% Zero padding necessary?
%   Not sure if we need this. Try zero padding A and B and see if it makes
%   any qualitative differences in the Transfer function
% sA=size(A);
% sB=size(B);
% A=[A; zeros(sB)];
% B=[B; zeros(sA)];

%% Compute transfer function
%   Equivalent to 
T=ifft(fft(R)./fft(L));

%% Correct data with transfer function
DATA(:,1)=fftfilt(T, DATA(:,1)); 