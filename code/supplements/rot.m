function rot()
% This function is for the rotator experiment
crtpwd = pwd;
upwd = fileparts(crtpwd);
uupwd = fileparts(upwd);

% collect and prune the raw data
% extract the name of folder for each object
dataStorageFolder= 'Rotator_Data';
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);
nObj = length(dataNameList);

% total num of sensors
thr = 180; % !!
nM = 4; % !!
nMode = 1; % !!
nWin = 1; % !!
% struct used for storage of experiment data for subsequent plotting
forceStr(nWin,nM,nMode,nObj) = struct("time",[],"force",[]);
data = []; % dummy var

for iObj=1:nObj
    % load data
    dataFolderName = dataNameList(iObj).name;
    fprintf([dataFolderName,'|%d/%d\n'],iObj,nObj);
    dataFileName = [dataFolderName, '.mat'];
    fullpath = fullfile(uupwd, 'data',dataStorageFolder, dataFolderName, dataFileName);
    load(fullpath)

    for modeNum = samplingMode
        iMode = find(samplingMode==modeNum);

        for msrNum = M
            iM = find(M==msrNum);

            fs=data(1,end,1,iM,iMode);
            num_frames = floor(fs * save_time);

            forceHis=zeros(1,num_frames);
            timeHis=0:1/fs:save_time-1/fs;

            for iWin=1:nWin
                for i=1:num_frames
                    LL=(i-1)*msrNum+1:i*msrNum;
                    temp=data(2,LL,iWin,iM,iMode);
                    temp=temp.*(temp>thr);

                    forceHis(i)=max(temp); % !!
                end
                forceStr(iWin,iM,iMode,iObj).time=timeHis;
                forceStr(iWin,iM,iMode,iObj).force=forceHis;
            end
        end
    end
end

f1 = figure("Name",sprintf("rot"),'Position', [0,0,800,1000]);
plotSetting_M=["-r","-b","-g","-m"];
iWin=1;
iMode=1;
for iObj=1:nObj
    dataFolderName = dataNameList(iObj).name;
    subplot(nObj,1,iObj);
    hold on;
    for iM=1:nM
        timeHis = forceStr(iWin,iM,iMode,iObj).time;
        forceHis = forceStr(iWin,iM,iMode,iObj).force;

        % extract the time segment when rotator hits the sensor
        % periodically
        time_thr = 0.7; % unit: s, !!
        forceHis = forceHis(timeHis>time_thr);

        fs = 1/mean(diff(timeHis)); % sampling frequency
        L = length(forceHis); % length of the signal
        % handle the case when the num of signal is odd
        if mod(L,2)==1
            % delete the 1st elem of an array of signal
            forceHis(1)=[];
            L=L-1;
        end
        fftHis = forceHis - mean(forceHis);
        Y = fft(fftHis);
        P2 = abs(Y/L);
        P1 = P2(1:L/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        f = fs*(0:(L/2))/L;

        % extract the first peak of Single-Sided Amplitude Spectrum
        [pks,locs] = findpeaks(P1,f,'MinPeakHeight',50);
        loc_thr = locs(1)+min(0.5*(locs(2)-locs(1)),5);
        P1(f>loc_thr)=0;

        plot(f,P1,plotSetting_M(iM),'LineWidth',1,'DisplayName',sprintf(['M=%d'],M(iM)));
    end
    hold off;
    title(sprintf(['',convertText(dataFolderName)]));
    xlabel("f (Hz)")
    ylabel("|P1(f)|")
    xlim([0,80]);

    if iObj==4
        legend('Location', 'bestoutside','Orientation','horizontal','Position', [0.5, 0.07, 0.003, 0.01]);
    end
end

% save fig
folder = '..\..\paperFig\figS_rotator\';
filePath = fullfile(folder, 'rot.fig');
saveas(gcf, filePath);

% test()
end

function test()
figure;
iWin=1;
iM=1;
iMode=1;
iObj=5;
timeHis=forceStr(iWin,iM,iMode,iObj).time;
forceHis=forceStr(iWin,iM,iMode,iObj).force;
plot(timeHis,forceHis,'--.',MarkerSize=10,DisplayName=sprintf('Measurement Level: %d',M(iM)));
xlabel('time (s)');
ylabel('force (A.U.)');
legend('Location', 'eastoutside');
end

% This function converts text like 'xxxx3p5V' to '3.5V'
function output = convertText(input)    
    % Find where the digits and the 'p' (for decimal point) are located
    pattern = '\d+p\d+|\d+';
    numericPart = regexp(input, pattern, 'match', 'once');
    
    % Replace 'p' with '.' to create the decimal format
    if contains(numericPart, 'p')
        numericPart = strrep(numericPart, 'p', '.');
    end
    
    % Extract the trailing character (like 'V')
    trailingChar = regexp(input, '[A-Za-z]+$', 'match', 'once');
    
    % Combine the numeric part and the trailing character
    output = [numericPart trailingChar];
end
