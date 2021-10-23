function cd_comparison(Meso)

%% extract values
[DFFs,CCDTrials] = rip(Meso,'S','DeNaN','NoStimulusResponsive','Active','Context');
[~,WMCDTrials] = rip(Meso,'Super','Beh');

%% how different are the two vectors?
FPS = 4.68;
Threshold = 10^-3;
Lag = 0;
clearvars CCD CCLass CCP WMCD WMClass WMCP
for S = 1:length(Meso)
    TempDFF = DFFs{S};
    %     {zscore(DFFs{S}',[],'omitnan')'}
    
    % remove the subthreshold DFFs
    for Type = 1:2 % CD tyoe
        TempTrial = swaparoo({WMCDTrials{S}; CCDTrials{S}},Type);
        TrigOn = destruct(TempTrial,'Trigger.Delay.Frame');
        TrigOff = destruct(TempTrial,'Trigger.Stimulus.Frame');
        Activities = wind_roi(TempDFF,{TrigOn;TrigOff},'Window',[1 frame(3200,FPS)]);
        if Lag
            Activities(:,1:frame(Lag,FPS),:) = nan;
        end
        Values{Type} = (reshape((nanmean(Activities,2)),[size(Activities,1) size(Activities,3)]));
    end
    TempDFF(or(nanmean(Values{2},2)<Threshold,nanmean(Values{1},2)<Threshold),:) = [];
    
    % {zscore(DFFs{S}',[],'omitnan')'} % folds 1 % normalizeLDA [] 0 1
    [Temp] = encode({{TempDFF},CCDTrials(S)},'Window',[-1000 3200],'OnlyCorrect',true,'Equate',true,'Threshold',[],'Iterate',20,...
        'Folds',10,'NormalizeLDA',1,'FPS',4.68,'Lag',400);
    %     [Temp] = encode4({{TempDFF},{CCDTrials{S}(1:2:end)}},'Window',[-1000 3200],'OnlyCorrect',true,'Equate',true,'Threshold',[],'Iterate',20,...
    %         'Folds',1,'NormalizeLDA',[],'FPS',4.68,'Lag',0);
    
    CCD{S}(:) = Temp{1}{1}(2:end);
    CClass(S) = Temp{3};
    CCP{S}(:) = Temp{6}{1};
    
    %     [Temp] = encode4({{TempDFF},{CCDTrials{S}(2:2:end)}},'Window',[-1000 3200],'OnlyCorrect',true,'Equate',true,'Threshold',[],'Iterate',20,...
    %         'Folds',1,'NormalizeLDA',[],'FPS',4.68,'Lag',0);
    [Temp] = encode({{TempDFF},WMCDTrials(S)},'Window',[-1000 3200],'OnlyCorrect',true,'Equate',true,'Threshold',[],'Iterate',20,...
        'Folds',10,'NormalizeLDA',1,'FPS',4.68,'Lag',400);
    
    WMCD{S}(:) = Temp{1}{1}(2:end);
    WMClass(S) = Temp{3};
    WMCP{S}(:) = Temp{6}{1};
end

figure;
for S = 1:length(Meso)
    Sign = sign(CCDTrials{S}(1).DB);
    Temp = nanmean(sign(squeeze(WMCD{S})) == (Sign*sign(squeeze(CCD{S}))));
    %     Temp = corrcoef(squeeze(WMCD{S}),squeeze(CCD{S}));
    %             Temp = corrcoef(WMCP{S}(~or(isnan(WMCP{S}),isnan(CCP{S}))),CCP{S}(~or(isnan(WMCP{S}),isnan(CCP{S}))));
    %     ToPlot(S) = Temp(2) .* Sign;
    ToPlot(S) = Temp;
    plot(ToPlot);
    text(1,0.5,strcat({'Average correlation is '}, num2str(mean(ToPlot))));
    text(1,0,strcat({'Average WM classification accuracy is '},num2str(nanmean(WMClass))));
    text(1,0.2,strcat({'Average Cue classification accuracy is '},num2str(nanmean(CClass))));
    Ax = gca; Ax.YLim = [-0.5 1];
end

%
%
% %%
% % Out = encode4({DFFs;CCDTrials},'Window',[-1000 3200],'OnlyCorrect',true,'OnlyPostCue',false,'Equate',true,'DePre',false,'Clever',false,'Iterate',50,...
% %     'NormalizeLDA',false);
% % Index = encode3(Index,'Window',[-1000 3200],'OnlyCorrect',true,'Equate',true,'DePre',false,'Clever',false,'Iterate',50,...
% %     'NormalizeLDA',false);
%
% WMCD = [];
% CCD = [];
% for S = 1:length(DFFs)
% %     TempWMCD = Index(S).Basis(2:end);
% %     TempCCD = Out{1}{S}(2:end);
%     TempWMCD = Diff{1}{S};
%     TempCCD = Diff{2}{S};
%     TempCCD(isnan(TempWMCD)) = [];
%     TempWMCD(isnan(TempWMCD)) = [];
%     TempWMCD(isnan(TempCCD)) = [];
%     TempCCD(isnan(TempCCD)) = [];

%     DB(S) = CCDTrials{S}(10).DB;
%     TempWMCD = TempWMCD.*sign(-DB(S));
%
%     X{S} = fitlm(TempWMCD,TempCCD);
%     Rs(S) = X{S}.Rsquared.Ordinary;
%     Slopes(S) = X{S}.Coefficients.Estimate(2);
%     Temp = corrcoef(TempWMCD,TempCCD);
%     Corrs(S) = Temp(2);
%
%     WMCD = cat(1,WMCD,TempWMCD);
%     CCD = cat(1,CCD,TempCCD);
% end
% figure; Colours;
% subplot(1,2,1)
% scatter(ones(length(Corrs),1),Corrs,'k','LineWidth',1); hold on
% plot([0.75 1.25],[median(Corrs) median(Corrs)],'k','LineWidth',2);
%
% Ax = gca; Ax.XTick = []; Ax.YTick = sort([-1  0 median(Corrs) 1]); Ax.YLim = [-1 1];
% Ax.XLim = [0.5 1.5];
% title('WMCD and Cue decoding dimension correlations')
% subplot(1,2,2)
% [~,Ind] = max(Corrs);
% MP = plot(X{Ind},'Marker','none','MarkerEdgeColor','none','MarkerFaceColor',Black);
% title('Example session')
% hold on;
% MPP = scatter(Diff{1}{Ind},Diff{2}{Ind},10,'Marker','o','MarkerEdgeColor','none','MarkerFaceColor',Black);
% alpha(MPP,0.2);
% %         MPP.Color = cat(2,Colour{Task},0.2);
% %         MP(1).Color = cat(2,Colour{Task},0.2);
% %         FaceAlpha = 1
% FitP=findobj(MP,'DisplayName','Fit');
% FitP.Color=Black;
% FitP.LineWidth=2;
% for Z = 3:4
%     CIP = MP(Z);
%     CIP.LineWidth=0.75;
%     CIP.Color = Black;
%     CIP.LineStyle ='--';
% end
% Ax = gca; xlabel('Working memory - Discrimination delay activity'); ylabel('-45 Cue - +45 Cue delay activity')
% legend off
% text(-0.1,0.1,strcat('R^2 =',num2str(X{Ind}.Rsquared.Ordinary)))
%
% %% just decode
% Out = encode4({DFFs;CCDTrials},'Window',[-1000 3200],'OnlyCorrect',true,'OnlyPostCue',false,'Equate',true,'DePre',false,'Clever',false,'Iterate',50,...
%     'NormalizeLDA',true,'Lag',Lag);
% DiscOut = encode4({DFFs;DiscCCDTrials},'Window',[-1000 3200],'OnlyCorrect',true,'OnlyPostCue',false,'Equate',true,'DePre',false,'Clever',false,'Iterate',50,...
%     'NormalizeLDA',true,'Lag',Lag);
%
% % see pre FA and PostProbe what happens?
% for Session = 1:length(DFFs)
%     Score = Out{2}{Session};
%     DiscScore = DiscOut{2}{Session};
%     PostProbe = ~isnan(destruct(CCDTrials{Session},'Post.Probe'));
%     Incorrect = or(destruct(CCDTrials{Session},'ResponseType')==2,destruct(CCDTrials{Session},'ResponseType')==3);
%     Labels = destruct(CCDTrials{Session},'Block');
%     DiscLabels = destruct(DiscCCDTrials{Session},'Block');
%     TimeLabels = destruct(CCDTrials{Session},'Trigger.Stimulus.Time')>1600;
%     Class(Session,1) = nanmean([Score(and(Labels==1,and(~PostProbe,~Incorrect)))<0;Score(and(Labels==0,and(~PostProbe,~Incorrect)))>=0]);
%     Class(Session,2) = nanmean([Score(and(Labels==1,PostProbe))<0;Score(and(Labels==0,PostProbe))>=0]);
%     Class(Session,3) = nanmean([Score(and(Labels==1,Incorrect))<0;Score(and(Labels==0,Incorrect))>=0]);
%     Class(Session,4) = nanmean([DiscScore(DiscLabels==1)<0;DiscScore(DiscLabels==0)>=0]);
%     Class(Session,5) = nanmean([Score(and(TimeLabels==1,and(~PostProbe,~Incorrect)))<0;Score(and(TimeLabels==0,and(~PostProbe,~Incorrect)))>=0]);
% end
%
% %% plot
% Colours;
% figure;
% plot(repmat([1 2 3 4 5],[size(Class,1) 1])',[Class(:,1) Class(:,2) Class(:,3) Class(:,4) Class(:,5)]','color',Grey,'LineStyle','none','LineWidth',1,'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Black);
% hold on
% for K = 1:5
% plot([0.75+(K-1) 1.25+(K-1)],[nanmedian(Class(:,K)) nanmedian(Class(:,K))],'LineWidth',2,'color',Black);
% end
% P1 = signrank(Class(:,1),Class(:,2));
% P2 = signrank(Class(:,1),Class(:,3));
% text(1,0.5,num2str(P1));
% text(2,0.5,num2str(P2));
% Ax= gca; Ax.YLim = [0 1]; Ax.YTick = sort([0 0.5 nanmedian(Class(:,1)) 1]); Ax.XLim = [0 6];Ax.XTick = [1 2 3 4 5];Ax.XTickLabel = ({'Following a Cue';'Following a Probe';'Pre FA';'Discrimination task';'Decoding time'});
% ylabel('Classification accuracy');