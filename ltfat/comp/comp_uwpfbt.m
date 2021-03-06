function c=comp_uwpfbt(f,wtNodes,rangeLoc,nodesUps)
%COMP_UWPFBT Compute Undecimated Wavelet Packet Filterbank Tree
%   Usage:  c=comp_uwpfbt(f,wtNodes,nodesUps);
%
%   Input parameters:
%         f        : Input data as L*W array.
%         wtNodes  : Filterbank tree nodes (elementary filterbanks) in
%                    BF order. Cell array of structures of length *nodeNo*.
%         nodesUps : Filters upsampling factor of each node. Array of
%                    length *nodeNo*. 
%
%   Output parameters:
%         c        : Coefficients stored in L*M*W array.
%

% Pre-allocated output
[L, W] = size(f);
M = sum(cellfun(@(wtEl) numel(wtEl.h),wtNodes));
c = zeros(L,M,W,assert_classname(f,wtNodes{1}.h{1}.h));

% Convenience input reshape
ca = reshape(f,size(f,1),1,size(f,2));
cOutRunIdx = 1;
cInRunIdxs = [1];
% For each node in tree in the BF order...
for jj=1:numel(wtNodes)
   % Node filters subs. factors
   a = wtNodes{jj}.a;
   % Node filters to a matrix
   hMat = cell2mat(cellfun(@(hEl) conj(flipud(hEl.h(:))),wtNodes{jj}.h(:)','UniformOutput',0));
   % Normalize each each filter
   hMat = bsxfun(@rdivide,hMat,sqrt(a(:)'));
   % Node filters initial skips
   hOffet = cellfun(@(hEl) 1-numel(hEl.h)-hEl.offset,wtNodes{jj}.h);
   % Number of filters of the current node
   filtNo = size(hMat,2);
   % Zero index position of the upsampled filters.
   offset = nodesUps(jj).*(hOffet);

   % Run filterbank
   c(:,cOutRunIdx:cOutRunIdx + filtNo-1,:)=...
      comp_atrousfilterbank_td(squeeze(ca(:,1,:)),hMat,nodesUps(jj),offset);
   
   % Bookkeeping
   outRange = cOutRunIdx:cOutRunIdx+filtNo-1;
   outRange(rangeLoc{jj}) = [];
   cInRunIdxs = [cInRunIdxs(2:end),outRange];
   
   cOutRunIdx = cOutRunIdx + filtNo;
   
   % Prepare input for the next iteration
   if ~isempty(cInRunIdxs)
      c(:,cInRunIdxs(1),:) = c(:,cInRunIdxs(1),:)/sqrt(2);
      ca = c(:,cInRunIdxs(1),:);
   end
end   


