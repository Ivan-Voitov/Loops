function [EnNaN] = threshold_values(Activities,Range,Iterate,Threshold,Five,DePre)

% get values for threshold
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

% depre... (first one)
if DePre
    Values = Values - (squeeze(nanmean(Activities(:,1:(abs(Range(1))),:),2)));
end

% threshold (the whole point of this block)
%         sum(nanmean(Values,2)<Threshold) /  size(Values,1)
%         Values(nanmean(Values,2)<Threshold,:) = nan;
EnNaN = nanmean(Values,2)<Threshold;
end

