%% I.E., ALL TRIALS WHICH THE MOUSE EARLY LICKED OR STOPPED DURING THE DELAY WERE EXCLUDED FROM FURTHER ANALYSIS
function delay_speed_halt_lick(Trial,varargin)
EnMouse = true;

for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

Data = Trial{2};
Trial = Trial{1};

%% organize
if EnMouse
    for I = 1:length(Trial); MouseNames{I} = Trial(I).MouseName; end
    Sessions = unique(MouseNames);
    for I = 1:length(Trial); S(I) = find(strcmp(Trial(I).MouseName,Sessions)); end
else
    for I = 1:length(Trial); FileNames{I} = Trial(I).FileName; end
    Sessions = unique(FileNames);
    for I = 1:length(Trial); S(I) = find(strcmp(Trial(I).FileName,Sessions)); end
end

for Session = 1:length(Sessions)
   Trials(Session) = {Trial(S==Session)}; 
   Datas(Session) = {Data(S==Session)}; 
end

%% extract triggers and trace

TempExtracted = cell(2,3,length(Session));
for Session = 1:length(Trials)
    
    TempTrial= Trials{Session};
    TaskLabel = 3 - destruct(TempTrial,'Task');
    Data = Datas{Session};
    BehStimulusOnset = destruct(TempTrial,'Trigger.Stimulus.Line') + 1;
    BehDelayOnset = TempTrial(1).Trigger.Delay.Line + 1;
    
    %     Temp{1,1,MouseIDs(Session)} = cat(1,Temp{1,1,MouseIDs(Session)},destruct(Trial(Task==2),'DelayResponse')==1);
    %     Temp{2,1,MouseIDs(Session)} = cat(1,Temp{2,1,MouseIDs(Session)},destruct(Trial(Task==1),'DelayResponse')==1);
    %     Temp{1,2,MouseIDs(Session)} = cat(1,Temp{1,2,MouseIDs(Session)},destruct(Trial(Task==2),'Reset')==1);
    %     Temp{2,2,MouseIDs(Session)} = cat(1,Temp{2,2,MouseIDs(Session)},destruct(Trial(Task==1),'Reset')==1);
    for Task = 1:2
        TT = 1;
        for T = find(TaskLabel == Task)' %1:length(Data)
            if frame(3200,60) < BehStimulusOnset(T)
                TempTraces{Session,Task}(TT,:) = Data{T}(BehDelayOnset:frame(3200,60)+BehDelayOnset-1,4);
            else
                TempTraces{Session,Task}(TT,:) = cat(1,Data{T}(BehDelayOnset:BehStimulusOnset(T),4),nan(frame(3200,60)-size(Data{T}(BehDelayOnset:BehStimulusOnset(T),4),1),1));
            end
            TT = TT + 1;
        end
        
        TempExtracted{Task,1,(Session)} = destruct(TempTrial(Task==TaskLabel),'DelayResponse')==1;
        TempExtracted{Task,2,(Session)} = destruct(TempTrial(Task==TaskLabel),'Reset')==1;
        TempExtracted{Task,3,(Session)} = nanmean(TempTraces{Session,Task}(:));
    end
end

for Mouse = 1:size(TempExtracted,3)
    for Task = 1:2
        for K = 1:3
            ToPlot{Task,K}(Mouse) = nanmean(TempExtracted{Task,K,Mouse}) ;
        end
    end
end

%% all mice
Task = destruct(Trial,'Task');
AllPlot(1,1) = nanmean(destruct(Trial(Task==2),'DelayResponse')==1) .* 100;
AllPlot(2,1) = nanmean(destruct(Trial(Task==1),'DelayResponse')==1) .* 100;
AllPlot(1,2) = nanmean(destruct(Trial(Task==2),'Reset')==1) .* 100;
AllPlot(2,2) = nanmean(destruct(Trial(Task==1),'Reset')==1) .* 100;
AllPlot(1,3) = nanmean(ToPlot{1,3});
AllPlot(2,3) = nanmean(ToPlot{2,3});

%% make box for speed and bar for early licking (%)
Colours;
figure;
% subplot(1,2,1);
% B = boxplot(Speed, 3-Task,'whisker',0.7193,'Symbol','','Colors',[Blue;Red]); % 95%
% set(B,{'linew'},{1.5});
% axis([0.5 2.5 0 100]);
% Ax = gca; Ax.XTick = []; Ax.YTick = [0 20 40 60 80 100];
% ylabel('Average running speed (cm/s)');

