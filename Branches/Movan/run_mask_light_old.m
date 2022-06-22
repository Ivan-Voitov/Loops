function run_mask_light_old(Stuff,varargin)
Window = round((600)./ 16.667);
Trial = Stuff{1}; Data = Stuff{2};
EnMouse = true;
for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end


% because i didn't save mask for that data
In = destruct(Trial,'MaskOn') == 0;
Data(In) = [];
Trial(In) = [];

%% extract triggered data
Condition = false(length(Trial),9);
for T = 1:length(Trial)
    Trigger(1) = Trial(T).Trigger.Delay.Line;
    Trigger(2) = Trial(T).Trigger.Stimulus.Line - round(600 / 16.667);
    Trigger(3) = Trial(T).Trigger.Stimulus.Line;
    
    for On = 1:3
        % all combinations of maskon and light on
        Condition(T,1 + (On-1)*3) = Trial(T).MaskOn ~= On && Trial(T).LightOn ~= On;
        Condition(T,2 + (On-1)*3) = Trial(T).MaskOn == On && Trial(T).LightOn ~= On;
        Condition(T,3 + (On-1)*3)  = Trial(T).LightOn == On;
        
%         Speed(T,On) = nanmean(Data{T}(Trigger(On):Trigger(On)+Window,4));
        Speed(T,On) = nanmean(Data{T}(Trigger(On):Trigger(On)+Window,7));
    end
    
    
    % averages
    %     Speed(T,1) = nanmean(Data{T}(:,4));
    %     Speed(T,1) = nanmean(Data{T}(:,4));
    
    % triggered
    
    
end

TaskMat = 3-destruct(Trial,'Task');

if EnMouse
    for I = 1:length(Trial); MouseNames{I} = Trial(I).MouseName; end
    MouseNames = unique(MouseNames);
    for I = 1:length(Trial); MouseMat(I) = find(strcmp(Trial(I).MouseName,MouseNames)); end
else
    for I = 1:length(Trial); MouseNames{I} = Trial(I).FileName; end
    MouseNames = unique(MouseNames);
    for I = 1:length(Trial); MouseMat(I) = find(strcmp(Trial(I).FileName,MouseNames)); end
end

for C = [1:3 7:9]
    ToPlot{C} = Speed(Condition(:,C),ceil(C/3));
    Task{C} = TaskMat(Condition(:,C));
    Mouse{C} = MouseMat(Condition(:,C))';
end

%% plot
figure; Colours; Colour = {Blue;Red}; hold on;
set(gcf, 'Position',  [400, 100, 400, 600])

for On = [1 3]
    for Ta = 1:2
        subplot(2,2,On-(On==3) + ((Ta-1)*2));
        hold on;
        for Mo = 1:length(unique(MouseMat))
            for Z = 1:3;PlotSelection{Z} = and((Mouse{Z+((On==3)*6)}==Mo),(Task{Z+((On==3)*6)}==Ta)); end
            PlotSelection{2} = and((Mouse{2+((On==3)*6)}==Mo),(Task{2+((On==3)*6)}==Ta));
            PlotSelection{3} = and((Mouse{3+((On==3)*6)}==Mo),(Task{3+((On==3)*6)}==Ta));
            if ~any(isnan([nanmean(ToPlot{1+((On==3)*6)}(PlotSelection{1})),nanmean(ToPlot{2+((On==3)*6)}(PlotSelection{2})),nanmean(ToPlot{3+((On==3)*6)}(PlotSelection{3}))]))
                plot([nanmean(ToPlot{1+((On==3)*6)}(PlotSelection{1})),nanmean(ToPlot{2+((On==3)*6)}(PlotSelection{2})),nanmean(ToPlot{3+((On==3)*6)}(PlotSelection{3}))],...
                    'Marker','o','MarkerFaceColor','w','MarkerEdgeColor',Colour{Ta},'LineWidth',1,'color',Grey);
            else
                plot([1 3],[nanmean(ToPlot{1+((On==3)*6)}(PlotSelection{1})),nanmean(ToPlot{3+((On==3)*6)}(PlotSelection{3}))],...
                    'Marker','o','MarkerFaceColor','w','MarkerEdgeColor',Colour{Ta},'LineWidth',1,'color',Grey);
            end
            ToStat(Mo,:) = [nanmean(ToPlot{1+((On==3)*6)}(PlotSelection{1})),nanmean(ToPlot{2+((On==3)*6)}(PlotSelection{2})),nanmean(ToPlot{3+((On==3)*6)}(PlotSelection{3}))];
        end
        for Z = 0:2;line([Z+0.75 Z+1.25],[nanmedian(ToStat(:,Z+1)) nanmedian(ToStat(:,Z+1))],'LineWidth',2,'color',Black);end
        P(On,Ta,1) = signrank(ToStat(:,1),ToStat(:,2));
        P(On,Ta,2) = signrank(ToStat(:,1),ToStat(:,3));
        text(1,80,strcat({'p = '},num2str(P(On,Ta,1))));
        text(2,80,strcat({'p = '},num2str(P(On,Ta,2))));
        
        axis([0.5 3.5 0 100]);
        Ax = gca; Ax.XTick = [1 2 3];
        Ax.XTickLabel = {'Off';'Masking';'On'};
        Ax.YTick = [0 20 40 60 80 100];
    end
end




% 
% figure; Colours;
% for On = [1 3]
%     for K = 1:3
%         C = K + (On-1)*3;
%         subplot(3,3,C);
%         B = boxplot(ToPlot{C},Task{C},'whisker',0.7193,'Symbol','','Colors',[Blue;Red]); % 95%
%         set(B,{'linew'},{1.5});
%         Ax = gca; Ax.XTick = [];
% %         if K == 1
%             Ax.YTick = [0 20 40 60 80 100];
%             %         ylabel('Average running speed (cm/s)');
% %         else
% %             Ax.YTick = [];
% %         end
%         axis([0.5 2.5 0 100]);
%         
%     end
% end


% %% or...
% figure; Colours;
% for On = 1:3
%     for K = 1:3
%         C = K + (On-1)*3;
%         subplot(3,3,C);
%         B = boxplot(ToPlot{C},Task{C},'whisker',0.7193,'Symbol','','Colors',[Blue;Red]); % 95%
%         set(B,{'linew'},{1.5});
%         Ax = gca; Ax.XTick = [];
% %         if K == 1
%             Ax.YTick = [0 20 40 60 80 100];
%             %         ylabel('Average running speed (cm/s)');
% %         else
% %             Ax.YTick = [];
% %         end
%         axis([0.5 2.5 0 100]);
%         
%     end
% end


