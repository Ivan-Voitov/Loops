% an encode-style function which has CDFA and also cross-task functionality
% and also does the cue just for now for sanity checks

function coding_compensation(Index,varargin)
%% READY
FPS = 4.68;
Normalize = false; % should not do because it changes origin of trace
Restrict = true; % do for now because easier to code (just super)
Short = false;
Long = false;

%% SET
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

if Restrict
    [TaskTraces,Trials] = rip(Index,'Trace','DeNaN','Super','Focus');
    [CueTraces,~] = rip(Index,'CueTrace','DeNaN','Context','Focus');
    CueTrials = Trials;
else
    % not super (both cues), need to do here due to focus
    [CueTraces,CueTrials] = rip(Index,'CueTrace','DeNaN','Context','Focus');
end

Trials = selector(Trials,'Memory');

for S = 1:length(Trials)
    if Long
        Trials{S} = Trials{S}(destruct(Trials{S},'Trigger.Stimulus.Time')>=1667);
    elseif Short
        Trials{S} = Trials{S}(destruct(Trials{S},'Trigger.Stimulus.Time')<1667);
    end
end
%% GO
PoolCorrectTask = {[];[]};
PoolIncorrectTask = {[];[]};

for S = 1:length(Index)
    if Normalize
        TaskTrace = zscore(TaskTraces{S},[],'omitnan');
        CueTrace = zscore(CueTraces{S},[],'omitnan');
    else
        TaskTrace = TaskTraces{S};
        CueTrace = CueTraces{S};
    end
    
    IsNaN = or(isnan(Index(S).TaskBasis(2:end)),isnan(Index(S).CueBasis(2:end)));
    TempCorr = corrcoef(Index(S).CueBasis([false; ~IsNaN]),Index(S).TaskBasis([false; ~IsNaN]));
    BasisCorr(S) = TempCorr(2);
    
    IsNaN = or(isnan(TaskTrace),isnan(CueTrace));
    TempCorr = corrcoef(TaskTrace(~IsNaN),CueTrace(~IsNaN).* sign(Trials{S}(1).DB));
    TraceCorr(S) = TempCorr(2);
    
    TempBeh = nan(length(Trials{S}),1);
%     TempBeh(or(destruct(Trials{S},'ResponseType') == 1,destruct(Trials{S},'ResponseType') == 4)) = false;
    TempBeh(destruct(Trials{S},'ResponseType') == 1) = false;
%     TempBeh(or(destruct(Trials{S},'ResponseType') == 2,destruct(Trials{S},'ResponseType') == 3)) = true;
    TempBeh(destruct(Trials{S},'ResponseType') == 2) = true;
    
    TrigOn = destruct(Trials{S},'Trigger.Delay.Frame');
    TrigOff = destruct(Trials{S},'Trigger.Stimulus.Frame');
    
    TaskActivity = squeeze(nanmean(wind_roi(TaskTrace,{TrigOn;TrigOff},'Window',frame([0 3200],FPS)),2));
    CueActivity = squeeze(nanmean(wind_roi(CueTrace,{TrigOn;TrigOff},'Window',frame([0 3200],FPS)),2));
    
    IsNaN = or(isnan(TaskActivity),isnan(CueActivity));
    %     TempCorr = corrcoef(TaskActivity(~IsNaN),CueActivity(~IsNaN).* sign(Trials{S}(1).DB));
    TempCorr1 = corrcoef(TaskActivity(and(~IsNaN,TempBeh==0)),CueActivity(and(~IsNaN,TempBeh==0)).* sign(Trials{S}(1).DB));
    TempCorr2 = corrcoef(TaskActivity(and(~IsNaN,TempBeh==1)),CueActivity(and(~IsNaN,TempBeh==1)).* sign(Trials{S}(1).DB));
    ScoreCorr(S,1) = TempCorr1(2);
    try
        ScoreCorr(S,2) = TempCorr2(2);
    catch
        ScoreCorr(S,2) = 0;
    end
    CueActivity = CueActivity .* sign(Trials{S}(1).DB);
    %% example plot
    %     figure;Colours;
    %     scatter(TaskActivity(TempBeh==0),CueActivity(TempBeh==0),8,'MarkerFaceColor',Black,'MarkerEdgeColor',Black);
    %     hold on;
    %     scatter(TaskActivity(TempBeh==1),CueActivity(TempBeh==1),8,'MarkerFaceColor',Red,'MarkerEdgeColor',Red);
    %     axis([min(cat(1,TaskActivity,CueActivity)) max(cat(1,TaskActivity,CueActivity))...
    %         min(cat(1,TaskActivity,CueActivity)) max(cat(1,TaskActivity,CueActivity))]);
    %     Ax = gca;
    %     xlabel('CDTASK activity');
    %     ylabel('CDCUE activity');
    %     Ax.XTick = [-5 0 20];
    %     Ax.YTick = [-5 0 20];
    %     axis square
    %% decode cues from high and low task activity
    % correct cueactivity in two taskactivity categories
    for B = 1:2
        TempActivities = [CueActivity(TempBeh==B-1) TaskActivity(TempBeh==B-1)]';
        PoolCorrectTask{B} = cat(2,PoolCorrectTask{B},TempActivities(1,TempActivities(2,:) >= 0) > 0);
        PoolIncorrectTask{B} = cat(2,PoolIncorrectTask{B},TempActivities(1,TempActivities(2,:) < 0) > 0);
    end
    
    %     CorrectClass = CueActivity(destruct(CueTrials,'Block')==1) > 0;
    %     HighCue = CueActivity(TaskActivity>=prctile(TaskActivity,50));
    %
    %     TempCrossLickClass(:,I) = ( (nansum(double(TempLickScores(:,I) < 0) .* double(OfInterestLick-1)) ./ nansum(OfInterestLick==2)) + ...
    %         ((nansum(double(TempLickScores(:,I) >= 0) .* double(1 - (OfInterestLick-1))) ./ nansum(OfInterestLick==1))) ) ./2;
    %
    %     TempCrossCuelass(:,I) = ( (nansum(double(TempCueScores(:,I) < 0) .* double(OfInterestCue-1)) ./ nansum(OfInterestCue==2)) + ...
    %         ((nansum(double(TempCueScores(:,I) >= 0) .* double(1 - (OfInterestCue-1))) ./ nansum(OfInterestCue==1))) ) ./2;
    
