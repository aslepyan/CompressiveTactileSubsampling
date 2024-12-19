%% figure of merit
% figure of merit can be an 'efficiency thing' --> 
% ~num of operations to achieve a particular "total sample speed"
% i.e. FOM = numADCreads * numsensors / speed

close all
clear all
SensorNum = ...
    [548
    216
    859
    1024
    1936
    162
    504
    34
    475
    960
    1864];

SamplingRate = ...
    [7
    14
    100
    10
    100
    30
    40
    20
    20
    100
    20];

ADCRate = SamplingRate.*SensorNum;

str = string(1:11);

for i = 1:11
    str(i) = "["+str(i)+"]";
end

%figure
%textscatter(x,y,str);
%scatter(SensorNum,SamplingRate,str)
%hold on
%scatter(1024,1000,'*')
textscatter(SensorNum,SamplingRate,str,"TextDensityPercentage",100)
hold on
textscatter(1024,1000,"★ This work","TextDensityPercentage",100)
ylim([-100 1100])
xlim([-100 2000])
xlabel('Number of Sensors')
ylabel('Sampling Rate (Hz)')
%% FOM
close all
x = ADCRate;
textscatter(x,ADCRate,str,"TextDensityPercentage",100)
hold on
[p,S] = polyfit(x,ADCRate,1);
indx = 1:2000;
[y_fit,delta] = polyval(p,indx,S);
plot(indx,y_fit,'r-','LineWidth',1)
plot(indx,y_fit+2*delta,'m--',indx,y_fit-2*delta,'m--')
scatter(55,1024*1000,100,'*','LineWidth',1)
text(150,1024*1000,"This work",'FontSize',12)

xlabel('Measurements Per Frame')
ylabel('Total Sensor Rate (Sensors/Sec)')
%% FOM -- this one
close all

str = string([22,23,65,66,67,68,69,70,71,72,73]);

for i = 1:11
    str(i) = "["+str(i)+"]";
end

x = SensorNum;
textscatter(x,ADCRate,str,"TextDensityPercentage",100)
hold on
[p,S] = polyfit(x,ADCRate,1);
indx = 1:2000;
[y_fit,delta] = polyval(p,indx,S);
plot(indx,y_fit,'r-','LineWidth',1)
plot(indx,y_fit+2*delta,'m--',indx,y_fit-2*delta,'m--')

scatter(55,1024*1000,100,'*','LineWidth',1)
text(100,1024*1000,"This work",'FontSize',12)

xlabel('Measurements Per Frame')
ylabel('Total Sensor Rate (Sensors/Sec)')



