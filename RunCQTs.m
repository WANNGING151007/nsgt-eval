% This script is related to the paper:
% Improving PLCA-based Score-Informed Source Separation 
% with Invertible Constant-Q Transforms
% J. Ganseman, P. Scheunders and S. Dixon
% EUSIPCO 2012

% Author: Joachim Ganseman, University of Antwerp, all rights reserved
% Adaptations and updates: december 2013

% This is a demo that demonstrates how the different implementations
% of (almost) invertible CQTs need to be run on data.
  

%%
clear;
addpath(genpath('./'));     % add subdirectories to path

createfigs=0;       % boolean: create figures for paper

%% Parameters

fftsize = 1024;
hopsize = fftsize / 4;

bins_per_octave = 48;       % make this a multiple of 12 for music


% Read file
datadir = getDataDirectory();       % directory with example files
[origMix,samplerate] = wavread([datadir 'pianoclip4notes.wav']);

  % if stereo, make mono
  if size(origMix, 2) > 1
     origMix = sum(origMix, 2) ./2 ; 
  end

  
%% Test the Klapuri CQT transform

% set min and max frequencies available
fs=samplerate;
fmax = fs/3;     %center frequency of the highest frequency bin .
fmin = fmax/512; %lower boundary for CQT (lowest frequency bin will be immediately above this): fmax/<power of two> 
% at 44100, max=14700, min=28.7
% FYI, a piano goes from 27.5 to 4186 Hz. (we want some higher harmonics too though)

% prepare signal: cut out frequencies outside range
%x = [zeros(500,1); origMix; zeros(500,1)];
x=origMix;
w1 = 2*(fmin/(fs/2)); w2 = 0.8*(fmax/(fs/2));
[B,A] = butter(6,[w1 w2]); x = filtfilt(B,A,x); 

% Calculate CQT
KlapuriCQT = cqt(x,fmin,fmax,bins_per_octave,fs);     % more options available for hop size, tresholding, window function used
KlapuriReverted = icqt(KlapuriCQT);
%KlapuriReverted = KlapuriReverted(501:size(KlapuriReverted)-500);

% display!
plotCQT(KlapuriCQT,fs,0.6,'surf');

% interpolate, and display that one too
intCQT = getCQT(KlapuriCQT,'all','all');
figure;
spectrum_plot(intCQT); colormap(jet);


% calculate the perfect rasterized version
KlapuriRast = cqtPerfectRast(x,fmin,fmax,bins_per_octave,fs);
KlapuriRevertedRast = icqt(KlapuriRast);
%KlapuriRevertedRast = KlapuriRevertedRast(501:size(KlapuriRevertedRast)-500);

s = origMix;
s_r = KlapuriReverted;
rec_err = norm(s-s_r)/norm(s);
fprintf(['Klapuri general error:'...
    '   %e \n'],rec_err);

s = origMix;
s_r = KlapuriRevertedRast;
rec_err = norm(s-s_r)/norm(s);
fprintf(['Klapuri rasterized error:'...
    '   %e \n'],rec_err);



%% Test the Prado CQT transform

minfreq=fmin; % fr�quence de d�but d'analyse
bins=bins_per_octave; % nombre de bins par octave
nbo=9;  % nombre d'octaves.
maxfreq=minfreq*(2^nbo);

assert(maxfreq == fmax);

% DO THE SAME TRICK AS FOR KLAPURI:
%x = [zeros(500,1); origMix; zeros(500,1)];
x=origMix;

% On va filtrer pour comparer les m�mes bandes de fr�quences.
rp = 3;           % Passband ripple
rs = 70;          % Stopband ripple
f = [maxfreq min(1.1*maxfreq,fs/2)];    % Cutoff frequencies
a = [1 0];        % Desired amplitudes
dev = [(10^(rp/20)-1)/(10^(rp/20)+1) 10^(-rs/20)]; 
[n,fo,ao,w] = remez_lp_ordre(f,a,dev,fs);
bdp = remez_lp(n,fo,ao,w);
x=filtfilt(bdp,1,x);
% pas d'analyse en seconde demand�
avance=0; %0.0005;           % MAKE LOW ENOUGH for reconstruction
% Filtre de d�cimation pour le calcul de la cqt
[b,bandwidth] = filtre_def();
[Pradocqt,t, f_cal, fs_new, noyau, Nfft, R,avance_reelle]=cqt_resamp(b,bandwidth,x,fs,minfreq,bins,nbo,avance);