end

%% plot decoding
figure;Colours;
subplot(2,2,[1 3])
for B = 2:-1:1
    Colour = swap({Black;Red},B);
    
    [MIncorrect, CIIncorrect] = binofit(sum(PoolIncorrectTask{B}),length(PoolIncorrectTask{B}));
    [MCorrect, CICorrect] = binofit(sum(PoolCorrectTask{B}),length(PoolCorrectTask{B}));
    errorbar([1 2],[MIncorrect MCorrect],[MIncorrect-CIIncorrect(1) MCorrect-CICorrect(1)],[MIncorrect-CIIncorrect(2) MCorrect-CICorrect(2)],...
        'color',Colour,'LineWidth',2,'LineStyle','none');
    hold on;
    plot([MIncorrect MCorrect],'color',Colour,'LineWidth',2,'Marker','o','MarkerFaceColor',White,'LineStyle',swap({'-';':'},B));
    
    [~,P] = fishertest([[sum(PoolIncorrectTask{B}), length(PoolIncorrectTask{B}) - sum(PoolIncorrectTask{B})];...
        [sum(PoolCorrectTask{B}), length(PoolCorrectTask{B}) - sum(PoolCorrectTask{B})] ]);

    text(1,0.6+((B==2).*0.05),num2str(P),'color',swap({Black;Red},B))
end

axis([0.75 2.25 0.5 1]);
Ax = gca;
Ax.XTick = [1 2];
Ax.XTickLabel = {'Incorrect task classification trials';'Correct task classification trials'};
Ax.YTick = [0.5 1];
ylabel('Cue classification accuracy');
%
subplot(2,2,[2])

for B = 2:-1:1
    Colour = swap({Black;Red},B);
    
    for X = 1:3
        if X == 1
            [Mu, CI] = normfit(BasisCorr);
        elseif X == 2
            [Mu, CI] = normfit(TraceCorr);
        elseif X == 3
            [Mu, CI] = normfit(ScoreCorr(:,B));
        end
        

            errorbar([X],Mu,CI,...
                'color',Colour,'LineWidth',2,'LineStyle','none','color',Colour,'LineWidth',2,'Marker','o','MarkerFaceColor',White);
                hold on

    end
    %     hold on;
    %     plot([MIncorrect MCorrect],'color',Colour,'LineWidth',2,'Marker','o','MarkerFaceColor',White,'LineStyle',swap({'-';':'},B));
    %
end

axis([0.75 3.25 -0.2 1]);
Ax = gca;
Ax.XTick = [1 2 3];
Ax.XTickLabel = {'Basis R';'Projection R';'Score R'};
Ax.YTick = [-0.2 0 Mu 1];
ylabel('CD correlation');

% 

subplot(2,2,[4])

for B = 2:-1:1
    Colour = swap({Black;Red},B);
    
    for X = 1:3
        if X == 1
            plot(zeros(length(TraceCorr),1)+1,BasisCorr,'MarkerFaceColor',White,'LineStyle','none','Marker','o','LineWidth',1.3,'color',Black)
            hold on;
            plot([X-0.125 X+0.125],[nanmedian(BasisCorr) nanmedian(BasisCorr)],'LineWidth',2,'color',Black)
        elseif X == 2
            plot(zeros(length(TraceCorr),1)+2,TraceCorr,'MarkerFaceColor',White,'LineStyle','none','Marker','o','LineWidth',1.3,'color',Black)
            plot([X-0.125 X+0.125],[nanmedian(TraceCorr) nanmedian(TraceCorr)],'LineWidth',2,'color',Black)
            [Mu, CI] = normfit(TraceCorr);
            text(1,0.8,strcat(num2str(Mu),'+/-',num2str(CI)));
            P = signrank(TraceCorr);
            text(1,0.7,num2str(P));
        elseif X == 3
            plot(zeros(length(TraceCorr),1)+3,ScoreCorr,'MarkerFaceColor',White,'LineStyle','none','Marker','o','LineWidth',1.3,'color',Black)
            plot([X-0.125 X+0.125],[nanmedian(ScoreCorr(:)) nanmedian(ScoreCorr(:))],'LineWidth',2,'color',Black)
            
        end
        

        hold on

    end
    %     hold on;
    %     plot([MIncorrect MCorrect],'color',Colour,'LineWidth',2,'Marker','o','MarkerFaceColor',White,'LineStyle',swap({'-';':'},B));
    %
end

axis([0.75 3.25 -0.2 1]);
Ax = gca;
Ax.XTick = [1 2 3];
Ax.XTickLabel = {'Basis R';'Projection R';'Score R'};
Ax.YTick = [-0.2 0 Mu 1];
ylabel('CD correlation');
