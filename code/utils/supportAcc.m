function acc=supportAcc(im1,im2,thr)
% function for calculating the support accuracy
% input:
% im1 - original image
% im2 - deformed image
% thr - thr of pixel value to be set to 0
% output:
% acc - accuracy

temp=((im1>thr)*2-1).*((im2>thr)*2-1);
acc = sum(temp==1,'all')-sum(temp==-1,'all');
