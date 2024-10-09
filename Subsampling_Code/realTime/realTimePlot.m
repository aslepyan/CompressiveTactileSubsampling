% This file is for plotting figures for the application of the real-time
% reconstruction and classification.
clc; close all; clear;
addpath ..\utils\

%% data collection (copy-paste style)
% measurement level
M = [50,100,200,300,400,500];

% full raster
t_FR = 18.214; % ms

% storage of time of subsampling
t_sam = [0.897,1.789,3.594,5.393,7.196,9.008]; % ms

% storage of total time of subsampling+recon
t_recon_total(5) = struct("dict_size",[],"data",[]);
i=1;

% dict_size = 200
t_recon_total(i).dict_size=200;
t_recon_total(i).data=[2.519,6.572,17.325,28.645,39.017,44.015]; % ms
t_recon_total(i).acc=[840.84,863.78,883.84,888.38,895.8,901.9]; % support acc
i=i+1;

% dict_size = 100
t_recon_total(i).dict_size=100;
t_recon_total(i).data=[1.69,4.262,11.364,18.255,24.594,28.688]; % ms
t_recon_total(i).acc=[828.54,856.48,876.5,889.06,894.94,897.8]; % support acc
i=i+1;

% dict_size = 50
t_recon_total(i).dict_size=50;
t_recon_total(i).data=[1.388,3.504,8.429,13.237,17.924,21.035]; % ms
t_recon_total(i).acc=[836.2,850.76,866.6,887,892.36,900.26]; % support acc
i=i+1;

% dict_size = 300
t_recon_total(i).dict_size=300;
t_recon_total(i).data=[3.43,8.681,23.745,37.654,51.284,57.919]; % ms
t_recon_total(i).acc=[842.32,870.02,891.28,894.02,897.5,900.1]; % support acc
i=i+1;

% dict_size = 500
t_recon_total(i).dict_size=500;
t_recon_total(i).data=[4.237,11.906,34.568,57.893,72.521,92.913]; % ms
t_recon_total(i).acc=[852.12,864.24,886.46,889.18,893.68,896.52]; % support acc
i=i+1;

% dict_size = 400
t_recon_total(i).dict_size=400;
t_recon_total(i).data=[3.685,10.886,29.864,47.776,58.638,74.095]; % ms
t_recon_total(i).acc=[845.4,862.9,882.26,887.7,895.3,899.62]; % support acc
i=i+1;

% storage of total time of subsampling+class
t_class_total(2) = struct("dict_size",[],"data",[]);
i=1;

% dict_size = 60
t_class_total(i).dict_size=60;
t_class_total(i).data=[1.24,2.47,4.92,7.36,9.81,12.23]; % ms
i=i+1;

% dict_size = 90
t_class_total(i).dict_size=90;
t_class_total(i).data=[1.501,2.68,5.34,7.99,10.64,13.29]; % ms
i=i+1;

%% M-fs plot for recon, subsampling
f1 = figure("Name",sprintf("M-fs for recon and subsampling"),'Position', [100, 100, 800, 600]);
dataArr = [2,3];
plotSetting = ["-.ko","-.bo"];
kk=1;
% plot the line for binary subsampling speed
plot(M, 1./t_sam*1e3, "--k*", 'DisplayName', sprintf('Binary Subsampling'));
hold on;
for idata=dataArr
    plot(M, 1./t_recon_total(idata).data*1e3, plotSetting(kk), 'DisplayName', sprintf('Binary subsampling+Reconstuction\nK_{pat}=%d',t_recon_total(idata).dict_size));
    kk=kk+1;
end
% plot the line for full raster speed
plot([0,500], 1./[t_FR t_FR]*1e3, 'r--', 'LineWidth', 2,'DisplayName', sprintf('Full raster'));
hold off;
xlabel('Number of measurements (M)');
ylabel(sprintf('Frame rate (s^{-1})'));
xlim([0,M(end)]);
% ylim([0,1024]);
legend;

folder = '..\..\paperFig\fig8';
filePath = fullfile(folder, 'M_fs_recon.fig');
saveas(gcf, filePath);

%% M-fs plot for varing size of dict
f2 = figure("Name","M-fs for varing dict for recon",'Position', [100, 100, 800, 600]);
dataArr = [1,2,3,4,5];
dict_sizeArr = 0*dataArr;
plotSetting = ["-ro","-bo","-go","-mo","-ko"];
for idata=1:numel(dataArr)
    dict_sizeArr(idata)=t_recon_total(dataArr(idata)).dict_size;
end
[~,ind]=sort(dict_sizeArr);
hold on;
for idata=dataArr(ind)
    plot(M, 1./(t_recon_total(idata).data-t_sam)*1e3, plotSetting(idata), 'DisplayName', sprintf('K_{pat}=%d',t_recon_total(idata).dict_size));
end
hold off;
xlabel('Number of measurements (M)');
ylabel(sprintf('Frame rate (s^{-1})'));
xlim([0,M(end)]);
% ylim([0,1024]);
legend;

folder = '..\..\paperFig\fig8';
filePath = fullfile(folder, 'M_fs_recon_dict.fig');
saveas(gcf, filePath);