%% statistics for statistics
Titles = {'Delay licking';'Delay halting (<5 cm/s)';'Average running speed'};
for K = 1:3
    subplot(2,3,K); hold on;
%     scatter(ones(9,1),ToPlot{1,K},'MarkerFaceColor','none','MarkerEdgeColor',Black)
%     scatter(ones(9,1)+1,ToPlot{2,K},'MarkerFaceColor','none','MarkerEdgeColor',Black)
if K == 3
    plot([ToPlot{1,K}; ToPlot{2,K}],'color',Grey ,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Grey,'LineWidth',1)
else
    plot([ToPlot{1,K} .* 100; ToPlot{2,K} .* 100],'color',Grey ,'LineWidth',1)
    plot(repmat(1,[size(ToPlot{1,K},2) 1]),ToPlot{1,K} .* 100,'LineStyle','none' ,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Blue,'LineWidth',1)
    plot(repmat(2,[size(ToPlot{2,K},2) 1]),ToPlot{2,K} .* 100,'LineStyle','none' ,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Red,'LineWidth',1)
    plot([0.75 1.25],[nanmedian(ToPlot{1,K}) .* 100; nanmedian(ToPlot{1,K}) .* 100],'color',Black ,'LineWidth',2)
    plot([1.75 2.25],[nanmedian(ToPlot{2,K}) .* 100; nanmedian(ToPlot{2,K}) .* 100],'color',Black ,'LineWidth',2)
end
    axis([0.5 2.5 0 40]);
    Ax = gca; Ax.XTick = [1 2];  Ax.YTick = [0 20 40 60 80]; Ax.XTickLabel = {'D';'WM'};
    if K == 3; Ax.YLim = [0 80];ylabel('(cm/s)');else; ylabel('Probability');     ytickformat(Ax, 'percentage'); end
    if K == 1; Ax.YLim = [0 20];Ax.YTick = [0 10 20];Ax.YTickLabel= [0 10 20];ytickformat(Ax, 'percentage');end
    hold on
%     plot([0.8 1.2],[AllPlot(1,K) AllPlot(1,K)],'k','LineWidth',2)
%     plot([1.8 2.2], [AllPlot(2,K) AllPlot(2,K)],'k','LineWidth',2)
    [P(K)] = signrank(ToPlot{1,K}, ToPlot{2,K});
    title(Titles{K});
    text(1,20,num2str(P(K)));
end

