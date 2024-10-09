function err=immae(im1,im2)
% function for calculating the mae between 2 images
% input:
% im1 - original image
% im2 - deformed image
% output:
% acc - accuracy

err=sum(abs(im1(:)-im2(:)))/numel(im1);
