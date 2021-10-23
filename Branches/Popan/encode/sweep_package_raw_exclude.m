%% sweep package
PCASmooth = 1;

%% raw
if ~isempty(PCsRaw)
    TempDFF = DFFs{Session}(~EnNaN,:); TempDFF = TempDFF(:,~isnan(TempDFF(1,:)));
    if size(TempDFF,1) < length(PCsRaw); TempPCsRaw = PCsRaw(1:size(TempDFF,1)); else TempPCsRaw = PCsRaw; end
    
    if PCASmooth
        for C = 1:size(TempDFF,1)
            %             NotNaN = ~isnan(DFFs{Session}(C,:));
            TempDFF(C,:)= gaussfilt(1:length(TempDFF(C,:)),TempDFF(C,:),1);
            %             DFFs{Session}(C,NotNaN)= gaussfilt(1:length(DFFs{Session}(C,NotNaN)),DFFs{Session}(C,NotNaN),1);
        end
    end
    
    [TempData,~,~,~,Explanations{Session}] = pca(TempDFF','numcomponents',max(TempPCsRaw),'Centered',true);
    %         DFF = nan(size(TempData,2)-TempPCsRaw,size(DFFs{Session},2));
    DFF = nan(max(TempPCsRaw),size(DFFs{Session},2));
    DFF(:,~isnan(DFFs{Session}(1,:))) = (DFFs{Session}(~EnNaN,~isnan(DFFs{Session}(1,:)))' * TempData)';
    Activities = wind_roi(DFF,{TrigOn;TrigOff},'Window',Range);
end

%% exlude
if ~isempty(PCsExclude)
    TempDFF = DFFs{Session}(~EnNaN,:); TempDFF = TempDFF(:,~isnan(TempDFF(1,:)));
    if size(TempDFF,1) < length(PCsExclude); TempPCsExclude = PCsExclude(1:size(TempDFF,1)); else TempPCsExclude = PCsExclude; end
    
    if PCASmooth
        for C = 1:size(TempDFF,1)
            %             NotNaN = ~isnan(DFFs{Session}(C,:));
            TempDFF(C,:)= gaussfilt(1:length(TempDFF(C,:)),TempDFF(C,:),1);
            %             DFFs{Session}(C,NotNaN)= gaussfilt(1:length(DFFs{Session}(C,NotNaN)),DFFs{Session}(C,NotNaN),1);
        end
    end
    
    [TempData,~,~,~,Explanations{Session}] = pca(TempDFF','Centered',true);
    
    TempData(:,TempPCsExclude) = [];
    DFF = nan(size(TempDFF,1)-max(TempPCsExclude),size(DFFs{Session},2));
    DFF(:,~isnan(DFFs{Session}(1,:))) = (DFFs{Session}(~EnNaN,~isnan(DFFs{Session}(1,:)))' * TempData)';
    Activities = wind_roi(DFF,{TrigOn;TrigOff},'Window',Range);
end
