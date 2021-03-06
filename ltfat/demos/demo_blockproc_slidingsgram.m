function demo_blockproc_slidingsgram(source,varargin)
%DEMO_BLOCKPROC_SLIDINGSGRAM Basic real-time rolling spectrogram visualization
%   Usage: demo_blockproc_slidingsgram('gspi.wav')
%
%   For additional help call |demo_blockproc_slidingsgram| without arguments.
%
%   This demo shows a simple rolling spectrogram of whatever is specified in
%   source. 


if demo_blockproc_header(mfilename,nargin)
   return;
end

% Basic Control pannel (Java object)
p = blockpanel({
               {'GdB','Gain',-20,20,0,21},...
               });

% Basic sepctrogram figure (Java object)
fobj = blockfigure();

%
bufLen = 1024;
% Setup blocktream
fs=block(source,varargin{:},'loadind',p,'L',bufLen);


% Using dgtreal with 20ms hann window, hop factor 80, 1000 channels.
% Redundancy factor 12.5
winLenms = 30;
a = 80;
M = 1000;

F = frame('dgtreal',{'hann',floor(fs*winLenms/1e3)},a,M);
F = blockframeaccel(F, bufLen,'segola');


flag = 1;
%Loop until end of the stream (flag) and until panel is opened
while flag && p.flag
   % Obtain the global gain value
   gain = blockpanelget(p,'GdB');
   gain = 10^(gain/20);

   % Read the next block of samples
   [f,flag] = blockread();
   f=f*gain;
   
   % Do analysis using the specified frame. 
   c = blockana(F, f); 
   
   % Draw the first channel coefficients
   blockplot(fobj,F,c(:,1));
   
   % Enqueue to play
   blockplay(f);
end
blockdone(p,fobj);
