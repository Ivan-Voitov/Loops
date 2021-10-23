%% sweep package
%% cat
if ~isempty(PCsCat)
    clearvars TempActivities TempPCsRaw
    for C = 1:size(Activities,1)
        try
            TempActivities(C,:) = denan(reshape(squeeze(Activities(C,(end-Range(2))+1:end,:)),[((size(Activities,2)-abs(Range(1))-1)*size(Activities,3)) 1]));
            if isempty(TempActivities(C,:)) && C == 1
                TempActivities = nan(1,length(denan(reshape(squeeze(Activities(2,(end-Range(2))+1:end,:)),[((size(Activities,2)-abs(Range(1))-1)*size(Activities,3)) 1]))));
            end
        catch
            TempActivities(C,:) = nan;
        end
    end
    
    if Smooth
        for C = 1:size(TempActivities,1)
            %             NotNaN = ~isnan(DFFs{Session}(C,:));
            TempActivities(C,:)= gaussfilt(1:length(TempActivities(C,:)),TempActivities(C,:),1);
            %             DFFs{Session}(C,NotNaN)= gaussfilt(1:length(DFFs{Session}(C,NotNaN)),DFFs{Session}(C,NotNaN),1);
        end
    end
    
    TempRemove = all(isnan(TempActivities)');
    TempActivities(TempRemove,:) = [];
    if size(TempActivities,1) < length(PCsCat); TempPCsRaw = PCsCat(1:size(TempActivities,1)); else TempPCsRaw = PCsCat; end
    
    Opts = statset('MaxIter',100000);
    [TempData,~,~,~,Explanations{Session}] = pca(TempActivities','numcomponents',max(TempPCsRaw),'Options',Opts,'Centered',true);
    
    DFF = nan(max(TempPCsRaw),size(DFFs{Session},2));
    DFF(:,~isnan(DFFs{Session}(1,:))) = (DFFs{Session}(~TempRemove,~isnan(DFFs{Session}(1,:)))' * TempData)';
    Activities = wind_roi(DFF,{TrigOn;TrigOff},'Window',Range);
end

% cat exclude
    %         clearvars TempActivities
    %         for C = 1:size(Activities,1)
    %             try
    %                 TempActivities(C,:) = denan(reshape(squeeze(Activities(C,(end-Range(2))+1:end,:)),[((size(Activities,2)-abs(Range(1))-1)*size(Activities,3)) 1]));
    %             catch
    %                 TempActivities(C,:) = nan;
    %             end
    %         end
    %
    %         if Smooth
    %             for C = 1:size(TempActivities,1)
    %                 %             NotNaN = ~isnan(DFFs{Session}(C,:));
    %                 TempActivities(C,:)= gaussfilt(1:length(TempActivities(C,:)),TempActivities(C,:),1);
    %                 %             DFFs{Session}(C,NotNaN)= gaussfilt(1:length(DFFs{Session}(C,NotNaN)),DFFs{Session}(C,NotNaN),1);
    %             end
    %         end
    %
    %         TempRemove = all(isnan(TempActivities)');
    %         TempActivities(TempRemove,:) = [];
    %         % %     if size(TempActivities,1) < length(PCsCat); TempPCsRaw = PCsCat(1:size(TempActivities,1)); else TempPCsRaw = PCsCat; end
    %
    %         Opts = statset('MaxIter',100000);
    %         [TempData,~,~,~,Explanations{Session}] = pca(TempActivities','Options',Opts,'Centered',true);
    %         TempData(:,PCsExclude) = [];
    %
    %         DFF = nan(size(TempData,2),size(DFFs{Session},2));
    %         % DFF(:,~isnan(DFFs{Session}(1,:))) = (DFFs{Session}(~TempRemove,~isnan(DFFs{Session}(1,:)))' * TempData)';
    %         DFF = nan(size(TempActivities,1)-max(PCsExclude),size(DFFs{Session},2));
    %         DFF(:,~isnan(DFFs{Session}(1,:))) = (DFFs{Session}(~EnNaN,~isnan(DFFs{Session}(1,:)))' * TempData)';
    %         Activities = wind_roi(DFF,{TrigOn;TrigOff},'Window',Range);
 