function visMat = insoleConv(im)
% convert the location to adapt insole sensor for visualization
% 1024 sensor, val range 0-1023
% left insole
im = reshape(im', [64 16]);
im(1:32,:) = flipud(im(1:32,:));
visMat=rot90(im,2);
