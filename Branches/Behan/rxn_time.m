function [Stat] = rxn_time(Trial,DFType,varargin)
%% PASS ARGUMENTS
EnMouse = false; % (only for stats)

for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

%% ORGANIZE
if EnMouse
    for I = 1:length(Trial); MouseNames{I} = Trial(I).MouseName; end
    Sessions = unique(MouseNames);
    for I = 1:length(Trial); S(I) = find(strcmp(Trial(I).MouseName,Sessions)); end
else
    for I = 1:length(Trial); FileNames{I} = Trial(I).FileName; end
    Sessions = unique(FileNames);
    for I = 1:length(Trial); S(I) = find(strcmp(Trial(I).FileName,Sessions)); end
end

%% EXTRACT
% all data
for I = 1:length(Trial)
    RxnTime(I) = Trial(I).ResponseTime - Trial(I).Trigger.Stimulus.Time;
end
Z = 1;
for Task = [1 2]
    for Type = [1 3]
        Gram{Z} = RxnTime(and(destruct(Trial,'Task')==Task,destruct(Trial,'Type')==Type));
        Z = Z + 1;
    end
end
for Z = 1:4
    Gram{Z} = (round(Gram{Z}./16.6667));
    Gram{Z}(end+1) = 100;
end

% for each session/mouse

for Session = 1:length(Sessions)
    TempTrial = Trial(Session == S);
    clearvars RxnTime
    for I = 1:length(TempTrial)
        RxnTime(I) = TempTrial(I).ResponseTime - TempTrial(I).Trigger.Stimulus.Time;
    end
    Z = 1;
    for Task = [1 2]
        for Type = [1 3]
            TempStat = RxnTime(and(destruct(TempTrial,'Task')==(3-Task),destruct(TempTrial,'Type')==Type));
            TempStat = TempStat(~isnan(TempStat));
            TempBin = round((length(TempStat).^0.5));
            [X,Xc] = histcounts(TempStat,TempBin-1,'Normalization','count');
            if DFType == 0
                [~,Ind] = max(diff(X));
                Stat(Z,Session,1) = Xc(Ind);
            elseif DFType == 1
                [~,Ind] = max((X));
                Stat(Z,Session,1) = Xc(Ind);
            end
            %             histcounts(TempStat,60,'Normalization','count');
            %             figure;
            %             histogram(TempStat,round(length(TempStat).^0.5),'Normalization','pdf'...
            %                 ,'FaceColor','k','EdgeColor','none');
            %
            %             Stat(Z,Session,1) = []; % kink in cdf
            %             Stat(Z,Session,2) = [];
            
            Z = Z + 1;
        end
    end
end
[PFA] = signrank(Stat([1],:),Stat([3],:));
[PMS] = signrank(Stat([2],:),Stat([4],:));

%% for for all
TempTrial = Trial;
for I = 1:length(TempTrial)
    RxnTime(I) = TempTrial(I).ResponseTime - TempTrial(I).Trigger.Stimulus.Time;
end
Z = 1;
for Task = [1 2]
    for Type = [1 3]
        TempStat = RxnTime(and(destruct(TempTrial,'Task')==(3-Task),destruct(TempTrial,'Type')==Type));
        TempStat = TempStat(~isnan(TempStat));
        TempBin = round((length(TempStat).^0.5));
        [X,Xc] = histcounts(TempStat,TempBin-1,'Normalization','count');
        
        if DFType == 0
            [~,Ind] = max(diff(X));
            AllStat(Z,1) = Xc(Ind+1);
        elseif DFType == 1
            [~,Ind] = max((X));
            AllStat(Z,1) = Xc(Ind+1);
        end
        Z = Z + 1;
    end
end

            



%% plot
Colours;
if DFType == 1
    for Z = 1:4
        Gram{Z}(isnan(Gram{Z})) = [];
    end
