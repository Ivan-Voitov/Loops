function [ToPlot,Selection] = early_vs_late_light2(Index,varargin)
FPS = 22.39;
HalfWindow = 1600;
Light = true;
LimitBound = 1600;
PlotOut = true;
Sub = false;
Option = 1;
OfAvg = false;

for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if ~isstruct(Index)
    Traces = Index{1}; Trials = Index{2};
    if ~Light
        Traces = {Traces};
        Trials = {Trials};
    else
        Traces = {Traces;Traces};
        Trials = {selector(Trials,'NoLight');selector(Trials,'Light')};
    end
else
    [TempTraces,TempTrials] = rip(Index,'Super','DeNaN','Active','Trace');
    if ~Light
        Traces = {TempTraces};
        Trials = {TempTrials};
    end
end

% if ~OfAvg
% %     for Cond = 1:2
% %         for Z = 1:length(Traces{Cond})
% %             if Trials{Cond}{Z}(1).DB == 15
% %                 Traces{Cond}{Z} =  -Traces{Cond}{Z};
% %             end
% %         end
% % Z    end
% end

%% extract
for Condition = 1:length(Traces)
    for S = 1:length(Traces{1})
        Trial = Trials{Condition}{S}(destruct(Trials{Condition}{S},'Trigger.Stimulus.Time')>=LimitBound);
        
        if ~isempty(Trial)
            if length(Trial)>1
                TrigOn = destruct(Trial(destruct(Trial,'Block')==0),'Trigger.Delay.Frame');
                TrigOff = destruct(Trial(destruct(Trial,'Block')==0),'Trigger.Stimulus.Frame');
                Trace = -(Traces{Condition}{S} - nanmean(Traces{Condition}{S})) ./ std(Traces{Condition}{S},'omitnan');
                
                if OfAvg
                    Trace = -Trace;
                end
                [TempActivities1] = wind_roi(Trace,{TrigOn;TrigOff},'Window',frame([0 3200],FPS));
                
                TrigOn = destruct(Trial(destruct(Trial,'Block')==1),'Trigger.Delay.Frame');
                TrigOff = destruct(Trial(destruct(Trial,'Block')==1),'Trigger.Stimulus.Frame');
                
                Trace = (Traces{Condition}{S} - nanmean(Traces{Condition}{S})) ./ std(Traces{Condition}{S},'omitnan');
                [TempActivities2] = wind_roi(Trace,{TrigOn;TrigOff},'Window',frame([0 3200],FPS));
                Activities = cat(3,TempActivities1,TempActivities2);
            end
        end
        
        % option 1
        if Option == 1
            [ToPlot(1,Condition,S),~,ToPlotCI(1,Condition,S,:),~] = normfit(denan(squeeze(nanmean(Activities(1,1:frame(HalfWindow,FPS),:),2))));
            [ToPlot(2,Condition,S),~,ToPlotCI(2,Condition,S,:),~] = normfit(denan(squeeze(nanmean(Activities(1,frame(HalfWindow,FPS):frame(3250,FPS),:),2))));
        else
            % option 2 (avg after trial averaging averaging), a la plot
            [ToPlot(1,Condition,S),~,ToPlotCI(1,Condition,S,:),~] = normfit(denan(nanmean(squeeze(Activities(1,1:frame(HalfWindow,FPS),:)),2)));
            [ToPlot(2,Condition,S),~,ToPlotCI(2,Condition,S,:),~] = normfit(denan(nanmean(squeeze(Activities(1,frame(HalfWindow,FPS):frame(3250,FPS),:)),2)));
            Selection(1,1,Condition,S) = nanmean(denan(nanmean(squeeze(TempActivities1(1,1:frame(HalfWindow,FPS),:)),2)));
            Selection(2,1,Condition,S) = nanmean(denan(nanmean(squeeze(TempActivities1(1,frame(HalfWindow,FPS):frame(3250,FPS),:)),2)));
            Selection(1,2,Condition,S) = nanmean(denan(nanmean(squeeze(TempActivities2(1,1:frame(HalfWindow,FPS),:)),2)));
            Selection(2,2,Condition,S) = nanmean(denan(nanmean(squeeze(TempActivities2(1,frame(HalfWindow,FPS):frame(3250,FPS),:)),2)));
        end
    end
end

%% plot
if PlotOut
    Colours;
    if ~Sub
        figure;
        set(gcf,'Position',[200 200 250 550]);
    end
    for Time = 1:2
        if size(ToPlot,3) > 1
            P = signrank(squeeze(ToPlot(Time,1,:)),squeeze(ToPlot(Time,2,:)));
            text(-0.5+Time,max(ToPlot(:)),num2str(P),'color',Black)
        else
            errorbar(repmat([(1*(Time-1)) (1*(Time-1))+0.5],[size(ToPlot,3) 1])',squeeze([ToPlot(Time,1,:) ToPlot(Time,2,:)]),...
                squeeze([ToPlotCI(Time,1,:,1) - ToPlot(Time,1,:) ToPlotCI(Time,2,:,1) - ToPlot(Time,2,:)]),squeeze([ToPlotCI(Time,1,:,2)-ToPlot(Time,1,:) ToPlotCI(Time,2,:,2)-ToPlot(Time,2,:)]),...
                'color',Black);
        end
        hold on;
        
        Fig= plot(repmat([(1*(Time-1)) (1*(Time-1))+0.5],[size(ToPlot,3) 1])',squeeze([ToPlot(Time,1,:) ToPlot(Time,2,:)]),...
            'color',Grey,'LineWidth',0.5,'Marker','none','MarkerFaceColor',Grey,'MarkerSize',6,'MarkerEdgeColor','none');
        
        plot(repmat([ (1*(Time-1))],[size(ToPlot,3) 1])',squeeze([ToPlot(Time,1,:)]),...
            'color',Black,'Marker','o','MarkerFaceColor',White,'MarkerSize',6,'MarkerEdgeColor',Black,'LineWidth',1,'LineStyle','none');
        plot(repmat([ (1*(Time-1))+0.5],[size(ToPlot,3) 1])',squeeze([ToPlot(Time,2,:)]),...
            'color',Red,'Marker','o','MarkerFaceColor',White,'MarkerSize',6,'MarkerEdgeColor',Red,'LineWidth',1,'LineStyle','none');
        
        line([(Time-1)-0.14 (Time-1)+0.14],[nanmedian([ToPlot(Time,1,:)]) nanmedian([ToPlot(Time,1,:)])],'LineWidth',2,'Color',Black)
        line([(Time-0.5)-0.14 (Time-0.5)+0.14],[nanmedian([ToPlot(Time,2,:)]) nanmedian([ToPlot(Time,2,:)])],'LineWidth',2,'Color',Black)
        %         plot([(Time+0.5)-0.25 (Time+0.5)+0.25],)
    end
    Ax= gca;
    Ax.XTick = [0.25 1.25];
    Ax.XLim  = [-0.15 1.65];
    Ax.YTick = [];
    if exist('YLim','var')
        Ax.YLim = YLim;
    else
        Ax.YLim = [(min(ToPlotCI(:)) - std(ToPlot(:))) max(ToPlotCI(:)) + std(ToPlot(:))];
    end
    Ax.XTickLabel = {'early delay';'late delay'};
    
    ylabel('CCD');
    
end
end
