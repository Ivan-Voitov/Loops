function db_performance(Index)
TempIndex = [];
if iscell(Index)
    for K = 1:length(Index)
        for Z = 1:length(Index{K})
            TempIndex(end+1).Name = Index{K}(Z).Name;
        end
    end
end
Index = TempIndex;
Remove = false(length(Index),1); clearvars TempNames
for Session = 1:length(Index)
    TempName = strsplit(Index(Session).Name,'_');
    TempNames{Session} = cat(2,TempName{1},'_',TempName{2});
    if any(strcmp(TempNames{Session},TempNames(1:end-1)))
        Remove(Session) = true;
    end
end
Index(Remove) = [];

for Session = 1:length(Index)
    Temp = load(Index(Session).Name,'Trial');
    Trials{Session} = selector(Temp.Trial(~destruct(Temp.Trial,'Ignore')),'NoReset','Post','NoLight');
    if size(Trials{Session},1) == 1
       Trials{Session} = Trials{Session}'; 
    end
end

%% get numbers
for DB = [-15 15]
    for Task = 1:2
        for Session = 1:length(Trials)
            TempTrial = Trials{Session}(and(destruct(Trials{Session},'Task')==3-Task,destruct(Trials{Session},'DB')==DB));
            if ~isempty(TempTrial)
                Numbers(Session,Task,(DB==15)+1) = 1 - (sum(destruct(TempTrial,'ResponseType')==2)/length(TempTrial)) - (sum(destruct(TempTrial,'ResponseType')==3)/length(TempTrial));
            else
                Numbers(Session,Task,(DB==15)+1) = nan;
            end
        end
        TempTrial = cat(1,Trials{:});
        TempTrial = TempTrial(and(destruct(TempTrial,'Task')==3-Task,destruct(TempTrial,'DB')==DB));
        AllNumbers(Task,(DB==15)+1) = 1 - (sum(destruct(TempTrial,'ResponseType')==2)/length(TempTrial)) - (sum(destruct(TempTrial,'ResponseType')==3)/length(TempTrial));
    end
end

%% plot/anova
Colours;
figure;
hold on
plot([1.*ones(length(Numbers),1) 2.*ones(length(Numbers),1)]',[Numbers(:,1,1)';Numbers(:,2,1)'],'color',Grey,'LineWidth',1);%,'Marker','o','MarkerSize',12,'MarkerFaceColor',White);
plot([3.*ones(length(Numbers),1) 4.*ones(length(Numbers),1)]',[Numbers(:,2,1)';Numbers(:,2,2)'],'color',Grey,'LineWidth',1);%,'Marker','o','MarkerSize',12,'MarkerFaceColor',White);

plot([1.*ones(length(Numbers),1)]',[Numbers(:,1,1)'],'LineWidth',2,'LineStyle','none','Marker','o','MarkerSize',10,'MarkerFaceColor',White,'MarkerEdgeColor',Blue);
plot([2.*ones(length(Numbers),1)]',[Numbers(:,2,1)'],'LineWidth',2,'LineStyle','none','Marker','o','MarkerSize',10,'MarkerFaceColor',White,'MarkerEdgeColor',Red);
plot([3.*ones(length(Numbers),1)]',[Numbers(:,2,1)'],'LineWidth',2,'LineStyle','none','Marker','o','MarkerSize',10,'MarkerFaceColor',White,'MarkerEdgeColor',Blue);
plot([4.*ones(length(Numbers),1)]',[Numbers(:,2,2)'],'LineWidth',2,'LineStyle','none','Marker','o','MarkerSize',10,'MarkerFaceColor',White,'MarkerEdgeColor',Red);


plot([0.75.*ones(length(Numbers),1) 1.25.*ones(length(Numbers),1)]',[nanmedian(Numbers(:,1,1)');nanmedian(Numbers(:,1,1)')],'color',Black,'LineWidth',2);
plot([1.75.*ones(length(Numbers),1) 2.25.*ones(length(Numbers),1)]',[nanmedian(Numbers(:,2,1)');nanmedian(Numbers(:,2,1)')],'color',Black,'LineWidth',2);
plot([2.75.*ones(length(Numbers),1) 3.25.*ones(length(Numbers),1)]',[nanmedian(Numbers(:,1,2)');nanmedian(Numbers(:,1,2)')],'color',Black,'LineWidth',2);
plot([3.75.*ones(length(Numbers),1) 4.25.*ones(length(Numbers),1)]',[nanmedian(Numbers(:,2,1)');nanmedian(Numbers(:,2,2)')],'color',Black,'LineWidth',2);
% 
% for K = 0:3
%     plot(K + [0.75 1.25],[AllNumbers(K+1)';AllNumbers(K+1)'],'color',Black,'LineWidth',2);
% end

Sig(1) = ranksum(cat(1,Numbers(:,1,1),Numbers(:,2,1)),cat(1,Numbers(:,1,2),Numbers(:,2,2)));
% Sig(4) = ranksum(Numbers(:,1,1),Numbers(:,1,2));
% Sig(5) = ranksum(Numbers(:,2,1),Numbers(:,2,2));

Sig(2) = signrank(Numbers(:,1,1),Numbers(:,2,1));
Sig(3) = signrank(Numbers(:,1,2),Numbers(:,2,2));

text(1,0.6,num2str(Sig(2)));
text(2,0.7,num2str(Sig(1)));
text(3,0.6,num2str(Sig(3)));

Ax = gca;
Ax.XLim = [0.5 4.5];
Ax.XTick = [1 2 3 4];
Ax.XTickLabel = {'D';'WM';'D';'WM'};
Ax.YLim = [0.5 1];
Ax.YTick = [0.5 0.75 1];
Ax.YTickLabel = {'50%';'75%';'100%'}; 
ylabel('Percent correct')

%% plot simpler version
SimpleNumbers = squeeze(nanmean(Numbers,2));
figure;

[Mean(1),~,Temp] = normfit(SimpleNumbers(:,1));
CI(1) = Mean(1) - Temp(1);
[Mean(2),~,Temp] = normfit(SimpleNumbers(:,2));
CI(2) = Mean(2) - Temp(1);
b = bar([Mean(1) Mean(2)]);
b(1).FaceColor = 'flat';
b(1).CData(1,:) = [0.5 0.5 0.5];
b(1).CData(2,:) = [0.5 0.5 0.5];
hold on
errorbar([1 2],[Mean(1); Mean(2)]',[CI(2) ; CI(1)]','.k');

for Column = 1:2
    for S = 1:size(SimpleNumbers,1)
        plot(Column+((rand-0.5).*0.3), SimpleNumbers(S,Column),'Marker','o','color',Black);
    end
end

Ax = gca;
Ax.YTick = [0 0.5 1];
Ax.YLim = [0 1];
Ax.XTick = [1 2];
Ax.XTickLabel = {'-15';'+15'};
Ax.YTickLabel = {'0%';'50%';'100%'};

%% anova...
TaskGroup = repmat(cat(1,zeros(size(Numbers,1),1),ones(size(Numbers,1),1)),[2 1]);
DBGroup = cat(1,zeros(size(Numbers,1)*2,1),ones(size(Numbers,1)*2,1));
Numbers = reshape(Numbers,[(size(Numbers,1).*4) 1]);
anovan(Numbers,{TaskGroup,DBGroup},'model','full','varnames',{'Task';'DB'});



%% misc

% delay_length(cat(1,Trials{:}),[],'Fit',1,'Split',false,'ToPlot',[1 3 4 6],'Truncate',800);





