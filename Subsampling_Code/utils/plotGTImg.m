function plotGTImg(iObj)
% This function plots each ground truth tactile img

load ..\archieveData\GTImg.mat

numWindow=10;

figure;
for idxWindow=1:numWindow
    img = reshape(GTImgArr(:,idxWindow,iObj),[32,32])';
    % img = circshift(img,[2,2]);
    imagesc(img)
    title(sprintf('%d',idxWindow))
    colorbar;
    clim([0 1023]);
    axis equal;

    pause(0.5);
end
