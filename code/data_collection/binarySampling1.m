function binarySampling1()
global M save_time data numWindow samplingMode numSensor numWindowTotal idxWindowTotal;

port = serialportlist;
s = serialport(port(1),12E6);
flush(s);

identity = 'binarySampling';
% conversion table for relation between num of measured sensors (per frame)
% and time per frame (us)
timePerFrameArr = [
    50, 884;
    55, 973;
    60, 1062;
    100, 1781;
    200, 3612;
    300, 5492;
    400, 7424;
    500, 9509;
    600, 11435;
    700, 13517;
    800, 15647;
    900, 17828;
    1000, 20059;

    10, 177;
    30, 530;
    36, 620;
    42, 719;
    48, 849;
    49, 866;
    56, 991;
    64, 1106;
    66, 1170;
    77, 1367;
    88, 1564;
    96, 1647;
    112, 1917;
    121, 2161;
    128, 2288;
    160, 2873;
    176, 3167;
    192, 3463;
    224, 4057;
    256, 4544;
    352, 6024;
    512, 8760;
    1024, 20601;
    ];

idxMode = find(samplingMode==3); % 3 means the mode is binary

for idxM = 1:length(M)
    msrNum = M(idxM);

    % calculation of params (fs (sampling rate), frame num) for each M
    fs = 1/timePerFrameArr(timePerFrameArr(:,1)==msrNum,2)*1e6; % s-1

    % calculation of num of frames per window
    num_frames = floor(fs * save_time);

    total_num = msrNum * num_frames; % num of msr sensor per 2s-window

    % store fs
    data(1,end,1,idxM,idxMode) = fs;

    % give initiation signal to arduino
    megary = [3 msrNum num_frames]; % 3 means the mode is binary
    str = sprintf('%d,', megary);

    flush(s)
    writeline(s, str); % start the main program of Arduino

    idxWindow = 1;
    while idxWindow<=numWindow
        isStart=input("press enter to start!","s");
        writeline(s, ['a',isStart]); % signal to start the window
        try
            disp([identity, '|msrNum ',num2str(msrNum), '|Window ', num2str(idxWindow), '|', num2str(idxWindowTotal), '/', num2str(numWindowTotal)]);
            input1 = split(readline(s),',');
        catch
            writeline(s, 'stop'); % stop the main program of Arduino

            clear s
            s = serialport(port,12E6);
            disp('re-connected')

            flush(s)
            writeline(s, str);

            continue;
        end

        if length(input1)~=(total_num*2+1+1)
            % sometimes > also happens, need to avoid.
            disp('read data error');
            
            continue;
        end

        % extract the pos and measurement
        vals = double(input1(1:end-2));
        data(:,1:(msrNum*num_frames),idxWindow,idxM,idxMode) = reshape(vals, 2, []);

        disp(input1(end-1));

        idxWindow = idxWindow+1;
        idxWindowTotal = idxWindowTotal+1;
    end
end

writeline(s, 'z'); % stop the main program of Arduino
clear s