%% heat map of fs and contour of accuracy by varing size of dict and M
f4 = figure("Name","heat map and contour",'Position', [100, 100, 800, 600]);
dataArr = [1,2,3,4,5,6];
dict_sizeArr = 0*dataArr;
for idata=1:numel(dataArr)
    dict_sizeArr(idata)=t_recon_total(dataArr(idata)).dict_size;
end
[dict_sizeArr1,ind]=sort(dict_sizeArr);

% get the data of fs
fs_map = zeros(numel(dataArr),numel(M));
kk=1;
for idata=dataArr(ind)
    fs_map(kk,:) = 1./(t_recon_total(idata).data-t_sam)*1e3;
    kk=kk+1;
end

% get the data of support accuracy
acc_map = zeros(numel(dataArr),numel(M));
kk=1;
for idata=dataArr(ind)
    acc_map(kk,:) = t_recon_total(idata).acc;
    kk=kk+1;
end

% interpolate fs for plotting
[X,Y] = meshgrid(M,dict_sizeArr1);
M1=50:50:500; % !!
dict_sizeArr11=50:50:500; % !!
[Xq,Yq] = meshgrid(M1,dict_sizeArr11);
fs_map1 = interp2(X,Y,fs_map,Xq,Yq);
acc_map1 = interp2(X,Y,acc_map,Xq,Yq);

imagesc(M1,dict_sizeArr11,fs_map1);
colormap("turbo");
% xTickLabels = cellstr(num2str(M(:)));
% yTickLabels = cellstr(num2str(dict_sizeArr1(:)));
% set(gca, 'XTick', 1:numel(M), 'XTickLabel', xTickLabels);
% set(gca, 'YTick', 1:numel(dict_sizeArr1), 'YTickLabel', yTickLabels);
xlabel('Number of measurements (M)');
ylabel(sprintf('Patch dictionary size (K_{pat})'));
c = colorbar;
ylabel(c, sprintf("Frame rate (s^{-1})"));
% clim([0 2100]);
hold on;
[Ccontour, hContour]=contour(Xq,Yq,acc_map1,8,'LineWidth',1.2,'LineColor','r',"ShowText",true,"LabelFormat","%0.1f","LabelSpacing",200);
clabel(Ccontour,hContour,'FontSize',12,'Color','m');
hold off;

folder = '..\..\paperFig\fig8';
filePath = fullfile(folder, 'heatmap_recon_M_dict.fig');
saveas(gcf, filePath);

%% heat map of support accuracy by varing size of dict and measurement level (M)
f4 = figure("Name","heat map for varing dict for recon (acc)",'Position', [100, 100, 800, 600]);
dataArr = [1,2,3,4,5,6];
dict_sizeArr = 0*dataArr;
for idata=1:numel(dataArr)
    dict_sizeArr(idata)=t_recon_total(dataArr(idata)).dict_size;
end
[dict_sizeArr1,ind]=sort(dict_sizeArr);

acc_map = zeros(numel(dataArr),numel(M));
kk=1;
for idata=dataArr(ind)
    acc_map(kk,:) = t_recon_total(idata).acc;
    kk=kk+1;
end
imagesc(acc_map);
colormap("turbo");
xTickLabels = cellstr(num2str(M(:)));
yTickLabels = cellstr(num2str(dict_sizeArr1(:)));
set(gca, 'XTick', 1:numel(M), 'XTickLabel', xTickLabels);
set(gca, 'YTick', 1:numel(dict_sizeArr1), 'YTickLabel', yTickLabels);
xlabel('Number of measurements (M)');
ylabel(sprintf('Patch dictionary size (K_{pat})'));
c = colorbar;
ylabel(c, sprintf("Support Accuracy"));
% clim([0 2100]);

folder = '..\..\paperFig\fig8';
filePath = fullfile(folder, 'heatmap_recon_dict_acc.fig');
saveas(gcf, filePath);

%% M-fs plot for classification, subsampling
f3 = figure("Name",sprintf("M-fs for classification and subsampling"),'Position', [100, 100, 800, 600]);
dataArr = [2,1];
plotSetting = ["-.ksquare","-.bsquare"];
kk=1;
% plot the line for binary subsampling speed
plot(M, 1./t_sam*1e3, "--k*", 'DisplayName', sprintf('Binary Subsampling'));
hold on;
for idata=dataArr
    plot(M, 1./t_class_total(idata).data*1e3, plotSetting(kk), 'DisplayName', sprintf('Binary subsampling+Classification\nL=%d',t_class_total(idata).dict_size));
    kk=kk+1;
end
% plot the line for full raster speed
plot([0,500], 1./[t_FR t_FR]*1e3, 'r--', 'LineWidth', 2,'DisplayName', sprintf('Full raster'));
hold off;
xlabel('Number of measurements (M)');
ylabel(sprintf('Frame rate (s^{-1})'));
xlim([0,M(end)]);
% ylim([0,1024]);
legend;

folder = '..\..\paperFig\fig8';
filePath = fullfile(folder, 'M_fs_class.fig');
saveas(gcf, filePath);
