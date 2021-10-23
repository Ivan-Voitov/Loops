function cross_db(Index)
% controls for WMCD being a decision boundary dimension,
% and controls for CCD being a previous stimulus dimension

%% get data
WMCD = cat(1,Index.Class);
CCD = cat(1,Index.CueClass);

DBCD = nan(length(WMCD),1);
DCD = nan(length(WMCD),1);

%% calculate cue trace for all time points
[DFFs,~,~] = rip(Index,'S','DeNaN','NoStimulusResponsive','Active');

Bases = {'Basis';'CueBasis'}; Traceses = {'Trace';'CueTrace'};

for CodingDimension = 1:2
    for Z = 1:length(DFFs)
        NotNaN = ~isnan(Index(Z).(Bases{CodingDimension})(2:end));
        Traces{Z} = (([ones(size(DFFs{Z}(NotNaN,:),2),1) DFFs{Z}(NotNaN,:)'] ...
            * Index(Z).(Bases{CodingDimension})([true; NotNaN]))');
        Index(Z).(Traceses{CodingDimension}) = Traces{Z};
    end
end

%% find optimal db using the new coding dimensions
% [Index2] = encode(Index,'CDB',true,'BasisIn',cellcat(Index.Basis),'Iterate',10,'Folds',1,'Threshold',[]);
[Index2] = encode(Index,'CDB',true,'CueTraceValue',true,'Iterate',10,'Folds',10,'Threshold',[]);
DCD = cat(1,Index2.Class);
[Index3] = encode(Index,'CDB',true,'TraceValue',true,'Iterate',10,'Folds',10,'Threshold',[]);
DBCD = cat(1,Index3.Class);

%% plot
Style = 1;
Colours;
figure;
% plot([zeros(length(WMCD),1) ones(length(WMCD),1)]', [WMCD'; DBCD'],'color',Black,'Marker','o','MarkerSize',5,'MarkerFaceColor',White,'MarkerEdgeColor',Black,'LineWidth',2);
hold on;
if Style == 1
    plot([zeros(length(WMCD),1)+2 ones(length(WMCD),1)+2]', [CCD'; DCD'],'color',Black,'Marker','o','MarkerSize',5,'MarkerFaceColor',White,'MarkerEdgeColor',Black,'LineWidth',1);
    Medians = [nanmedian(WMCD) nanmedian(DBCD) nanmedian(CCD) nanmedian(DCD)];
    for I = 1:length(Medians)
        line([-1.15+I -0.85+I],[Medians(I) Medians(I)],'color',Black,'LineWidth',3)
    end
else
    Datas = {WMCD; DBCD; CCD; DCD};
    for Column = 1:4
        [Mean{Column},~,CI{Column}] = normfit(Datas{Column}(~isnan(Datas{Column})));
        errorbar(-1+Column,Mean{Column},Mean{Column}-CI{Column}(1),Mean{Column}-CI{Column}(2),'LineWidth',2,'color',Black,'Marker','o','MarkerFaceColor',Black,'MarkerSize',5);
    end
end

axis([1.75 3.25 (0+(Style-1).*0.5) 1])
Ax = gca;
Ax.XTick = [0 1 2 3];
Ax.XTickLabel = {'WMCD';'DBCD';'CCD';'DCD'};
Ax.YTick = [0 0.5 1];
Ax.YTickLabel = {'0%';'50%';'100%'};
ylabel('Classification accuracy');

% %% dynamics plot
% nanmean()


