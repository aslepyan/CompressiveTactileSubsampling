function visMat = gloveConv(im)
% convert the location to adapt glove sensor for visualization
% 1024 sensor, val range 0-1023
% ini
bgVal = -10; % val of background for visualization
visMatSz1 = 40;
visMatSz2 = 55;
visMat = bgVal*ones(visMatSz1,visMatSz2);

% extraction
im = rot90(im);
palm        = im(17:32,9:32);
thumb       = im(17:32,1:8);
ind_finger  = im(1:16,1:8);
mid_finger  = im(1:16,9:16);
ring_finger = im(1:16,17:24);
pinky       = im(1:16,25:32);

% adjustment
thumb = imrotate(thumb-bgVal, 30, 'bilinear')+bgVal;
ring_finger = imrotate(ring_finger-bgVal, 0, 'bilinear')+bgVal;
pinky = imrotate(pinky-bgVal, 0, 'bilinear')+bgVal;

% size for location
[palmSz1,palmSz2] = size(palm);
[thumbSz1,thumbSz2] = size(thumb);
[ind_fingerSz1,ind_fingerSz2] = size(ind_finger);
[mid_fingerSz1,mid_fingerSz2] = size(mid_finger);
[ring_fingerSz1,ring_fingerSz2] = size(ring_finger);
[pinkySz1,pinkySz2] = size(pinky);

% make vis mat
leftSpace = 2;
bottomSpace = 2;
x1 = 8;
x2 = 2;
x3 = 3;
x4 = 3;
x5 = 3;
x6 = 7;
x7 = 3;
x8 = 17;
x9 = 3;
x10 = 27;
palmInd1 = visMatSz1-bottomSpace-palmSz1+1;
palmInd2 = leftSpace+thumbSz2+x2;
thumbInd1 = visMatSz1-bottomSpace-x1-thumbSz1+1;
thumbInd2 = leftSpace+1;
ind_fingerInd1 = palmInd1-x3-ind_fingerSz1;
ind_fingerInd2 = palmInd2-x4;
mid_fingerInd1 = palmInd1-x5-mid_fingerSz1;
mid_fingerInd2 = palmInd2+x6;
ring_fingerInd1 = palmInd1-x7-ring_fingerSz1;
ring_fingerInd2 = palmInd2+x8;
pinkyInd1 = palmInd1-x9-pinkySz1;
pinkyInd2 = palmInd2+x10;
visMat(palmInd1:palmInd1+palmSz1-1,palmInd2:palmInd2+palmSz2-1) = palm;
visMat(thumbInd1:thumbInd1+thumbSz1-1,thumbInd2:thumbInd2+thumbSz2-1) = thumb;
visMat(ind_fingerInd1:ind_fingerInd1+ind_fingerSz1-1,ind_fingerInd2:ind_fingerInd2+ind_fingerSz2-1) = ind_finger;
visMat(mid_fingerInd1:mid_fingerInd1+mid_fingerSz1-1,mid_fingerInd2:mid_fingerInd2+mid_fingerSz2-1) = mid_finger;
visMat(ring_fingerInd1:ring_fingerInd1+ring_fingerSz1-1,ring_fingerInd2:ring_fingerInd2+ring_fingerSz2-1) = ring_finger;
visMat(pinkyInd1:pinkyInd1+pinkySz1-1,pinkyInd2:pinkyInd2+pinkySz2-1) = pinky;
