%By: Shoa Russell 
%parser for 2 BNO configuration with TEENSY 3.6 
% This program parses log files and plots the sensor data.

tic;
clc;
clear;
close all;

% How many samples per sensor per block
k=1;%start of file
pointer=0;
numsamples_B = 600;
MAG_BLOCKSIZE = 6*numsamples_B; % changed from 3 to 6 because there are two sensors 
GYR_BLOCKSIZE = 6*numsamples_B;
ACC_BLOCKSIZE = 6*numsamples_B;
BLOCKSIZE = 4*MAG_BLOCKSIZE+4*GYR_BLOCKSIZE ...
    + 4*ACC_BLOCKSIZE;

%Open the log file
[Name, pathName] = uigetfile('*.bin', 'Select Log File');% selects the folder to pull data from 

%{ 
BaseName='BNO_test';
%EndFileName='_raw.bin'; % picks which file you will use 
EndFileName='.bin';
ShortEndName = EndFileName(1:end-4);
%mkdir(pathName,'figures')
fileName=[BaseName,num2str(k),EndFileName]
savelocation=[pathName,'figures',num2str(k)]
%}
%while(fileName)
fileID = fopen([pathName, Name]);
rawData = fread(fileID, 'uint8');
numBlocks = floor(length(rawData)/BLOCKSIZE); % Only process whole blocks

if(numBlocks)
% Pre-allocate buffers
MAGData = zeros(1, MAG_BLOCKSIZE*(numBlocks-2701));
GYRData = zeros(1, GYR_BLOCKSIZE*(numBlocks-2701));
ACCData = zeros(1, ACC_BLOCKSIZE*(numBlocks-2701));

% Parse the raw data
for n = 0:numBlocks-400
    % Parse MAG Data: 4 bytes -> float
    for i=1:MAG_BLOCKSIZE     
        Datatemp3=rawData(i*4-3+(BLOCKSIZE*n));
        Datatemp2=bitshift(rawData(i*4-2+(BLOCKSIZE*n)), 8, 'uint32');
        Datatemp1=bitshift(rawData(i*4-1+(BLOCKSIZE*n)), 16, 'uint32');
        Datatemp0=bitshift(rawData(i*4+(BLOCKSIZE*n)), 24, 'uint32');  
        MAGData(i+MAG_BLOCKSIZE*n) = ...
            typecast( ...
                uint32(bitor( ...
                    uint32(bitor( Datatemp3,Datatemp2,'uint32')), ...
                    uint32(bitor( Datatemp1,Datatemp0,'uint32')), ...
                'uint32' )),...
             'single');  
pointer = 4*MAG_BLOCKSIZE;
    end
    % Parse GYR Data: 2 bytes -> uint16
    for i=1:GYR_BLOCKSIZE
        Datatemp3=rawData(i*4-3+(BLOCKSIZE*n)+pointer);
        Datatemp2=bitshift(rawData(i*4-2+(BLOCKSIZE*n)+pointer), 8, 'uint32');
        Datatemp1=bitshift(rawData(i*4-1+(BLOCKSIZE*n)+pointer), 16, 'uint32');
        Datatemp0=bitshift(rawData(i*4+(BLOCKSIZE*n)+pointer), 24, 'uint32');
        
        GYRData(i+GYR_BLOCKSIZE*n) = ...
            typecast( ...
                uint32(bitor( ...
                    uint32(bitor( Datatemp3,Datatemp2,'uint32')), ...
                    uint32(bitor( Datatemp1,Datatemp0,'uint32')), ...
                'uint32' )),...
             'single');   
    end
    pointer=4*MAG_BLOCKSIZE+4*GYR_BLOCKSIZE;
    % Parse Accel Data: 6 bytes -> 3*int16 (x, y, z ft/s^2)
  for i=1:ACC_BLOCKSIZE
        Datatemp3=rawData(i*4-3+(BLOCKSIZE*n)+pointer);
        Datatemp2=bitshift(rawData(i*4-2+(BLOCKSIZE*n)+pointer), 8, 'uint32');
        Datatemp1=bitshift(rawData(i*4-1+(BLOCKSIZE*n)+pointer), 16, 'uint32');
        Datatemp0=bitshift(rawData(i*4+(BLOCKSIZE*n)+pointer), 24, 'uint32');
        
        ACCData(i+ACC_BLOCKSIZE*n) = ...
            typecast( ...
                uint32(bitor( ...
                    uint32(bitor( Datatemp3,Datatemp2,'uint32')), ...
                    uint32(bitor( Datatemp1,Datatemp0,'uint32')), ...
                'uint32' )),...
             'single');   
  end
    pointer=4*MAG_BLOCKSIZE+4*GYR_BLOCKSIZE+4*ACC_BLOCKSIZE;
end
%emgshort = emgData(1:15000);
MAGData = reshape(MAGData,6,[]);
GYRData = reshape(GYRData,6,[]);
ACCData = reshape(ACCData,6,[]);
mx=ACCData(1,:);
my=ACCData(2,:);
mz=ACCData(3,:);

fs = 250; %set sampling frequency 

t = 0:1/fs:(length(MAGData)-1)/fs;

t_ACCel = 0:1/fs:(length(ACCData)-1)/fs;

%mkdir(savelocation)% make the individual directory
% 
% =
% ===============xzfor each test batch
% Plot MAG Data
E=figure('Name', 'MAG Data');%,'visible','off')
plot(t, MAGData);
title('MAG Data')
xlabel('Time (s)')
ylabel('mag Y axis')
%saveas(E,[pathName,'\figures',num2str(k),'\','MAG',ShortEndName],'fig')

% Plot GYR Data
M=figure('Name', 'GYR Data');%,'visible','off')
plot(t, GYRData);
title('GYR Data')
xlabel('Time (s)')
ylabel('GYR y axis ')
%saveas(M,[pathName,'\figures',num2str(k),'\','GYR',ShortEndName],'fig')

%*********Plot MAGelerometer Data*******%

%scale ACCelerometer data 
maxAccel_scale=max([ACCData(2,:);ACCData(3,:);ACCData(1,:)]);
maxAccel_scale=max(maxAccel_scale(:,:,:));
minAccel_scale=min([ACCData(2,:);ACCData(3,:);ACCData(1,:)]);
minAccel_scale=min(minAccel_scale(:,:,:));

A=figure('Name', 'ACCel/MAG');%,'visible','off','Position', [100, 100, 1024, 1200]);
subplot(3,1,1)
plot(t_ACCel, ACCData(1,:))
%axis([0,max(t_ACCel),minAccel_scale,maxAccel_scale+1])
title('ACCelerometer x-axis')
xlabel('Time (s)')
ylabel('g')
subplot(3,1,2)
plot(t_ACCel, ACCData(2,:))
%axis([0,max(t_ACCel),minAccel_scale,maxAccel_scale+1])
title('ACCelerometer y-axis')
xlabel('Time (s)')
ylabel('g')
subplot(3,1,3)
plot(t_ACCel, ACCData(3,:))
%axis([0,max(t_ACCel),minAccel_scale,maxAccel_scale+1])
title('ACCelerometer z-axis')
xlabel('Time (s)')
ylabel('g')
%saveas(A,[pathName,'\figures',num2str(k),'\','ALL Axis Motion ',ShortEndName],'fig')

end % ends if for empty file and increments to the next 
%close all;
%clear flagData spo2Data emgData
%     k=k+1;
%   fileName=[BaseName,num2str(k),EndFileName]
%   savelocation=[pathName,'figures',num2str(k)]
  
 toc
 %5end