end
Fig = figure;
Axes(1) = subplot(2,4,1:3);
Axes(2) = subplot(2,4,5:7);
Axes(3) = subplot(2,4,4);
Axes(4) = subplot(2,4,8);
%
% [Axes(1), ~] = tight_fig(1, 1, 0.02, [0.59 0.05], [0.18 0.1],1,300,600);
% [Axes(2), ~] = tight_fig(1, 1, 0.02, [0.12 0.52], [0.18 0.1],0,300,600);

% top
set(gcf, 'currentaxes', Axes(1));% fas hold on;
hold on;
if DFType == 1
    histogram(Gram{3},60,'BinWidth',1,'Normalization','pdf'...
        ,'FaceColor',Blue,'EdgeColor','none');
    histogram(Gram{1},60,'BinWidth',1,'Normalization','pdf'...
        ,'FaceColor',Red,'EdgeColor','none');
    axis([0 60 0 0.07]);
    title('False Alarms','FontSize',16);
    Axes(1).YTick = [0 0.07];
    Axes(1).YTickLabel = [0 0.07];
else
    histogram(Gram{3},60,'DisplayStyle','stairs','BinWidth',1,'Normalization','cdf'...
        ,'FaceColor','none','EdgeColor',Blue,'LineWidth',2);
    histogram(Gram{1},60,'DisplayStyle','stairs','BinWidth',1,'Normalization','cdf'...
        ,'FaceColor','none','EdgeColor',Red,'LineWidth',2);
    axis([0 60 0 0.4]);
    %     title('Cues or Distractors','FontSize',16);
    title('False Alarms','FontSize',16);
    % set(gca, 'YScale', 'log')
    Axes(1).YTick = [0 0.4];
    Axes(1).YTickLabel = [0 0.4];
end
line(([AllStat(1) AllStat(1)]) ./ 16.6667,[0 1],'color',Blue);
text(AllStat(1)/16.6667,0.05,num2str(AllStat(1)),'color',Blue)
line(([AllStat(3) AllStat(3)]) ./ 16.6667,[0 1],'color',Red);
text(AllStat(3)/16.6667,0.02,num2str(AllStat(3)),'color',Red)

ylabel('Probability','FontSize',12);
Axes(1).FontSize = 12;
% Axes(1).XTick = [0 12 24 36 48 60];
% hits
set(gcf, 'currentaxes', Axes(2));
hold on;
if DFType == 1
    histogram(Gram{4},60,'BinWidth',1,'Normalization','pdf'...
        ,'FaceColor',Blue,'EdgeColor','none');
    histogram(Gram{2},60,'BinWidth',1,'Normalization','pdf'...
        ,'FaceColor',Red,'EdgeColor','none');
    axis([0 60 0 0.07]);
    title('Hits','FontSize',12);
    Axes(2).YTick = [0 0.07];
    Axes(2).YTickLabel = [0 0.07];
else
    histogram(Gram{4},60,'DisplayStyle','stairs','BinWidth',1,'Normalization','cdf'...
        ,'FaceColor','none','EdgeColor',Blue,'LineWidth',2);
    histogram(Gram{2},60,'DisplayStyle','stairs','BinWidth',1,'Normalization','cdf'...
        ,'FaceColor','none','EdgeColor',Red,'LineWidth',2);
    axis([0 60 0 1]);
    %     title('Targets','FontSize',16);
    title('Hits','FontSize',16);
    %     set(gca, 'YScale', 'log')
    Axes(2).YTick = [0 0.4 1];
    Axes(2).YTickLabel = [0 0.4 1];
end

ylabel('Probability','FontSize',12);
% xlabel('Reaction Time (ms)','FontSize',16);
xlabel('Response time (ms)','FontSize',12);
Axes(2).XTick = [0 12 24 36 48 60];
Axes(2).XTickLabel = {'0';'200';'400';'600';'800';'1000'};
Axes(1).XTick = [0 12 24 36 48 60];
Axes(1).XTickLabel = {'0';'200';'400';'600';'800';'1000'};
xlabel('Reaction time (ms)','FontSize',12);
% Axes(2).YTick = [];
Axes(2).FontSize = 12;

