function  varargout = block_interface(varargin)
%BLOCK_INTERFACE Common block processing backend
%
%
%
%
%
%
%  Object-like interface for sharing data between block handling
%  functions. 

if nargin<1
     error('%s: Too few input parameters.',upper(mfilename));
end

% Persistent data
persistent pos;
persistent pageNo;
persistent sourceName;
persistent maxBufCount;
persistent pageList;
persistent playChanList;
persistent recChanList;
persistent skipCounter;

persistent classid;
persistent toPlayBlock;
persistent anaOverlap;
persistent synOverlap;
persistent dispLoad;

persistent Ls;

persistent loop;

% DEFAULTS
persistent bufLen;



command = varargin{1};



switch command
   case {'reset','clearAll'}
      pos = 0; 
      sourceName = [];
      maxBufCount = 3;
      pageList = [];
      playChanList = [];
      recChanList = [];
      pageNo = 0;
      skipCounter = 0;
      classid = 'double';
      anaOverlap = [];
      synOverlap = [];
      toPlayBlock = [];
      dispLoad = 1;
      loop = 0;
      Ls = -1;
%% SETTERS %%%
   case 'setLs'
      Ls = varargin{2};
   case 'setPos'
      pos = varargin{2};
   case 'setBufCount'
      maxBufCount = varargin{2};
   case 'setPlayChanList'
      playChanList = varargin{2};
   case 'setRecChanList'
      recChanList = varargin{2};
   case 'setPageNo'
      pos = varargin{2};
   case 'setSkipped'
      skipCounter = varargin{2};
   case 'setBufLen'
      bufLen = varargin{2}; 
   case 'setClassId'
      classid = varargin{2};
   case 'setAnaOverlap'
      anaOverlap = varargin{2};
   case 'setSynOverlap'
      synOverlap = varargin{2};
   case 'setDispLoad'
      dispLoad = varargin{2};
   case 'setToPlay'
      toPlayBlock=varargin{2};
   case 'setIsLoop'
      loop = varargin{2};
   case 'setSource'
      sourceName = varargin{2};
%% GETTERS %%%
   case 'getLs'
      varargout{1}=Ls;
   case 'getPos'
      varargout{1}=pos;
   case 'getBufCount'
      varargout{1}= maxBufCount;
   case 'getPlayChanList'
      varargout{1}=playChanList;
   case 'getRecChanList'
      varargout{1}=recChanList; 
   case 'getPageList'
      varargout{1}=pageList; 
   case 'getPageNo'
      varargout{1}=pageNo; 
   case 'getSkipped'
      varargout{1}=skipCounter; 
   case 'getBufLen'
      varargout{1}=bufLen; 
   case 'getClassId'
      varargout{1}=classid; 
   case 'getAnaOverlap'
      varargout{1}=anaOverlap;
   case 'getSynOverlap'
      varargout{1}=synOverlap;
   case 'getDispLoad'
      varargout{1}=dispLoad;
   case 'getToPlay'
      varargout{1}=toPlayBlock; 
      toPlayBlock = [];
   case 'getIsLoop'
      varargout{1}=loop;
   case 'getSource'
      if isnumeric(sourceName)
         varargout{1}='numeric';
      else
         varargout{1}=sourceName;
      end
   case 'getEnqBufCount'
      varargout{1}= numel(pageList);

%% OTHER %%%
   case 'incPageNo'
      pageNo = pageNo +1;
   case 'popPage'
      varargout{1}=pageList(1);
      pageList = pageList(2:end);
   case 'pushPage'
      pageList = [pageList, varargin{2}];   


%   case 'incSkipped'
%      skipCounter = skipCounter + varargin{2};
%   case 'readNumericBlock'
%      L = varargin{2};
%      varargout{1}=sourceName(pos+1:pos+1+L,:); 
   otherwise
      error('%s: Unrecognized command.',upper(mfilename));
end

