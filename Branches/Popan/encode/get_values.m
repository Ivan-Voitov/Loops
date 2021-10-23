function [Values] = get_values(Activities,Clever,Five,DePre,Range,ValuesIn,PCsCloud,Cells)


%% get values after threshold
if Clever
    MeanActivities = nanmean(cat(3,nanmean(Activities(:,:,Labels==1),3), nanmean(Activities(:,:,Labels==0),3)),3);
    for T = 1:size(Activities,3)
        Activities(:,:,T) = Activities(:,:,T) - MeanActivities;
    end
end

if Five
    for Iter = 1:Iterate
        TempActivities = Activities;
        for Ce = 1:size(TempActivities,1)
            for Tr = 1:size(TempActivities,3)
                Temp = abs(Range(1)) + randperm(sum(~isnan(TempActivities(Ce,:,Tr))) - abs(Range(1)));
                TempActivities(Ce,Temp(6:end),Tr) = nan;
                %             Activities(:,abs(Range(1))+1:sum(~isnan(Activities(1,:,Tr))),Tr) = ...
                %                 Activities(:,Temp(1:5),Tr);
            end
        end
        TempValues(:,:,Iter) = reshape((nanmean(TempActivities(:,(end-Range(2))+1:end,:),2)),[size(TempActivities,1) size(TempActivities,3)]);
    end
    Values = nanmean(TempValues,3);
else
    % get values without clever for threshold
    Values = reshape((nanmean(Activities(:,(end-Range(2))+1:end,:),2)),[size(Activities,1) size(Activities,3)]);
end

% depre...
if DePre
    Values = Values - (squeeze(nanmean(Activities(:,1:(abs(Range(1))),:),2)));
end

% select cells / make cloud pca
sweep_package_cells_cloud;

if ~isempty(ValuesIn)
    Values = ValuesIn;
end

%% test difference in values
%     NewValues = Values;
%     NewLabels = Labels;
%     NewValues(isnan(NewValues(:,1)),:) = [];
%     NewValues(:,isnan(NewLabels)) = [];
%     NewLabels(isnan(NewLabels)) = [];
%     for Cell = 1:size(NewValues,1)
%         [~,P(Cell)] = ttest2(NewValues(Cell,NewLabels==1),NewValues(Cell,NewLabels==2));
%     end
%     sum(P<0.05) ./ size(NewValues,1)
