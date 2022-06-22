function [Rs,Slopes] = dynamics_scatter(Index,varargin)
%% READY
FPS = 4.68;
HalfWindow = 1600;
Light = false;
LimitBound = 1600;
Equate = false;

Normalize = true;
UseNormalizers = false;
Focus = false;

Fit = false;

CCD = false;
DCD = false;
CueTrace = false;

CrossOldStyle = false;
Cross = false;

Sub = false;

PlotOut = true;
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

rng(10);
%% SET
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
    if ~CCD && ~DCD
        [TempTraces,TempTrials] = rip(Index,swap({'Super';'DistractorCue'},Cross+1),'DeNaN',swap({'Trace';'CueTrace'},Cross+1));
    elseif DCD
        [TempTraces,TempTrials] = rip(Index,'AllTrials','DeNaN',swap({'DistractorTrace';'CueTrace'},CueTrace +1));
    else
        [TempTraces,TempTrials] = rip(Index,swap({'Context';'Cross'},CrossOldStyle+1),'DeNaN','CueTrace');
    end
    if ~Light
        Traces = {TempTraces};
        Trials = {TempTrials};
    end
end

%% extract
for Context = 1:2-CCD+CrossOldStyle % -_-
    for Condition = 1:length(Traces)
        Short{Condition,Context} = [];
        Long{Condition,Context} = [];
        for S = 1:length(Traces{1})
            Trial = Trials{Condition}{S}(destruct(Trials{Condition}{S},'Trigger.Stimulus.Time')>=LimitBound);
            
            if Normalize
                if Focus
                    % tricky... do in such a manner that effectively focusing
                    % on the right trials. and don't do mean substract! because
                    % that biases things.
                    Frames = [];
                    for III = 1:length(Trial)
                        Frames = cat(1,Frames,[Trial(III).Trigger.Delay.Frame:Trial(III).Trigger.Post.Frame]');
                    end
                    TempFocus = false(size(Traces{Condition}{S},2),1);
                    TempFocus(Frames(~isnan(Frames))) = true;
                    Trace = (Traces{Condition}{S} - nanmean(Traces{Condition}{S}(TempFocus)))./  nanstd(Traces{Condition}{S}(TempFocus));
                else
                    % old style if Traces are not filled in a priori (no need
                    % to focus)
                    if ~UseNormalizers
                        Trace = (Traces{Condition}{S} - nanmean(Traces{Condition}{S})) ./ std(Traces{Condition}{S},'omitnan');
                    elseif ~Cross && ~CCD
                        Trace = (Traces{Condition}{S} - Index(S).CueNormalizers(1)) ./ Index(S).CueNormalizers(2);
                    else
                        Trace = (Traces{Condition}{S} - Index(S).TaskNormalizers(1)) ./ Index(S).TaskNormalizers(2);
                    end
                end
            else
                Trace = Traces{Condition}{S};
            end
            
            if Context == 2 && ~DCD% && ~CCD
                Trace = -Trace;
            end
            
            
            if ~CCD
                NumD = sum(destruct(Trial,'Task')==2);
                NumM = sum(destruct(Trial,'Task')==1);
                Trial = Trial(destruct(Trial,'Task')==(3-Context));
                if Equate && length(Trial) > min(NumD,NumM)
                    Trial = Trial(randperm(length(Trial)));
                    Trial = Trial(1:min(NumD,NumM));
                end
            end
            
%             if Cross
%                 DB(S) = round(mean(destruct(Trial(destruct(Trial,'Task')==1),'DB') == -15));
%                 Trial = Trial(destruct(Trial,'Task')==(Context));
%                 if Context == 1 % WM task only take out the central cue
%                     Trial = Trial(destruct(Trial,'Block')==DB(S));
%                 end
%             end
            
            if ~isempty(Trial)
                TrigOn = destruct(Trial,'Trigger.Delay.Frame');
                TrigOff = destruct(Trial,'Trigger.Stimulus.Frame');
                [Activities] = wind_roi(-Trace,{TrigOn;TrigOff},'Window',frame([0 3200],FPS));
                if CCD %&& ~Cross % flip one of the cues
                    Activities(:,:,destruct(Trial,'Block')==1) = -Activities(:,:,destruct(Trial,'Block')==1);
                    %                     Activities(:,:,destruct(Trial,'Block')==0) = [];
                elseif DCD && CueTrace
                    if Context == 1 % distractor
                        Activities(:,:,destruct(Trial,'DB')==15) = -Activities(:,:,destruct(Trial,'DB')==15);
                    else % cue
                        Activities(:,:,destruct(Trial,'Block')==1) = -Activities(:,:,destruct(Trial,'Block')==1);
                    end
                elseif Cross 
                    if Context == 2
                        if Trial(find(destruct(Trial,'Task')==1,1)).DB ~= -15
                        % the matched cue is not always up in CCD space
                            Activities =-Activities;
                        end
                    elseif Context == 1
                        TempDB =Trial(find(destruct(Trial,'Task')==2,1)).DB;
                        Activities(:,:,destruct(Trial,'DB')~=TempDB) = -Activities(:,:,destruct(Trial,'DB')~=TempDB);
                    end
                end
           end
            
            %             Fits = fitlm([1:size(Activities,2)-1]', squeeze(nanmean(Activities(1,2:end,:),3)));
            %             Fits = fitlm([1:size(Activities,2)-1]', squeeze(Activities(1,2:end,:)));
            
            TempShort = squeeze(nanmean(Activities(1,1:frame(HalfWindow,FPS),:),2));
            TempLong = squeeze(nanmean(Activities(1,frame(HalfWindow,FPS):end,:),2));
            TempShort(isnan(TempLong)) = [];
            TempLong(isnan(TempLong)) = [];
            TempLong(isnan(TempShort)) = [];
            TempShort(isnan(TempShort)) = [];
            
            Short{Condition,Context} = cat(1,Short{Condition,Context},TempShort);
            Long{Condition,Context} = cat(1,Long{Condition,Context},TempLong);
            try
                Fits{Condition,Context}{S} = fitlm(TempShort,TempLong);
            end
        end
        %             Short{Condition,Context}(isnan(Long{Condition,Context})) = [];
        %             Long{Condition,Context}(isnan(Long{Condition,Context})) = [];
        %             Long{Condition,Context}(isnan(Short{Condition,Context})) = [];
        %             Short{Condition,Context}(isnan(Short{Condition,Context})) = [];
    end
end

%% Type 1 plot
if PlotOut
    Colours;
%     if Cross
%         Red = Orange;
%     end
    if DCD
        Red = Black;
    end
    Colour = {Blue;Red};
    for Condition = 1:length(Traces)
        if ~Sub
            figure;
        end
        line([-1.6 3],[-1.6 3],'LineWidth',2,'color',Grey); hold on;
        axis ([-1.6 3 -1.6 3])
        for Context = 1:2-CCD+CrossOldStyle
            %         scatter(Short{Condition,Task},Long{Condition,Task},'Marker','o','SizeData',30,'MarkerEdgeColor','none','MarkerFaceColor',Colour{Task},'MarkerFaceAlpha',0.3);
            try
                [M{Context}] = fitlm(Short{Condition,Context},Long{Condition,Context});
                
                MP = plot(M{Context},'Marker','none','MarkerEdgeColor','none','MarkerFaceColor',swap({Colour{Context};Black},CCD+1-CrossOldStyle));
                hold on;
                MPP = scatter(Short{Condition,Context},Long{Condition,Context},10,'Marker','o','MarkerEdgeColor','none','MarkerFaceColor',swap({Colour{Context};Black},CCD+1-CrossOldStyle));
                alpha(MPP,0.2);
                %         MPP.Color = cat(2,Colour{Task},0.2);
                %         MP(1).Color = cat(2,Colour{Task},0.2);
                %         FaceAlpha = 1
                FitP=findobj(MP,'DisplayName','Fit');
                FitP.Color=swap({Colour{Context};Black},CCD+1-CrossOldStyle);
                FitP.LineWidth=2;
                for Z = 3:4
                    CIP = MP(Z);
                    CIP.LineWidth=0.75;
                    CIP.Color = swap({Colour{Context};Black},CCD+1-CrossOldStyle);
                    CIP.LineStyle ='--';
                end
                %         axis([-Zoom Zoom -Zoom Zoom]);
                
                %         text([],[],strcat({'R = '};num2str(C);{''}))
                %         text([],[],strcat({'Slope = '};num2str(C);{''}))
                %         [A] = corrcoef(Short{Condition,Task},Long{Condition,Task});
                %         Corr(Condition,Task) = A(2,1);
                
                %         Rs(Condition,Task,S+1) = M.Rsquared.Ordinary;
                %         Slopes(Condition,Task,S+1) = M.Coefficients.Estimate(2);
                %         text(1,-1-(Task*0.2),strcat('Slope signrank is ',{' '},num2str(SlopeDiff1)));
                %         text(1,-1-(Task*0.2),strcat('Slope t test is ',{' '},num2str(SlopeDiff2)));
            end
        end
        axis square
        Ax = gca;
        legend off
        title([])
        if or(~CCD,CrossOldStyle)
            Ax.XLim = [min(min(min(Short{Condition,1}),min(Short{Condition,2})),min(min(Long{Condition,1}),min(Long{Condition,2}))) ...
                max(max(max(Short{Condition,1}),max(Short{Condition,2})),max(min(Long{Condition,1}),max(Long{Condition,2}))) ];
        else
            Ax.XLim = [min(min(Short{Condition,1}),min(Long{Condition,1})) ...
                max(max(Short{Condition,1}),max(Long{Condition,1})) ];
        end
        Ax.YLim = Ax.XLim;
        Ax.XTick = [Ax.XLim(1) 0 Ax.XLim(2)];
        Ax.YTick = [Ax.YLim(1) 0 Ax.YLim(2)];
        xlabel('Coding dimension activity, first half of the delay');
        ylabel('Coding dimension activity, second half of the delay');
        
        %% statistics
        clearvars S R TempM ShuffledShort ShuffledLong
        if or(~CCD,CrossOldStyle)
            ShuffledShortFull = cat(1,Short{Condition,1},Short{Condition,2});
            ShuffledLongFull = cat(1,Long{Condition,1},Long{Condition,2});
            SizeOfTask1 = length(Short{Condition,1});
            SizeOfTask2 = length(Short{Condition,2});
            for BS = 1:1000
                ShuffleInd = randperm(length(ShuffledShortFull));
                
                ShuffledShort{1} = ShuffledShortFull(ShuffleInd(1:SizeOfTask1));
                ShuffledShort{2} = ShuffledShortFull(ShuffleInd(SizeOfTask1+1:end));
                ShuffledLong{1} = ShuffledLongFull(ShuffleInd(1:SizeOfTask1));
                ShuffledLong{2} = ShuffledLongFull(ShuffleInd(SizeOfTask1+1:end));
                
                for Context = 1:2
                    [Sample,ID] = datasample(ShuffledShort{Context},length(ShuffledShort{Context}));
                    [TempM{Context}] = fitlm(Sample,ShuffledLong{Context}(ID));
                    R{Context}(BS) = TempM{Context}.Rsquared.Ordinary;
                    S{Context}(BS) = TempM{Context}.Coefficients.Estimate(2);
                end
                
                % distribution
                RDiff(BS) = TempM{1}.Rsquared.Ordinary - TempM{2}.Rsquared.Ordinary;
                SlopeDiff(BS) = TempM{1}.Coefficients.Estimate(2) - TempM{2}.Coefficients.Estimate(2);
            end
            
            % differences
            TrueRDiff = M{1}.Rsquared.Ordinary - M{2}.Rsquared.Ordinary;
            TrueSlopeDiff = M{1}.Coefficients.Estimate(2) - M{2}.Coefficients.Estimate(2);
            [A,B]= normfit(RDiff);
            RSig = normcdf(TrueRDiff,A,B);
            [A,B]= normfit(SlopeDiff);
            SlopeSig = normcdf(TrueSlopeDiff,A,B);
            
            % CIs
            RCI(1) = nanmean(R{1}) - prctile(R{1},5);
            RCI(2) = nanmean(R{2}) - prctile(R{2},5);
            SlopeCI(1) = nanmean(S{1}) - prctile(S{1},5);
            SlopeCI(2) = nanmean(S{2}) - prctile(S{2},5);
        else
            % just CIs
            for BS = 1:1000
                ShuffledShort = Short{Condition}(randperm(length(Short{Condition})));
                ShuffledLong = Long{Condition}(randperm(length(Long{Condition})));
                [Sample,ID] = datasample(ShuffledShort,length(ShuffledShort));
                [TempM{1}] = fitlm(Sample,ShuffledLong(ID));
                R{1}(BS) = TempM{1}.Rsquared.Ordinary;
                S{1}(BS) = TempM{1}.Coefficients.Estimate(2);
            end
            RCI(1) = nanmean(R{1}) - prctile(R{1},5);
            SlopeCI(1) = nanmean(S{1}) - prctile(S{1},5);
        end
        % text
        for Context = 1:2-CCD+CrossOldStyle
            text(-1,0.5-(Context*0.2),...
                strcat('R^2 is ',{' '},num2str(M{Context}.Rsquared.Ordinary),{' +/- '},num2str(RCI(Context)))...
                ,'color',swap({Colour{Context};Black},CCD+1-CrossOldStyle));
            text(-1,1-(Context*0.2),...
                strcat('Slope is ',{' '},num2str(M{Context}.Coefficients.Estimate(2)),{' +/- '},num2str(SlopeCI(Context)))...
                ,'color',swap({Colour{Context};Black},CCD+1-CrossOldStyle));
        end
        if or(~CCD,CrossOldStyle)
            text(-1,0.5-0.6,...
                strcat({'p = '},num2str(RSig))...
                ,'color','k');
            text(-1,1-0.6,...
                strcat({'p = '},num2str(SlopeSig))...
                ,'color','k');
        end
        %     text(1,-1-0.4,strcat('Slope signrank is ',{' '},num2str(SlopeDiff1)));
        %     text(1,-1-0.2,strcat('Slope t test is ',{' '},num2str(SlopeDiff2)));
        %     text(1,-1-0,strcat('R signrank is ',{' '},num2str(RDiff)));
        
        
        
    end
else
    
    
    for Context = 1:2-CCD
        %         scatter(Short{Condition,Task},Long{Condition,Task},'Marker','o','SizeData',30,'MarkerEdgeColor','none','MarkerFaceColor',Colour{Task},'MarkerFaceAlpha',0.3);
        [M{Context}] = fitlm(Short{Condition,Context},Long{Condition,Context});
        
    end
    axis square
end
Rs = M{Context}.Rsquared.Ordinary;

%
% %% type 2 plot
% Colours;
% Colour = {Blue;Red};
% for Condition = 1:length(Traces)
% %     if ~Sub
% %         figure;
% %     end
% %     line([-1.6 3],[-1.6 3],'LineWidth',2,'color',Grey); hold on;
% %     axis ([-1.6 3 -1.6 3])
% %     for Context = 1:2-CCD
% %         for S = 1:length(Index)
% %             MP = plot(Fits{Condition,Context}{S},'Marker','none','MarkerEdgeColor','none','MarkerFaceColor',swap({Colour{Context};Black},CCD+1));
% %         end
% %     end
%
%
%     %% statistics
%     for S = 1:length(Index)
%         for Context = 1:2-CCD
%             RInd(Context,S) = Fits{Condition,Context}{S}.Rsquared.Ordinary;
%         end
%     end
%     figure;
%     plot(RInd(1,:));hold on;
%     if ~CCD
%         plot(RInd(2,:));
%         signrank(RInd(1,:),RInd(2,:))
%     end
%
% end
%
