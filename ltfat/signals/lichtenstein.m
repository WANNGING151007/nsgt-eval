function s=lichtenstein();
%LICHTENSTEIN  Load the 'lichtenstein' test image
%   Usage: s=lichtenstein;
% 
%   `lichtenstein` loads a $512 \times 512$ color image of a castle
%   Lichtenstein, `<http://en.wikipedia.org/wiki/Lichtenstein_Castle>`_.
% 
%   The returned matrix `s` consists of integers between 0 and 255.
% 
%   To display the image, simply use `image`:::
% 
%     image(lichtenstein); axis('image');
% 
%   See
%   `<http://commons.wikimedia.org/wiki/File:Lichtenstein_img_processing_test.png>`_.
%
%   See also: cameraman  

%   AUTHOR : Peter L. Søndergaard
%   TESTING: TEST_SIGNALS

if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

s=imread([f,'.png']);




