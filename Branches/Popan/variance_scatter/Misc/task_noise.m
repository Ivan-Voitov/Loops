function [Noise] = task_noise(Activities,Labels,varargin)
%% parse args
AverageFR = [];
% the way (1..3)
Way = 3; % EMPIRICALLY DOENS'T MATTER

for I = 2:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end


%%
% define
if ~isempty(varargin{1})
    Noise = varargin{1};
else
    Noise.Normal = [];
    Noise.MeanFR = [];
    Noise.Shifted = [];
    Noise.ShiftedMeanFR = [];
    Noise.Shuffled = [];
    Noise.ShuffledMeanFR = [];    
    Noise.Control = [];
    Noise.ControlMeanFR = [];
end

%% do
if ~isempty(AverageFR)
else
    Temp = cat(3,nanmean(Activities(:,:,Labels==2),3), nanmean(Activities(:,:,Labels==1),3));
    AverageFR = [squeeze(nanmean(Temp(:,:,1),2)) squeeze(nanmean(Temp(:,:,2),2))];
end
% get noise values
if Way == 1 % one way... most naive
    AvgTrace = nanmean(Activities,3);
    for T = 1:size(Activities,3)
        Activities(:,:,T) = Activities(:,:,T) - AvgTrace;
    end
elseif Way == 2 % the second way... averaging independantly averaged tasks
    AvgTrace = nanmean(cat(3,nanmean(Activities(:,:,Labels==1),3), nanmean(Activities(:,:,Labels==2),3)),3);
    for T = 1:size(Activities,3)
        Activities(:,:,T) = Activities(:,:,T) - AvgTrace;
    end
elseif Way == 3 % the third way... subtracting averaged of the each respective task
    AvgTrace(:,:,2) = nanmean(Activities(:,:,Labels==2),3);
    AvgTrace(:,:,1) = nanmean(Activities(:,:,Labels==1),3);
    for T = 1:size(Activities,3)
        Activities(:,:,T) = Activities(:,:,T) - AvgTrace(:,:,Labels(T));
    end
end
% Values = squeeze(nanmean(Activities,2));
Values = reshape(nanmean(Activities,2),[size(Activities,1) size(Activities,3)]);
Labels(isnan(Values(1,:))) = [];
Values(:,isnan(Values(1,:))) = [];
for Row = 1:size(Values,1)
    for Column = 1 + Row : size(Values,1)
        % this is a pair
        Noise.MeanFR(end+1,:) = nanmean(cat(1,AverageFR(Row,:),AverageFR(Column,:)),1);

        TempCoeff1 = corrcoef(Values(Row,Labels==2)',Values(Column,Labels==2)');
        TempCoeff2 = corrcoef(Values(Row,Labels==1)',Values(Column,Labels==1)');
        Noise.Normal(end+1,:) = [TempCoeff1(1,2) TempCoeff2(1,2)];
        
        for Shuff = 1:5
            RandIndex = randperm(length(Labels));
            TempCoeff1 = corrcoef(Values(Row,Labels(RandIndex)==2)',Values(Column,Labels(RandIndex)==2)');
            TempCoeff2 = corrcoef(Values(Row,Labels(RandIndex)==1)',Values(Column,Labels(RandIndex)==1)');
            Noise.Shuffled(end+1,:) = [TempCoeff1(1,2) TempCoeff2(1,2)];
            Noise.ShuffledMeanFR(end+1,:) = Noise.MeanFR(end,:);
            RandIndex2 = randperm(length(Labels));
            TempCoeff1 = corrcoef(Values(Row,Labels(RandIndex)==2)',Values(Column,Labels(RandIndex2)==2)');
            TempCoeff2 = corrcoef(Values(Row,Labels(RandIndex)==1)',Values(Column,Labels(RandIndex2)==1)');
            Noise.Control(end+1,:) = [TempCoeff1(1,2) TempCoeff2(1,2)];
            Noise.ControlMeanFR(end+1,:) = Noise.MeanFR(end,:);
        end
        
        ShiftedLabels = shift_labels(Labels);
        TempCoeff1 = corrcoef(Values(Row,ShiftedLabels==1)',Values(Column,ShiftedLabels==1)');
        TempCoeff2 = corrcoef(Values(Row,ShiftedLabels==2)',Values(Column,ShiftedLabels==2)');
        Noise.Shifted(end+1,:) = [TempCoeff1(1,2) TempCoeff2(1,2)];
        Noise.ShiftedMeanFR(end+1,:) = Noise.MeanFR(end,:);
        ShiftedLabels = 3 - ShiftedLabels;
        TempCoeff1 = corrcoef(Values(Row,ShiftedLabels==1)',Values(Column,ShiftedLabels==1)');
        TempCoeff2 = corrcoef(Values(Row,ShiftedLabels==2)',Values(Column,ShiftedLabels==2)');
        Noise.Shifted(end+1,:) = [TempCoeff1(1,2) TempCoeff2(1,2)];
        Noise.ShiftedMeanFR(end+1,:) = Noise.MeanFR(end,:);
    end
end

