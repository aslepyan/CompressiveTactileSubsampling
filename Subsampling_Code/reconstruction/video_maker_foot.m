%% Tennis_ball
close all
clear all
idx = 2;
Ms = [64,128,256,512];
M = Ms(idx);
nrow=64;
ncol=16;
numSensor=ncol*nrow;
load(['recData',num2str(M),'.mat'])
v = VideoWriter(['foot_',num2str(M)]);
cmap = colormap; % get the current colormap
new_cmap = [0 0 0; cmap]; % define the new colormap with black for the negative value
valMax = max(max(max(recarrayData)));
valMin = -6;
colormap(new_cmap);
% for i = 1:length(recarrayData(1,1,:))
%     image([recarrayData(:,:,i), zeros(64,1),raw_data(:,:,i)]);
%     axis equal;
%     clim([valMin valMax]);
%     title(i)
% %    pause(0.1)
%     drawnow
% end
fss = [887.3114,443.4590,221.8279,110.870];
fs = fss(idx);
% 64, 128, 256, 512

% 960 FPS --> playing as 100X slow motion
% plays at 9.6 FPS
% To slow tactile down by 100X --> it should play at Fs/100

v.FrameRate = fs/4;

open(v)

for i = 1:length(recarrayData(1,1,:))
    % simulation for non press frame
    if (all(raw_data(:,:,i)==0,'all'))
        temp1 = valMin*ones(nrow,ncol);
        temp1(randperm(numSensor,M))=0;
        raw_data(:,:,i)=temp1;
    end

    imagesc([recarrayData(:,:,i), zeros(64,1),raw_data(:,:,i)]);
    axis equal;
    clim([valMin valMax]);
    drawnow
    frame = getframe(gcf);
    writeVideo(v,frame)
end

close(v)

%% Zero video
close all
fz = zeros(64,16)-6;
v = VideoWriter('foot_zero');
v.FrameRate = fs/100;
open(v)

cmap = colormap; % get the current colormap
new_cmap = [0 0 0; cmap];
colormap(new_cmap);

for i = 1:100
    image(fz);
    axis equal;
    clim([valMin valMax]);
    frame = getframe(gcf);
    writeVideo(v,frame)
end
close(v)

