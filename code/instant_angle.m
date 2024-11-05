% This file is for tract the instant angle of bouncing objects on the
% sensor
close all; clear; clc

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% extract the names of data files
dataStorageFolder= 'ricochet_angle_data';
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);

numObject=length(dataNameList);

nrow = 32; % number of rows
ncol = 32; % number of columns
numSensor = nrow*ncol;
pressThreshold = 50; % thr for the smaller sensor

% plot settings
%f1=figure("Name","classic");
cmap = colormap; % get the current colormap
new_cmap = [0 0 0; cmap]; % define the new colormap with black for the negative value
valMin = -6; % negative value assigned to the unsampled pixels
valMax = 300; % max value of measurement values
modeName = ["Down-Sampling","Random Sampling","Binary Sampling"]; % name of the subsampling method

disp('Data visualization process initiated...');
for dataNameIdx=5%:numObject % !!
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the subsampling and recovered data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    recSignalFileName = ['RecSignal1_', dataFolderName, '.mat'];
    datapath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, dataFileName);
    recDatapath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, recSignalFileName);
    disp('data loading...');
    load(datapath)
    load(recDatapath)
    disp('data loaded successfully!');

    numMode = numel(samplingMode);
    numM = numel(M);

    for modeNum = samplingMode
        idxMode = find(samplingMode==modeNum);

        for msrNum = M
            if msrNum==numSensor
                continue;
            end

            idxM = find(M==msrNum);
            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            for idxWindow = 1:numWindow
                xHis = savedRcvSg(idxWindow,idxM,idxMode).data;
                xHisIdx = 1;

                % array for stroage of COM and rec img
                comArr=zeros(50,2);
                imgArr=zeros(numSensor,50);
                kk=1;

                for i=savedRcvSg(idxWindow,idxM,idxMode).recFrameIdx'
                    % prepare subsampling data
                    rawData = valMin*ones(nrow,ncol);

                    for msr = 1:msrNum
                        temp = data(2,((i-1)*msrNum)+msr,idxWindow,idxM,idxMode);
                        temp1=data(1,((i-1)*msrNum)+msr,idxWindow,idxM,idxMode); % 0-1023
                        x=floor(temp1/ncol)+1; % row ind
                        y=mod(temp1,ncol)+1; % col ind
                        rawData(x,y)=temp*(temp>pressThreshold);
                    end

                    % prepare recovered data
                    recData = reshape(xHis(:,xHisIdx),[ncol,nrow])';
                    recData(recData<=pressThreshold)=0;
                    xHisIdx = xHisIdx+1;

                    % calculate the COM for each frame
                    [rowInd,colInd]=com(recData);
                    comArr(kk,:)=[rowInd,colInd];
                    imgArr(:,kk)=recData(:);
                    kk=kk+1;

                    % figure(f1)
                    % %plot subsampling data
                    % subplot(1,2,1);
                    % imagesc(rawData)
                    % colormap(new_cmap);
                    % colorbar;
                    % clim([valMin valMax]);
                    % title('Raw Data');
                    % axis equal;
                    %
                    % % plot recovered data
                    % subplot(1,2,2);
                    % imagesc(recData)
                    % colormap(new_cmap);
                    % colorbar;
                    % clim([valMin valMax]);
                    % title('Recovered Data');
                    % axis equal;
                    %
                    % sgtitle(sprintf(strcat(modeName(modeNum), "|msrNum %d|Window %d|%0.5fs"),msrNum,idxWindow,i/fs))
                    % drawnow
                end
                kk=kk-1;
                comArr=comArr(1:kk,:);
                imgArr=imgArr(:,1:kk);

                % delete some wrong tracking; !!
                de_fr=[kk-2:kk];

                % plot the figure
                angle=nameTransfer(dataFolderName); % convert the angle of incidence
                % make_figure(comArr,angle);
                make_figure2(comArr,imgArr,angle,de_fr);

                comArr(de_fr,:)=[];
                imgArr(:,de_fr)=[];

                % calculate the angle
                ang=ang_cal(comArr);
                disp(ang);
            end
        end
    end
end

% This function tracks the trajectory of COM of the bouncing ball with the
% recoverd images.
function make_figure2(arr1,arr2,angle,de_fr)
% arr1 - arr of COM
% arr2 - arr of images
% angle - angle of incidence of the bouncing ball
if size(arr1,1)<2 || size(arr2,2)<2
    error("The number of points in the trajectory is not enough!");