%% bar version for paper
% for Session = 1:size(TempExtracted,3)
%     for K = 1:2
%         for Task = 1:2
%             ForBino{Task,K}(Session) = [sum(TempExtracted{Task,K,Session}) length(TempExtracted{Task,K,Session})];
%         end
%     end
% end
Titles = {'Delay licking';'Delay halting (<5 cm/s)';'Average running speed'};
for K = 1:3
    subplot(2,3,K+3); hold on;
    
    b = bar([mean( ToPlot{1,K}) mean( ToPlot{2,K})]);
    b(1).FaceColor = 'flat';
    b(1).CData(1,:) = [0.5 0.5 0.5];
    b(1).CData(2,:) = [0.5 0.5 0.5];
    hold on
    Ax = gca;
    if K == 3
        %             CI(1) = 1.96 * (std(ToPlot{1,K}) / (length(Trials))^0.5);
        %             CI(2) = 1.96 * (std(ToPlot{2,K}) / (length(Trials))^0.5);
        [~,~,Temp] = normfit(ToPlot{1,K});
        CI(1) = mean(ToPlot{1,K}) - Temp(1);
        [~,~,Temp] = normfit(ToPlot{2,K});
        CI(2) = mean(ToPlot{2,K}) - Temp(1);
        errorbar([1 2],[mean(ToPlot{1,K}); mean(ToPlot{2,K})]',[CI(2) ; CI(1)]','.k');
        Ax.YTick = [0 20 40 60 80];
        Ax.YLim = [0 80];
        
        Ax.YTickLabel = {'0';'20';'40';'60';'80'};
    else
        %         [X,CI(1,:)] = binofit(ForBino{1,K}(1),ForBino{1,K}(2));
        %         [Y,CI(2,:)] = binofit(ForBino{2,K}(1),ForBino{2,K}(2));
        %         CI(1,:) = X-CI(1,end:-1:1);
        %         CI(2,:) = Y-CI(2,end:-1:1);
        %         errorbar([1 2],[X; Y]',[CI(:,1)],[CI(:,2)],'.k');
        [~,~,Temp] = normfit(ToPlot{1,K});
        CI(1) = mean(ToPlot{1,K}) - Temp(1);
        [~,~,Temp] = normfit(ToPlot{2,K});
        CI(2) = mean(ToPlot{2,K}) - Temp(1);
        errorbar([1 2],[mean(ToPlot{1,K}); mean(ToPlot{2,K})]',[CI(2) ; CI(1)]','.k');
        
        Ax.YTick = [0 0.10 .20 ];
        Ax.YLim = [0 0.2];
        Ax.YTickLabel = {'0%';'10%';'20%'};
    end
    
    Ax.XTick = [1 2];
    Ax.XTickLabel = {'D';'M'};
end
    


%     
%     [~,CI{1}] = binofit(sum(ToPlot{1,K}==1),length(ToPlot{1,K}));
%     CI{1} = CI{1} - nanmean(ToPlot{1,K}==1);
%     CI{1} = CI{1} .* 100;
%     [~,CI{2}] = binofit(sum(ToPlot{2,K}==1),length(ToPlot{2,K}));
%     CI{2} = CI{2} - nanmean(ToPlot{2,K}==1);
%     CI{2} = CI{2} .* 100;
%     errorbar([1 2]',[nanmean(ToPlot{1,K}==1);nanmean(ToPlot{2,K}==1)]*100,...
%         [CI{1}(1);CI{2}(1)],...
%         [CI{1}(2);CI{2}(2)],...
%         '.k','LineWidth',1);

% % halt
% subplot(1,2,2);
% B = bar([nanmean(Stopping{1}==1),nanmean(Stopping{2}==1)]*100,0.6);
% B.FaceColor = 'flat'; B.CData(1,:) = Blue; B.CData(2,:) = Red;
% axis([0.5 2.5 0 100]);
% Ax = gca; Ax.XTick = [];  Ax.YTick = [0 20 40 60 80 100];
% ytickformat(Ax, 'percentage');
% ylabel('Halting probability (<5 cm/s)');
% hold on
% [~,CI{1}] = binofit(sum(Stopping{1}==1),length(Stopping{1}));
% CI{1} = CI{1} - nanmean(Stopping{1}==1);
% CI{1} = CI{1} .* 100;
% [~,CI{2}] = binofit(sum(Stopping{2}==1),length(Stopping{2}));
% CI{2} = CI{2} - nanmean(Stopping{2}==1);
% CI{2} = CI{2} .* 100;
% errorbar([1 2]',[nanmean(Stopping{1}==1);nanmean(Stopping{2}==1)]*100,...
%     [CI{1}(1);CI{2}(1)],...
%     [CI{1}(2);CI{2}(2)],...
%     '.k','LineWidth',1);

% %%
% Colours;
%     figure;
% for Task = [1:2]
%     Colour = {Red;Blue};
%     for Z = 1:3
%         %         1 3 5 2 4 6
%         subplot(2,3,(((3-Task)*3)-2)+Z-1); hold on;
%         patch([61 61 60 60],[0 80 80 0],'k','EdgeColor','none');
%         patch([97 97 61 61],[0 80 80 0],[0.4 0.8 1],'EdgeColor','none','FaceAlpha',0.5);
%
%         for ZZ = 1:3
%             if ZZ == 1
%                 plot(Avg{Task,ZZ,Z},'color',Grey,'LineStyle','--');
%             elseif ZZ == 2
%                 plot(Avg{Task,ZZ,Z},'color',Grey);
%             else
%                 TempCI = squeeze(CI{Task,ZZ,Z}(:,:,1));
%                 patches(Avg{Task,ZZ,Z},TempCI',[1:length(Avg{Task,ZZ,Z})],'Colour',Colour{Task})
%                 hold on;
%                 plot(Avg{Task,ZZ,Z},'color',Colour{Task});
%             end
%         end
%         axis([1 180 0 80]);
%         ylabel('Running speed (cm/s)');
%         Ax = gca;
%         Ax.YTick = [0 40 80];
%         Ax.XTick = [1 60.5 180];
%         Ax.XTickLabel = {'-1 s','0 s','+2 s'};
%
%     end
% end
% % % saveas(gcf,strcat('Plots/Optan/Run light traces',num2str(Task),'.svg'));
% %
