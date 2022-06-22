%% sweep package
PCASmooth = 1;

%% raw
if ~isempty(PCsRaw)
    TempDFF = DFFs{1}(~EnNaN,:); TempDFF = TempDFF(:,~isnan(TempDFF(1,:)));
    if size(TempDFF,1) < length(PCsRaw); TempPCsRaw = PCsRaw(1:size(TempDFF,1)); else TempPCsRaw = PCsRaw; end
    
    if PCASmooth
        for C = 1:size(TempDFF,1)
            %             NotNaN = ~isnan(DFFs{1}(C,:));
            TempDFF(C,:)= gaussfilt(1:length(TempDFF(C,:)),TempDFF(C,:),1);
            %             DFFs{1}(C,NotNaN)= gaussfilt(1:length(DFFs{1}(C,NotNaN)),DFFs{1}(C,NotNaN),1);
        end
    end
    
    [TempData,~,~,~,Explanations{1}] = pca(TempDFF','numcomponents',max(TempPCsRaw),'Centered',true);
    %         DFF = nan(size(TempData,2)-TempPCsRaw,size(DFFs{1},2));
    DFF = nan(max(TempPCsRaw),size(DFFs{1},2));
    DFF(:,~isnan(DFFs{1}(1,:))) = (DFFs{1}(~EnNaN,~isnan(DFFs{1}(1,:)))' * TempData)';
    Activities = wind_roi(DFF,{TrigOn;TrigOff},'Window',Range);
end

%% exlude
if ~isempty(PCsExclude)
    TempDFF = DFFs{1}(~EnNaN,:); TempDFF = TempDFF(:,~isnan(TempDFF(1,:)));
    if size(TempDFF,1) < length(PCsExclude); TempPCsExclude = PCsExclude(1:size(TempDFF,1)); else TempPCsExclude = PCsExclude; end
    
    if PCASmooth
        for C = 1:size(TempDFF,1)
            %             NotNaN = ~isnan(DFFs{1}(C,:));
            TempDFF(C,:)= gaussfilt(1:length(TempDFF(C,:)),TempDFF(C,:),1);
            %             DFFs{1}(C,NotNaN)= gaussfilt(1:length(DFFs{1}(C,NotNaN)),DFFs{1}(C,NotNaN),1);
        end
    end
    
    [TempData,~,~,~,Explanations{1}] = pca(TempDFF','Centered',true);
    
    TempData(:,TempPCsExclude) = [];
    DFF = nan(size(TempDFF,1)-max(TempPCsExclude),size(DFFs{1},2));
    DFF(:,~isnan(DFFs{1}(1,:))) = (DFFs{1}(~EnNaN,~isnan(DFFs{1}(1,:)))' * TempData)';
    Activities = wind_roi(DFF,{TrigOn;TrigOff},'Window',Range);
end