end


v = VideoWriter(['angle_',num2str(angle)]);
fs = 1177.9;
v.FrameRate = fs/400; %400X slower
open(v)

% Data extraction
y=arr1(:,1);
x=arr1(:,2);

%figure("Name","recCOM");
cmap = colormap; % get the current colormap
new_cmap = [0 0 0; cmap]; % define the new colormap with black for the negative value
valMin = -6; % negative value assigned to the unsampled pixels
valMax = 300; % max value of measurement values
for i = 1:length(x)
    recData=reshape(arr2(:,i),[32,32]);
    imagesc(recData)
    colormap(new_cmap);
    colorbar;
    clim([valMin valMax]);
    title(sprintf(['The angle of incidence is ',num2str(angle),'']));
    axis equal;
    hold on;
    % Plot current (and previous) COM(s) as dot(s)
    plot(x(1:i), y(1:i), 'ro', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
    % Plot arrows connecting the dots in order
    for j = 1:i-1
        % Calculate the change in x and y
        dx = x(j+1) - x(j);
        dy = y(j+1) - y(j);
        % Plot the arrow using quiver (arrows connecting consecutive points)
        line2=quiver(x(j), y(j), dx, dy, 0, 'MaxHeadSize', 10, 'Color', 'r', 'LineWidth', 3);
        uistack(line2, "top");
    end
    xlim([0 32])
    ylim([0 32])
    drawnow
    if i<length(x)
        frame = getframe(gcf);
        writeVideo(v,frame)
    end
    saveas(gcf,['angle',num2str(i)],'fig')
end
% draw the total arrow
x(de_fr)=[];
y(de_fr)=[];
% Calculate the change in x and y
dx = x(end) - x(1);
dy = y(end) - y(1);
% Plot the arrow using quiver (arrows connecting consecutive points)
% quiver(x(1), y(1), dx, dy, 0, 'MaxHeadSize', 10, 'Color', 'k', 'LineWidth', 5);
factor =10;
line1=quiver(x(1) - dx*factor/2, y(1) - dy*factor/2, factor*dx, factor*dy, 0, 'MaxHeadSize', .2, 'Color', 'k', 'LineWidth', 5);
uistack(line2, "top");
drawnow
hold off;
xlim([0 32])
ylim([0 32])
frame = getframe(gcf);
saveas(gcf,['angle',num2str(i+1)],'fig')
for i = 1:10 %write last frame several times... (for video)
    writeVideo(v,frame)
end
close(v)
end

% This function tracks the trajectory of the bouncing ball.
function make_figure(arr,angle)
% arr - arr of COM
% angle - angle of incidence of the bouncing ball
if size(arr,1)<2
    error("The number of points in the trajectory is not enough!");
end

% Data extraction
y=arr(:,1);
x=arr(:,2);

% Plot the scatter points
%figure("Name","COM");
scatter(x, y, 20, 'filled');  % 100 is the marker size
hold on;

% Plot arrows connecting the points in order
for i = 1:length(x)-1
    % Calculate the change in x and y
    dx = x(i+1) - x(i);
    dy = y(i+1) - y(i);

    % Plot the arrow using quiver (arrows connecting consecutive points)
    quiver(x(i), y(i), dx, dy, 0, 'MaxHeadSize', 1, 'Color', 'r', 'LineWidth', 3);
end

% Set x and y axis limits to [0, 32]
xlim([0, 32]);
ylim([0, 32]);

% Flip the y-axis
set(gca, 'YDir', 'reverse');

title(sprintf(['The angle of incidence is ',num2str(angle),'']));
grid on;
hold off;
end

% This function calculates the angle of incidence of the bouncing ball by
% averaging the difference of vector.
function ang = ang_cal(arr)
if size(arr,1)<2
    error("The number of points in the trajectory is not enough!");
end
delta_arr = arr(2:end,:)-arr(1:end-1,:);

avg_delta_vec = mean(delta_arr);

ang=rad2deg(atan(-avg_delta_vec(2)/avg_delta_vec(1)));
if avg_delta_vec(1)<0 && (avg_delta_vec(2)<0 || ang<20)
    ang=ang+180;
elseif avg_delta_vec(1)<0 && avg_delta_vec(2)>0 && ang>20
    ang=ang-180;
end
end
