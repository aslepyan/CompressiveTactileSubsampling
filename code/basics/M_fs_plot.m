% This file is for determining the relation between the measurement level
% (M) and sampling rate (fs).
close all;

load ..\archieveData\timePerFrameArr.mat

Mrange = 530;
plot(timePerFrameArr(1:end-1,1),1./timePerFrameArr(1:end-1,2)*1e6,'k.-','DisplayName',sprintf('Down-sampling'));
hold on
plot(timePerFrameArr(1:end-1,1),1./timePerFrameArr(1:end-1,2)*1e6,'b*-','DisplayName',sprintf('Random sampling'));
plot(timePerFrameArr2(14:end-1,1),1./timePerFrameArr2(14:end-1,2)*1e6,'go-','DisplayName',sprintf('Binary sampling'));
raster_plotX = 0:Mrange;
raster_fs = 1/timePerFrameArr(end,2)*1e6;
raster_plotY = raster_fs*ones(length(raster_plotX),1);
plot(raster_plotX,raster_plotY,'r--','MarkerSize',10,'DisplayName','Raster')
xlabel('number of measurements (M)');
ylabel('sampling rate (fs, unit: s-1)');
xlim([0,Mrange]);
legend;
text(25, 150, sprintf('fs_{raster} = 55 s^{-1}'),'FontSize', 12, 'Color', 'red');
hold off
