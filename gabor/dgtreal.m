function [c,Ls,g]=dgtreal(f,g,a,M,varargin)
%DGTREAL  Discrete Gabor transform for real-valued signals
%   Usage:  c=dgtreal(f,g,a,M);
%           c=dgtreal(f,g,a,M,L);
%           [c,Ls]=dgtreal(f,g,a,M);
%           [c,Ls]=dgtreal(f,g,a,M,L);
%
%   Input parameters:
%         f     : Input data
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of modulations.
%         L     : Length of transform to do.
%   Output parameters:
%         c     : $M*N$ array of coefficients.
%         Ls    : Length of input signal.
%
%   `dgtreal(f,g,a,M)` computes the Gabor coefficients (also known as a
%   windowed Fourier transform) of the real-valued input signal *f* with
%   respect to the real-valued window `g` and parameters *a* and *M*. The
%   output is a vector/matrix in a rectangular layout.
%
%   As opposed to |dgt|_ only the coefficients of the positive frequencies
%   of the output are returned. `dgtreal` will refuse to work for complex
%   valued input signals.
%
%   The length of the transform will be the smallest multiple of *a* and *M*
%   that is larger than the signal. *f* will be zero-extended to the length of
%   the transform. If *f* is a matrix, the transformation is applied to each
%   column. The length of the transform done can be obtained by
%   `L=size(c,2)*a`.
%
%   The window *g* may be a vector of numerical values, a text string or a
%   cell array. See the help of |gabwin|_ for more details.
%
%   `dgtreal(f,g,a,M,L)` computes the Gabor coefficients as above, but does
%   a transform of length *L*. *f* will be cut or zero-extended to length L before
%   the transform is done.
%
%   `[c,Ls]=dgtreal(f,g,a,M)` or `[c,Ls]=dgtreal(f,g,a,M,L)` additionally
%   returns the length of the input signal *f*. This is handy for
%   reconstruction::
%
%     [c,Ls]=dgtreal(f,g,a,M);
%     fr=idgtreal(c,gd,a,M,Ls);
%
%   will reconstruct the signal *f* no matter what the length of *f* is, provided
%   that *gd* is a dual window of *g*.
%
%   `[c,Ls,g]=dgtreal(...)` additionally outputs the window used in the
%   transform. This is useful if the window was generated from a description
%   in a string or cell array.
%
%   See the help on |dgt|_ for the definition of the discrete Gabor
%   transform. This routine will return the coefficients for channel
%   frequencies from 0 to `floor(M/2)`.
%
%   `dgtreal` takes the following flags at the end of the line of input
%   arguments:
%
%     'freqinv'  Compute a `dgtreal` using a frequency-invariant phase. This
%                is the default convention described in the help for |dgt|_.
%
%     'timeinv'  Compute a `dgtreal` using a time-invariant phase. This
%                convention is typically used in filter bank algorithms.
%
%   `dgtreal` can be used to manually compute a spectrogram, if you
%   want full control over the parameters and want to capture the output
%   :::
%
%     f=greasy;  % Input test signal
%     fs=16000;  % The sampling rate of this particular test signal
%     a=10;      % Downsampling factor in time
%     M=200;     % Total number of channels, only 101 will be computed
%
%     % Compute the coefficients using a 20 ms long Hann window
%     c=dgtreal(f,{'hann',0.02*fs'},a,M);
%
%     % Visualize the coefficients as a spectrogram
%     dynrange=90; % 90 dB dynamical range for the plotting
%     plotdgtreal(c,a,M,fs,dynrange);
%     
%   See also:  dgt, idgtreal, gabwin, dwilt, gabtight, plotdgtreal
%
%   References: fest98 gr01

%   AUTHOR : Peter Soendergaard.
%   TESTING: TEST_DGT
%   REFERENCE: OK
  
% Assert correct input.

if nargin<4
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.flags.phase={'freqinv','timeinv'};
[flags,kv]=ltfatarghelper({'L'},definput,varargin);

[f,g,L,Ls] = gabpars_from_windowsignal(f,g,a,M,kv.L);

if ~isreal(g)
  error('The window must be real-valued.');  
end;

c=comp_dgtreal(f,g,a,M,L,flags.do_timeinv);