line(([AllStat(2) AllStat(2)]) ./ 16.6667,[0 1],'color',Blue);
text(AllStat(2)/16.6667,0.05,num2str(AllStat(2)),'color',Blue)
line(([AllStat(4) AllStat(4)]) ./ 16.6667,[0 1],'color',Red);
text(AllStat(4)/16.6667,0.02,num2str(AllStat(4)),'color',Red)

% stats FAs

set(gcf, 'currentaxes', Axes(3));% fas hold on;
hold on;
plot(Stat([1 3],:),'LineWidth',1,'color',Grey,'MarkerSize',6,'Marker','o','MarkerFaceColor',White);
plot(repmat(1,[size(Stat,2)]),Stat([1],:),'LineWidth',1,'LineStyle','none','MarkerSize',6,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Blue);
plot(repmat(2,[size(Stat,2)]),Stat([3],:),'LineWidth',1,'LineStyle','none','MarkerSize',6,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Red);
plot([0.75 1.25],repmat(nanmedian(Stat([1],:)), [2 1]),'color',Black,'LineWidth',2);
plot([1.75 2.25],repmat(nanmedian(Stat([3],:)), [2 1]),'color',Black,'LineWidth',2);

% plot([0.75 1.25],[AllStat([1]) AllStat([1])],'LineWidth',2,'color',Black);
% plot([1.75 2.25],[AllStat([3]) AllStat([3])],'LineWidth',2,'color',Black);
Axes(3).XLim = [0.5 2.5]; Axes(3).XTick = [1 2]; Axes(3).YLim = [0 600]; Axes(3).YTick = [0 200 400 600 800 1000];
Axes(3).XTickLabel = {'D';'WM'};
if DFType == 1; ylabel('Peak reaction time (ms)'); else;  ylabel('Kink reaction time (ms)');end

text(1.5,100,num2str(PFA));
text(1.5,500,num2str(nanmean(Stat([1],:))),'color',Blue)
text(1.5,300,num2str(nanmean(Stat([3],:))),'color',Red)

% stats MSs
set(gcf, 'currentaxes', Axes(4));% fas hold on;
hold on;
plot(Stat([2 4],:),'LineWidth',1,'color',Grey);
plot(repmat(1,[size(Stat,2)]),Stat([2],:),'LineWidth',1,'LineStyle','none','MarkerSize',6,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Blue);
plot(repmat(2,[size(Stat,2)]),Stat([4],:),'LineWidth',1,'LineStyle','none','MarkerSize',6,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Red);
% plot(mean(Stat([2 4],:),2) ,'LineWidth',2,'color',Black);
% plot([0.75 1.25],[AllStat([2]) AllStat([2])],'LineWidth',2,'color',Black);
% plot([1.75 2.25],[AllStat([4]) AllStat([4])],'LineWidth',2,'color',Black);
plot([0.75 1.25],repmat(nanmedian(Stat([2],:)), [2 1]),'color',Black,'LineWidth',2);
plot([1.75 2.25],repmat(nanmedian(Stat([4],:)), [2 1]),'color',Black,'LineWidth',2);

Axes(4).XLim = [0.5 2.5]; Axes(4).XTick = [1 2]; Axes(4).YLim = [0 800]; Axes(4).YTick = [0 200 400 600 800 1000];
Axes(4).XTickLabel = {'D';'WM'}; 
if DFType == 1; ylabel('Peak reaction time (ms)'); else;  ylabel('Kink reaction time (ms)');end
text(1.5,100,num2str(PMS));
text(1.5,500,num2str(nanmean(Stat([2],:))),'color',Blue)
text(1.5,300,num2str(nanmean(Stat([4],:))),'color',Red)
