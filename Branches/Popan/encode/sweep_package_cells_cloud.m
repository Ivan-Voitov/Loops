if ~isempty(PCsCloud)
    TempRemove = all(isnan(Values)');
    if size(Values(~TempRemove,:),1) < length(PCsCloud); TempPCsCloud = PCsCloud(1:size(Values(~TempRemove,:),1)); else TempPCsCloud = PCsCloud; end
    [TempData,~,~,~,Explanations] = pca(Values(~TempRemove,:)','numcomponents',max(TempPCsCloud));
    Values = (Values(~TempRemove,:)' * TempData)';
end

% CELL SWEEP
if ~isempty(Cells)
    Values(all(isnan(Values)'),:) = [];
    TempOrder = randperm(size(Values,1));
    Values = Values(TempOrder,:);
    Activities = Activities(TempOrder,:,:);
    try
        TotalVar = nansum(nansum((Values - nanmean(Values,2)).^2));
        CellVar = nansum(nansum((Values(Cells,:) - nanmean(Values(Cells,:),2)).^2));
        Explanations = CellVar / TotalVar;
        Values = Values(Cells,:);
        Activities = Activities(Cells,:,:);
    catch
        Bases{Session} = nan;
        Scores{Session} = nan;
        Classes(Session) = nan;
        Traces{Session} = nan;
        Explanations = nan;
        Skip = true;
    end
end