if (R >= Nfft/2)
    disp('Step size too big w.r.t. FFT size.');
    disp('The reconstruction risks to be inaccurate.');
    disp('Either increase the nr of bins per octave,');
    disp('or diminish the stepsize.');
end
if avance_reelle==0
    disp('You are asking for too many octaves!');
    return;
end
txt=['Stepsize used was : ' num2str(avance_reelle) ' seconds'];
disp(txt);

%DISPLAY:
%figure;
%mesh(t,f_cal,abs(cqt));title('Prado CQT resample');
figure;
imagesc(abs(Pradocqt)); axis xy; colormap(jet);title('Prado CQT resample');

%RECONSTRUCT using several windows
% type_fen=1;
% y_rec_ham=cqt_inv(Pradocqt,Nfft,nbo,bins,R,minfreq,b,fs_new,fs,type_fen);
% y_rec_ham=y_rec_ham(501:length(origMix)+500);
type_fen=2;
y_rec_rect=cqt_inv(Pradocqt,Nfft,nbo,bins,R,minfreq,b,fs_new,fs,type_fen);
    %y_rec_rect=y_rec_rect(501:length(origMix)+500);
type_fen=3;
% y_rec_tuk=cqt_inv(Pradocqt,Nfft,nbo,bins,R,minfreq,b,fs_new,fs,type_fen);
% y_rec_tuk=y_rec_tuk(501:length(origMix)+500);

% I've added a couple of windows
% type_fen=4;
% y_rec_han=cqt_inv(Pradocqt,Nfft,nbo,bins,R,minfreq,b,fs_new,fs,type_fen);
% y_rec_han=y_rec_han(501:length(origMix)+500);
% type_fen=5;
% y_rec_blha=cqt_inv(Pradocqt,Nfft,nbo,bins,R,minfreq,b,fs_new,fs,type_fen);
% y_rec_blha=y_rec_blha(501:length(origMix)+500);


% Comparaison de reconstruction suivant la fen�tre utilis��e.
% figure;
% subplot(311);plot(x); hold on; plot(y_rec_ham,'r');hold off;
% axis([1 8192 -1.3 1.3]);hleg1 = legend('Original','Reconstruit');
% set(hleg1,'Location','NorthEast'); set(hleg1,'Interpreter','none');
% xlabel('Avec fen�tre de Hamming');
% subplot(312);plot(x); hold on; plot(y_rec_rect,'r');hold off;
% axis([1 8192 -1.3 1.3]);hleg1 = legend('Original','Reconstruit');
% set(hleg1,'Location','NorthEast'); set(hleg1,'Interpreter','none');
% xlabel('Avec fen�tre rectangulaire');
% subplot(313);plot(x); hold on; plot(y_rec_tuk,'r');hold off;
% axis([1 8192 -1.3 1.3]);hleg1 = legend('Original','Reconstruit');
% set(hleg1,'Location','NorthEast'); set(hleg1,'Interpreter','none');
% xlabel('Avec fen�tre de Tukey');

% s = origMix;
% s_r = y_rec_ham;
% rec_err = norm(s-s_r)/norm(s);
% fprintf(['Prado rast Hamming error:'...
%     '   %e \n'],rec_err);

s = origMix;
s_r = y_rec_rect(1:length(s));
rec_err = norm(s-s_r)/norm(s);
fprintf(['Prado rast Rectangular error:'...
    '   %e \n'],rec_err);
