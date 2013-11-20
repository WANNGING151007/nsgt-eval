function [g,info] = comp_window(g,a,M,L,lt,callfun);
%COMP_WINDOW  Compute the window from numeric, text or cell array.
%   Usage: [g,info] = comp_window(g,a,M,L,s,callfun);
%
%   [g,info]=COMP_WINDOW(g,a,M,L,lt,callfun) will compute the window
%   from a text description or a cell array containing additional
%   parameters.
%
%   This function is the driving routine behind GABWIN and WILWIN.
%
%   See the help on GABWIN and WILWIN for more information.
%
%   See also: gabwin, wilwin

  
% Basic discovery: Some windows depend on L, and some windows help define
% L, so the calculation of L is window dependant.
  
% Default values.
info.gauss=0;
info.wasrow=0;
info.isfir=0;
info.istight=0;
info.isdual=0;

isrect=(lt(2)==1);

% Manually get the list of window names
definput=arg_firwin(struct);
firwinnames =  definput.flags.wintype;

% Create window if string was given as input.
if ischar(g)
  winname=lower(g);
  switch(winname)
   case {'pgauss','gauss'}
    complain_L(L,callfun);
    g=comp_pgauss(L,a*M/L,0,0);
    info.gauss=1;
    info.tfr=a*M/L;
   case {'psech','sech'}
    complain_L(L,callfun);
    g=psech(L,a*M/L);
    info.tfr=a*M/L;
   case {'dualgauss','gaussdual'}
    complain_L(L,callfun);
    g=comp_pgauss(L,a*M/L,0,0);
    if isrect
      g=gabdual(g,a,M);
    else
      g=gabdual(g,a,M,'lt',lt);
    end;
    info.isdual=1;
    info.tfr=a*M/L;
   case {'tight'}
    complain_L(L,callfun);
    if isrect
      g=gabtight(a,M,L);
    else
      g=gabtight(a,M,L,'lt',lt);
    end;
    info.tfr=a*M/L;
    info.istight=1;
   case firwinnames
    [g,firinfo]=firwin(winname,M,'2');
    info.isfir=1;
    if firinfo.issqpu
      info.istight=1;
    end;
   otherwise
    error('%s: Unknown window type: %s',callfun,winname);
  end;
end;

if iscell(g)
  if isempty(g) || ~ischar(g{1})
    error('First element of window cell array must be a character string.');
  end;
  
  winname=lower(g{1});
  
  switch(winname)
   case {'pgauss','gauss'}
    complain_L(L,callfun);
    [g,info.tfr]=pgauss(L,g{2:end});
    info.gauss=1;
   case {'psech','sech'}
    complain_L(L,callfun);
    [g,info.tfr]=psech(L,g{2:end});    
   case {'dual'}
    gorig = g{2};   
    [g,info.auxinfo] = comp_window(gorig,a,M,L,lt,callfun);    
    if isrect
      g = gabdual(g,a,M,L);
    else
      g = gabdual(g,a,M,L,'lt',lt);
    end;
    % gorig can be string or cell array
    if info.auxinfo.isfir 
    % Original window is FIR, dual window is FIR if length of the original
    % window is <= M. This is true if the length was not explicitly
    % defined (gorig{2}).
      if iscell(gorig) && numel(gorig)>1 && isnumeric(gorig{2}) && gorig{2}<=M...
         || ischar(gorig)   
        info.isfir = 1; 
      end
    end
    info.isdual=1;
   case {'tight'}
    gorig = g{2};
    [g,info.auxinfo] = comp_window(gorig,a,M,L,lt,callfun);    
    if isrect
      g = gabtight(g,a,M,L);
    else
      g = gabtight(g,a,M,L,'lt',lt);
    end;
    % The same as in dual?
    info.istight=1;
   case firwinnames
    g=firwin(winname,g{2},'energy',g{3:end});
    info.isfir=1;
   otherwise
    error('Unsupported window type.');
  end;
end;

if isnumeric(g)
  if size(g,2)>1
    if size(g,1)==1
      % g was a row vector.
      g=g(:);
      info.wasrow=1;
    end;
  end;
end;

if rem(length(g),M)~=0
  % Zero-extend the window to a multiple of M
  g=fir2long(g,ceil(length(g)/M)*M);
end;

% Information to be determined post creation.
info.wasreal = isreal(g);
info.gl      = length(g);

if (~isempty(L) && (info.gl<L))
  info.isfir=1;
end;

function complain_L(L,callfun)
  
  if isempty(L)
    error(['%s: You must specify a length L if a window is represented as a ' ...
           'text string or cell array.'],callfun);
  end;


