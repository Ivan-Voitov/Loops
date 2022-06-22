function trial_history(Trial,Type)
%% select
if ~exist('Type','var')
    Type = 1
end
%% calculate [Selection] (basically more advanced form of destruct with logicals)
Selection = cell(4,2); % trial type (cue/distractor, probe, targetnot, targetfa'd) by task.
TaskIsTwo = destruct(Trial,'Task')==2;
TaskIsOne = destruct(Trial,'Task')==1;

Selection{1,1} = and(TaskIsTwo,destruct(Trial,'Stimulus')==15);
Selection{2,1} = and(TaskIsTwo,destruct(Trial,'Stimulus')==21);
Selection{3,1} = and(TaskIsTwo,destruct(Trial,'Type')==3);

Selection{1,2} = and(TaskIsOne,destruct(Trial,'Type')==1);
Selection{2,2} = and(TaskIsOne,destruct(Trial,'Stimulus')==21);
Selection{3,2} = and(TaskIsOne,destruct(Trial,'Type')==3);

% for contextual and not
if Type == 1
    BlockLocation = destruct(Trial,'BlockLocation');
else
    BlockLocation = destruct(Trial,'TaskLocation');
end
for I = 1:2
    % for each type
    for II = 1:3
%                 Index = [1 4 7 10 13 16 19 22];
        Index = [1:1:21];
        for K = 1:length(Index)-1%1:1:20
            TempTrial = Trial(and(Selection{II,I},and(BlockLocation >= Index(K),BlockLocation < Index(K+1))));
            %             Perf(II,I,K) = sum(destruct(TempTrial,'StimulusResponse'), 'omitnan' ) ./ length(TempTrial);
            %             if Perf(II,I,K) == 0; Perf(II,I,K) = 0.0005;end
            %             if Perf(II,I,K) == 1; Perf(II,I,K) = 0.9995;end
            %             CI(II,I,K) = 1.96*(((Perf(II,I,K) *(1-Perf(II,I,K) ))   /length(TempTrial))   .^0.5);
            [Perf(II,I,K), X] =  binofit(nansum(destruct(TempTrial,'StimulusResponse')),length(TempTrial));
            CI(II,I,K,:) = X;%[Perf(II,I,K)-X(1) Perf(II,I,K)-X(2)];
        end
        for K = 2:length(Index)-2%1:1:20
            if isnan(Perf(II,I,K))
                Perf(II,I,K) = (Perf(II,I,K-1) + Perf(II,I,K+1)) ./ 2;
                 CI(II,I,K,:) =  (CI(II,I,K-1,:) +  CI(II,I,K+1,:)) ./ 2;
            end
        end
    end
end

%% stats
try
for I = 1:length(Trial); MouseNames{I} = Trial(I).MouseName; end
Sessions = unique(MouseNames);
for I = 1:length(Trial); S(I) = find(strcmp(Trial(I).MouseName,Sessions)); end
BlockLocation = destruct(Trial,'BlockLocation');
Task = 3 - destruct(Trial,'Task');
for Session = 1:length(Sessions)
    for T = 1:2
        for Location = 2:20
            TempTrial = Trial(and((S == Session)',and(BlockLocation == Location,Task == T )));
            Responses = destruct(TempTrial,'StimulusResponse'); Responses(isnan(Responses)) = 0;
            Stat(Session,Location-1+((T==2)*19)) = 1 - (1-nanmean(Responses(destruct(TempTrial,'Type')==3))) - nanmean(Responses(destruct(TempTrial,'Type')==1));
        end
    end
end
Stat(isnan(Stat)) = 1;

LocationGroup = repmat([2:20]',[2 1]);
TaskGroup = cat(1,repmat(1,[19 1]), repmat(2,[19 1]));
LocationGroup = repmat(LocationGroup,[9 1]);
TaskGroup = repmat(TaskGroup,[9 1]);
Stat = reshape(Stat',[9*38 1]);
anovan(Stat,{LocationGroup-1,TaskGroup},'model','full','varnames',{'Location';'Task'});

% discrimination task not significant
fitglm(LocationGroup(TaskGroup==1),Stat(TaskGroup == 1),'linear','Distribution','normal','Dispersion', true);
end
%% plot
% bug
% Perf(3,2,1) = nan



% [Axes, ~] = tight_fig(1, 1, 0.02, [0.12 0.05], [0.18 0.1],1,600,600);
   [Axes(1), ~] = tight_fig(1, 1, 0.02, [0.46 0.05], [0.22 0.1],1,400,600);
    [Axes(2), ~] = tight_fig(1, 1, 0.02, [0.12 0.72], [0.22 0.1],0,400,600);
    set(gcf, 'currentaxes', Axes(1)); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Colours;
% Blue = Blue;
% Red =  Red;
hold on;
% axis([1 7 0 100]);
axis([1 20 0 100]);
% Axes.XTick = [1:1:7];
% Axes.XTickLabel = 1:3:22;
Axes(1).XTick = [1:6:20];
Axes(1).XTickLabel = 1:6:20;
xlabel('Number of Trials from previous Target','FontSize',12);
ylabel('Response probability (%)','FontSize',12)
Axes(1).YColor = 'k';
Axes(1).YTick = [0 50 100];
Axes(1).YTickLabel = [0 50 100];
Axes(1).FontSize = 12;
% ytickformat(Axes, 'percentage');

% NumPoints = 7;
NumPoints = 20;
% cue/distractor
patches([],squeeze(CI(1,1,:,:)).*100,[1:1:NumPoints],'Colour',Blue)
A = plot(squeeze(Perf(1,1,:))'.*100,'Color',Blue,'LineWidth',2,'LineStyle','--','Marker','none','MarkerSize',13,'MarkerFaceColor','w');
patches([],squeeze(CI(1,2,:,:)).*100,[1:1:NumPoints],'Colour',Red)
% NewE = plot(squeeze(Perf(1,2,:))'.*100,'Color',[0.5 0.5 0.5],'LineWidth',1.7,'LineStyle','none','Marker','s','MarkerSize',13,'MarkerFaceColor','w');
B = plot(squeeze(Perf(1,2,:))'.*100,'Color',Red,'LineWidth',2,'LineStyle','--','Marker','none','MarkerSize',13,'MarkerFaceColor','w');

% Tar

patches([],squeeze(CI(3,1,:,:)).*100,[1:1:NumPoints],'Colour',Blue)
% NewE = plot(squeeze(Perf(3,1,:))'.*100,'Color',[0.5 0.5 0.5],'LineWidth',1.5,'LineStyle','none','Marker','o','MarkerSize',12,'MarkerFaceColor','w');

E = plot(squeeze(Perf(3,1,:))'.*100,'Color',Blue,'LineWidth',2,'LineStyle','-','Marker','none','MarkerSize',13,'MarkerFaceColor','w');
patches([],squeeze(CI(3,2,:,:)).*100,[1:1:NumPoints],'Colour',Red)
% NewF = plot(squeeze(Perf(3,2,:))'.*100,'Color',[0.5 0.5 0.5],'LineWidth',1.5,'LineStyle','none','Marker','o','MarkerSize',13,'MarkerFaceColor','w');

F = plot(squeeze(Perf(3,2,:))'.*100,'Color',Red,'LineWidth',2,'LineStyle','-','Marker','none','MarkerSize',13,'MarkerFaceColor','w');

set(gcf, 'currentaxes', Axes(2)); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on;
% axis([1 7 0 100]);
axis([1 20 0 20]);
% Axes.XTick = [1:1:7];
% Axes.XTickLabel = 1:3:22;
Axes(2).XTick = [1:6:20];
Axes(2).XTickLabel = 1:6:20;
xlabel('Number of Trials from previous Target','FontSize',12);
ylabel('Response probability (%)','FontSize',12)
Axes(2).YColor = 'k';
Axes(2).YTick = [0  20];
Axes(2).YTickLabel = [0  20];
Axes(2).FontSize = 12;
% ytickformat(Axes, 'percentage');

% NumPoints = 7;
NumPoints = 20;
% % probe
patches([],squeeze(CI(2,1,:,:)).*100,[1:1:20],'Colour','b')
C = plot(squeeze(Perf(2,1,:))'.*100,'LineStyle','--','color','b','LineWidth',2,'Marker','none','MarkerSize',12,'MarkerFaceColor','w');
patches([],squeeze(CI(2,2,:,:)).*100,[1:1:20],'Colour','r')
D = plot(squeeze(Perf(2,2,:))'.*100,'LineStyle','--','color','r','LineWidth',2,'Marker','none','MarkerSize',12,'MarkerFaceColor','w');





% Legend = legend([A B E F],'Perceptual - Distractor FAs','Memory - Cue FAs',...
%     'Perceptual - Target Hits','Memory - Target Hits');
% Legend = legend([NewE NewF  ],'False Alarms','Hits');
% Legend.Location = 'east';

% title('History effect - # of Trials from from Target switch');
%%