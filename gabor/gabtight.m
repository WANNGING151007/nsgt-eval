function gt=gabtight(varargin)
%GABTIGHT  Canonical tight window of Gabor frame
%   Usage:  gt=gabtight(a,M,L);
%           gt=gabtight(g,a,M);
%           gt=gabtight(g,a,M,L);
%           gd=gabtight(g,a,M,L,lt);
%
%   Input parameters:
%         g     : Gabor window.
%         a     : Length of time shift.
%         M     : Number of modulations.
%         L     : Length of window. (optional)
%         lt    : Lattice type (for non-separable lattices).
%   Output parameters:
%         gt    : Canonical tight window, column vector.
%
%   `gabtight(a,M,L)` computes a nice tight window of length *L* for a
%   lattice with parameters *a*, *M*. The window is not an FIR window,
%   meaning that it will only generate a tight system if the system
%   length is equal to *L*.
%
%   `gabtight(g,a,M)` computes the canonical tight window of the Gabor frame
%   with window *g* and parameters *a*, *M*.
%
%   The window *g* may be a vector of numerical values, a text string or a
%   cell array. See the help of |gabwin|_ for more details.
%  
%   If the length of *g* is equal to *M*, then the input window is assumed to
%   be a FIR window. In this case, the canonical dual window also has
%   length of *M*. Otherwise the smallest possible transform length is
%   chosen as the window length.
%
%   `gabtight(g,a,M,L)` returns a window that is tight for a system of
%   length *L*. Unless the input window *g* is a FIR window, the returned
%   tight window will have length *L*.
%
%   `gabtight(g,a,M,[],lt)` or `gabtight(g,a,M,L,lt)` does the same for a
%   non-separable lattice specified by *lt*. Please see the help of
%   |matrix2latticetype|_ for a precise description of the parameter *lt*.
%
%   If $a>M$ then an orthonormal window of the Gabor Riesz sequence with
%   window *g* and parameters *a* and *M* will be calculated.
%
%   See also:  gabdual, gabwin, fir2long, dgt

%   AUTHOR : Peter Soendergaard.
%   TESTING: TEST_DGT
%   REFERENCE: OK

%% ------------ decode input parameters ------------

if nargin<3
    error('%s: Too few input parameters.',upper(mfilename));
end;

if numel(varargin{1})==1
  % First argument is a scalar.

  a=varargin{1};
  M=varargin{2};

  g='gauss';

  varargin=varargin(3:end);  
else    
  % First argument assumed to be a vector.

  g=varargin{1};
  a=varargin{2};
  M=varargin{3};

  varargin=varargin(4:end);
end;

definput.keyvals.L=[];
definput.keyvals.lt=[0 1];
definput.keyvals.nsalg=0;
[flags,kv,L,lt]=ltfatarghelper({'L','lt'},definput,varargin);


%% ------ step 2: Verify a, M and L
if isempty(L)
    if isnumeric(g)
        % Use the window length
        Ls=length(g);
    else
        % Use the smallest possible length
        Ls=1;
    end;

    % ----- step 2b : Verify a, M and get L from the window length ----------
    L=dgtlength(Ls,a,M,lt);

else

    % ----- step 2a : Verify a, M and get L

    Luser=dgtlength(L,a,M,lt);
    if Luser~=L
        error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
               'is L=%i. See the help of DGTLENGTH for the requirements.'],...
              upper(mfilename),L,Luser)
    end;

end;


%% ----- step 3 : Determine the window 

[g,info]=gabwin(g,a,M,L,lt,'callfun',upper(mfilename));

if L<info.gl
  error('%s: Window is too long.',upper(mfilename));
end;

R=size(g,2);

% -------- Are we in the Riesz sequence of in the frame case

scale=1;
if a>M*R
  % Handle the Riesz basis (dual lattice) case.
  % Swap a and M, and scale differently.
  scale=sqrt(a/M);
  tmp=a;
  a=M;
  M=tmp;
end;

% -------- Compute ------------- 

if lt(2)==1
    % Rectangular case

    if (info.gl<=M) && (R==1)
        
        % FIR case
        N_win = ceil(info.gl/a);
        Lwin_new = N_win*a;
        if Lwin_new ~= info.gl
            g_new = fir2long(g,Lwin_new);
        else
            g_new = g;
        end
        weight = sqrt(sum(reshape(abs(g_new).^2,a,N_win),2));
        
        gt = g_new./repmat(weight,N_win,1);
        gt = gt/sqrt(M);
        if Lwin_new ~= info.gl
            gt = long2fir(gt,info.gl);
        end
        
    else
        
        % Long window case
        
        % Just in case, otherwise the call is harmless. 
        g=fir2long(g,L);
        
        gt=comp_gabtight_long(g,a,M)*scale;
        
    end;

else
    
    % Just in case, otherwise the call is harmless. 
    g=fir2long(g,L);

    if (kv.nsalg==1) || (kv.nsalg==0 && lt(2)<=2) 
        
        mwin=comp_nonsepwin2multi(g,a,M,lt);
        
        gtfull=comp_gabtight_long(mwin,a*lt(2),M)*scale;
        
        % We need just the first vector
        gt=gtfull(:,1);
            
    else
        b=L/M;
        s=b*lt(1)/lt(2);
        
        [s0,s1,br] = shearfind(a,b,s,L);
        
        if s1 ~= 0
            g = pchirp(L,s1).*g;
        end
        
        if s0 ~= 0
            g = ifft(pchirp(L,-s0).*fft(g));
        end
        
        Mr = L/br;
        ar = a*b/br;
        
        gt=comp_gabtight_long(g,ar,Mr);
        
        if s0 ~= 0
            gt = ifft(pchirp(L,s0).*fft(gt));
        end
        
        if s1 ~= 0
            gt = pchirp(L,-s1).*gt;
        end
    end;
    
    if (info.gl<=M) && (R==1)
        gt=long2fir(gt,M);
    end;
    
end;

% --------- post process result -------

if isreal(g) && (lt(2)==1 || lt(2)==2)
  % If g is real and the lattice is either rectangular or quinqux, then
  % the output is known to be real.
  gt=real(gt);
end;

if info.wasrow
  gt=gt.';
end;
