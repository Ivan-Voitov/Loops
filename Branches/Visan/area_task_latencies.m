function area_task_latencies(Index,varargin)
FPS = 4.68;
ThresholdLatency = false;
Pretty = true;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% ORGANIZE
Types = {'DelayResponsive';'StimulusResponsive'};
Area = destruct(Index,'Area');
AreaIndex = {[];[]};
TaskIndex = {[];[]};
Numbers = {[];[]};
for Session = 1:length(Index)
    for CellType = 1:2
        Numbers{CellType} = cat(2,Numbers{CellType},[Index(Session).DiscriminationLatency(Index(Session).(Types{CellType})) ...
            Index(Session).MemoryLatency(Index(Session).(Types{CellType}))]);
        AreaIndex{CellType} = cat(1,AreaIndex{CellType},repmat(Area(Session),[length([Index(Session).DiscriminationLatency(Index(Session).(Types{CellType})) ...
            Index(Session).MemoryLatency(Index(Session).(Types{CellType}))]) 1]));
        TaskIndex{CellType} = cat(1,TaskIndex{CellType},[ones(length([Index(Session).DiscriminationLatency(Index(Session).(Types{CellType}))]),1);...
            ones(length([Index(Session).MemoryLatency(Index(Session).(Types{CellType}))]),1)+1]);
    end
end

for CellType = 1:2
    if ThresholdLatency
        AreaIndex{CellType}(Numbers{CellType}>=ThresholdLatency) = [];
        TaskIndex{CellType}(Numbers{CellType}>=ThresholdLatency) = [];
        Numbers{CellType}(Numbers{CellType}>=ThresholdLatency) = [];
    end
end



%% tom plot for just tasks
figure;Colours ;
set(gcf, 'Position',  [500, 300, 800, 350]);
for CellType = 1:2
    subplot(1,2,CellType);
    scatter(Numbers{CellType}(TaskIndex{CellType} == 1),Numbers{CellType}(TaskIndex{CellType} == 2),10,'MarkerEdgeColor',Black);
    axis square
    [Temp] = corrcoef(Numbers{CellType}(TaskIndex{CellType} == 1),Numbers{CellType}(TaskIndex{CellType} == 2));
    text(0,0,strcat('r = ',num2str(Temp(2))))
    Ax = gca;
    Ax.XTick = [-5 max(Numbers{CellType})];
    Ax.XLim = [-5 max(Numbers{CellType})];
    Ax.XTickLabel = round(Ax.XTick .* 1000/FPS);
    Ax.YTick = [-5 max(Numbers{CellType})];
    Ax.YLim = [-5 max(Numbers{CellType})];
    Ax.YTickLabel = round(Ax.YTick .* 1000/FPS);
end



%% plot
Colours;
Titles = {'Delay Responsive';'Stimulus Responsive'};
Suptitles = {'Difference between task blocks';'Difference between areas'};
Indicies = [TaskIndex AreaIndex];
for CellType = 1:2
    [Ps(:,CellType)] = anovan(Numbers{CellType},{Indicies{CellType,1};Indicies{CellType,2}},'model','full','varnames',{'Task';'Area'});
end

for CellType = 1:2
    if Pretty
        Numbers{CellType}(Numbers{CellType} < 0) = -1;
        if CellType == 1
            Numbers{CellType}(Numbers{CellType} > frame(3200,FPS)) =frame(3200,FPS)+2;
        else
            Numbers{CellType}(Numbers{CellType} > frame(2000,FPS)) = frame(2000,FPS)+2;
        end
    end
end


for IndexType = 1:2
    figure;
    for CellType = 1:2
        %                 swap({-1:1:frame(3200,FPS)+1;-1:1:frame(2000,FPS)+1},CellType)
        
        subplot(1,2,CellType);
        TempIndex = Indicies{CellType,IndexType};
        histogram(Numbers{CellType}(TempIndex == 1),swap({-1.5:2:frame(3200,FPS)+3.5;-1:2:frame(2000,FPS)+3.5},CellType),'Normalization','probability','FaceColor',Blue,'EdgeColor','none')
        hold on;
        histogram(Numbers{CellType}(TempIndex == 2),swap({-1.5:2:frame(3200,FPS)+3.5;-1:2:frame(2000,FPS)+3.5},CellType),'Normalization','probability','FaceColor',Red,'EdgeColor','none')
        title(Titles{CellType});
        Ax = gca;
        %         Ax.XTick = [-5 max(Numbers{CellType})];
        %          Ax.XLim = [-5 max(Numbers{CellType})];
        %         Ax.XTick = [min(swap({-1.5:2:frame(3200,FPS)+3.5;-1:2:frame(2000,FPS)+3.5},CellType)):2:max(swap({-1.5:2:frame(3200,FPS)+3.5;-1:2:frame(2000,FPS)+3.5},CellType))];
        Ax.XTick = [];
        Ax.XLim = [min(swap({-1.5:2:frame(3200,FPS)+3.5;-1:2:frame(2000,FPS)+3.5},CellType)) max(swap({-1.5:2:frame(3200,FPS)+3.5;-1:2:frame(2000,FPS)+3.5},CellType))];
        %         Ax.XTickLabel = round(Ax.XTick .* 1000/FPS);
        
        %         if IndexType == 1
        %             [~,P]= ttest(Numbers{CellType}(TempIndex==1),Numbers{CellType}(TempIndex==2));
        %         else
        %             [~,P] = ttest2(Numbers{CellType}(TempIndex==1),Numbers{CellType}(TempIndex==2));
        %         end
        Ax.YTick = [0:0.1:1];
        Ax.YLim = [0 1];
        text(6,0.2,strcat('p = ',num2str(Ps(IndexType,CellType))));
    end
    suptitle(Suptitles{IndexType});
end

end
