function [Activity] = context_activity(Activities,Labels,varargin)
Option = 1;

% define if doesn't exist (first session)
if min(Labels(:)) == 0; Labels = Labels+1;end
if ~isempty(varargin{1})
    Activity = varargin{1};
else
    Activity.Normal = [];
    Activity.Shuffled = [];
    Activity.Shifted = [];
    Activity.Odd = [];
    Activity.CrossedMemory = [];
    Activity.CrossedDiscrimination = [];
end


% % collapse time
if Option == 1
    Activities = squeeze(nanmean(Activities,2));
    
    % threshold
    if any(strcmp(varargin,'Threshold'))
        EnNaN = nanmean(Activities,2)<varargin{find(strcmp(varargin,'Threshold'))+1};
        Activities(EnNaN,:,:) = [];
    end
elseif Option == 2
    % threshold
    if any(strcmp(varargin,'Threshold'))
        EnNaN = nanmean(nanmean(Activities,3),2)<varargin{find(strcmp(varargin,'Threshold'))+1};
        Activities(EnNaN,:,:) = [];
    end
end


%% do
% normal activity (dis, mem)]
if Option == 1
    Temp = [nanmean(Activities(:,Labels==2),2) nanmean(Activities(:,Labels==1),2)];
elseif Option == 2
    Temp = cat(3,nanmean(Activities(:,:,Labels==2),3), nanmean(Activities(:,:,Labels==1),3));
    Temp = [squeeze(nanmean(Temp(:,:,1),2)) squeeze(nanmean(Temp(:,:,2),2))];
end
Activity.Normal = cat(1,Activity.Normal,Temp);

% shuffled label activity (*100)
for Shuff = 1:100
    RandIndex = randperm(length(Labels));
    if Option == 1
        Temp = cat(2,nanmean(Activities(:,Labels(RandIndex)==2),2), nanmean(Activities(:,Labels(RandIndex)==1),2));
    elseif Option == 2
        Temp = cat(2,nanmean(nanmean(Activities(:,:,Labels(RandIndex)==2),3),2), nanmean(nanmean(Activities(:,:,Labels(RandIndex)==1),3),2));
    end
    Activity.Shuffled = cat(1,Activity.Shuffled,Temp);
end

% shifted label activity (*2)
ShiftedLabels = shift_labels(Labels);
if Option == 1
    Temp = cat(2,nanmean(Activities(:,ShiftedLabels==2),2), nanmean(Activities(:,ShiftedLabels==1),2));
elseif Option == 2
    Temp = cat(2,nanmean(nanmean(Activities(:,:,ShiftedLabels==2),3),2), nanmean(nanmean(Activities(:,:,ShiftedLabels==1),3),2));
end
Activity.Shifted = cat(1,Activity.Shifted,Temp);
ShiftedLabels = 3 - ShiftedLabels;
if Option == 1
    Temp = cat(2,nanmean(Activities(:,ShiftedLabels==2),2), nanmean(Activities(:,ShiftedLabels==1),2));
elseif Option == 2
    Temp = cat(2,nanmean(nanmean(Activities(:,:,ShiftedLabels==2),3),2), nanmean(nanmean(Activities(:,:,ShiftedLabels==1),3),2));
end
Activity.Shifted = cat(1,Activity.Shifted,Temp);

if Option == 2
    Activities = squeeze(nanmean(Activities,2));
end
% odds and evens
Odd = rem(1:size(Activities,2),2)';
TempOdd = cat(2,nanmean(Activities(:,and(Labels==2,Odd)),2), nanmean(Activities(:,and(Labels==1,Odd)),2));
TempEven = cat(2,nanmean(Activities(:,and(Labels==2,~Odd)),2), nanmean(Activities(:,and(Labels==1,~Odd)),2));
% Temp = [squeeze(nanmean(TempOdd(:,:,1),2)) squeeze(nanmean(TempOdd(:,:,2),2))];
Activity.Odd = cat(1,Activity.Odd,[TempOdd]);
% Temp = [squeeze(nanmean(TempOdd(:,:,2),2)) squeeze(nanmean(TempEven(:,:,2),2))];
Activity.CrossedMemory = cat(1,Activity.CrossedMemory,[TempOdd(:,2) TempEven(:,2)]);
% Temp = [squeeze(nanmean(TempOdd(:,:,1),2)) squeeze(nanmean(TempEven(:,:,1),2))];
Activity.CrossedDiscrimination = cat(1,Activity.CrossedDiscrimination,[TempOdd(:,1) TempEven(:,1)]);