% This function plot the relation between the force applied to the sensor
% and the measurement (of resistance) of sensor.
weightOutputArr = [
    0,0;
    10,0;
    20,447;
    30,3794;
    40,5763;
    50,7526;
    70,8301;
    100,12495;
    200,16690;
    300,20019;
    400,26590;
    500,29089;
    600,32083;
    700,35461;
    800,38823;
    ]; % units: g, AU, !!

contactArea = 60; % number of pixels, !!

% plotting
figure;
plot(weightOutputArr(:,1),weightOutputArr(:,2)/contactArea,"-k","LineWidth",2,"Marker",".","MarkerSize",20)
xlabel("Weight (g)")
ylabel("Average output per taxel (A.U.)")
xlim([0,max(weightOutputArr(:,1))]);

% save fig
folder = '..\..\paperFig\';
filePath = fullfile(folder, 'forceR.fig');
saveas(gcf, filePath);