% 
% s = origMix;
% s_r = y_rec_tuk;
% rec_err = norm(s-s_r)/norm(s);
% fprintf(['Prado rast Tukey error:'...
%     '   %e \n'],rec_err);
% 
% s = origMix;
% s_r = y_rec_han;
% rec_err = norm(s-s_r)/norm(s);
% fprintf(['Prado rast Hann error:'...
%     '   %e \n'],rec_err);
% 
% s = origMix;
% s_r = y_rec_blha;
% rec_err = norm(s-s_r)/norm(s);
% fprintf(['Prado rast Blackman-Harris error:'...
%     '   %e \n'],rec_err);

% --> Seems like best results are gotten with the Rectangular win
% Really wondering: is the signal also windowed before the forward
% transform? Otherwise using a window for the backward transform seems
% pretty pointless.


%% Test the Constant-Q Nonstationary Gabor Transform

fmin = fmin; % Minimum desired frequency (in Hz)
fmax = fmax;              
bins = bins_per_octave; %bins = [12; 24; 36; 48; 12]; 

%[s,fs] = wavread('glockenspiel.wav'); name = 'Glockenspiel';
s=origMix; 
fs=samplerate;
Ls = length(s); % Length of signal (in samples)

% Window design
%  Define a set of windows for the nonstationary Gabor transform with
%  resolution evolving over frequency. In particular, the centers of the
%  windows correspond to geometrically spaced center frequencies.
[g,shift,M] = nsgcqwin(fmin,fmax,bins,fs,Ls);

% Compute corresponding dual windows.
gd = nsdual(g,shift,M);

% Plot the windows and the corresponding dual windows
figure;
subplot(211); plot_wins(g,shift);
subplot(212); plot_wins(gd,shift);

% Calculate the coefficients
c = nsgtf(s,g,shift,M);

% Plot the resulting spectrogram
figure;
plotnsgtf(c,shift,fs,2,60);

% Test reconstruction
s_r = nsigtf(c,gd,shift,Ls);

% Print relative error of reconstruction.
rec_err = norm(s-s_r)/norm(s);
fprintf(['NSGTF Relative reconstruction error:'...
    '   %e \n'],rec_err);




%% Use own windowfunction, to rasterize

fmin = fmin; % Minimum desired frequency (in Hz)
fmax = fmax;              
bins = bins_per_octave; %bins = [12; 24; 36; 48; 12]; 

%[s,fs] = wavread('glockenspiel.wav'); name = 'Glockenspiel';
s=origMix; 
fs=samplerate;
Ls = length(s); % Length of signal (in samples)

% Window design
[g,shift,M] = nsgfwin_joa(fmin,fmax,bins,fs,Ls);

% Compute corresponding dual windows.
gd = nsdual(g,shift,M);

% Plot the windows and the corresponding dual windows
figure;
subplot(211); plot_wins(g,shift);
subplot(212); plot_wins(gd,shift);

% Calculate the coefficients
c = nsgtf(s,g,shift,M);

% Plot the resulting spectrogram
figure;
plotnsgtf(c,shift,fs,2,60);

% remove Nyquist frequency band, replace by zeroes
maxbin = size(c,1)/2;
c{maxbin+1} = zeros(length(origMix), 1);

% Test reconstruction
s_r = nsigtf(c,gd,shift,Ls);

% Print relative error of reconstruction.
rec_err = norm(s-s_r)/norm(s);
fprintf(['NSGTF Relative reconstruction error:'...
    '   %e \n'],rec_err);




% 
% %% Create figure for paper
% 
% %%
% 
% myimage = flipud( abs(KlapuriRast.spCQT) );
% myimage = myimage(:,1500:size(myimage,2)-3000); 
% 
% 
% % perform plca
% 
% %[w h] = plca(myimage, 4, 50);
% 
% figure;
% imagesc(myimage); colormap(1-gray)
% 
% figure;
% 
% subplot( 2, 2, 2), imagesc( w*h), title('resynthesized CQT'), colormap(1-gray);
% %subplot( 2, 2, 3), stem( z), axis tight, title('components')
% subplot( 2, 2, 1), multiplot( fliplr(w')), view( [-90 90]), title('spectra')
% subplot( 2, 2, 4), multiplot( h), title('timelines')
% drawnow
% 
