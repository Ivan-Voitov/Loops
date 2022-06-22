function [Out] = rotation(Index,varargin)
%% Parameters
Iterate = 10;
Ts = [0 600 1200 1800 2400 3200];

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% have plot data or not
if exist('Out','var')
    AvgAngle = Out{1};
    CI = Out{2};
    AvgCrossClass = Out{3};
else
    %% extract
    [DFFs,Trials{2}] = rip(Index,'DeNaN','S','NoStimulusResponsive','Active','Context');
    [~,Trials{1}] = rip(Index,'DeNaN','S','NoStimulusResponsive','Active','Super','Beh');
    
    %% get vectors for angle calculation, means
    for I = 1:Iterate
        for CD = 1:2
            while 1
                try
                    clearvars TempTrials
                    for S = 1:length(Index)
                        Selection = randperm(length(Trials{CD}{S}));
                        TempTrials{S,1} = Trials{CD}{S}(Selection(1:round(length(Selection)./2)));
                        TempTrials{S,2} = Trials{CD}{S}(Selection(round(length(Selection)./2):end));
                    end
                    for T = 1:length(Ts)-1
                        for Half = 1:2
                            % mean difference for vectors
                            [TempOut] = encode({DFFs;TempTrials(:,Half)},'Model','Means','Folds',-1,'CCD',CD-1,'Window',[0 Ts(T+1)],'Lag',Ts(T),'Equate',false,'Iterate',1);
                            Bases{CD,T,I,Half} = TempOut{1};
                            Classes{CD,T,I,Half} = TempOut{3};
                        end
                    end
                catch
                    X = 1;
                    break
                end
            end
        end
    end
    
    % calculate angles
    for I = 1:Iterate
        for CD = 1:2
            for C = 1:length(Ts)-1
                for R = 1:length(Ts)-1
                    if ~(isempty(Bases{CD,R,I,1}) || isempty(Bases{CD,C,I,1}) ...
                            || isempty(Bases{CD,R,I,2}) || isempty(Bases{CD,C,I,2}) )
                        for S = 1:length(Index)
                            NaNSession = or(or(isnan(Bases{CD,C,I,1}{S}) , isnan(Bases{CD,C,I,2}{S})), ...
                                or(isnan(Bases{CD,R,I,1}{S})  , isnan(Bases{CD,R,I,2}{S})));
                            % calculate angle
                            Vect1 = Bases{CD,C,I,1}{S}([false; ~NaNSession(2:end)]);
                            Vect2 = Bases{CD,R,I,2}{S}([false; ~NaNSession(2:end)]);
                            % the angle equation for cosine angle
                            TempAngle(S) = dot(Vect1,Vect2)/(norm(Vect1)*norm(Vect2));
                            TempTempTemp = corrcoef(Vect1,Vect2);
                            TempCorr(S) = TempTempTemp(2,1);
                        end
                        Angle(CD,C,R,I) = nanmean(TempAngle);
                        Corr(CD,C,R,I) = nanmean(TempCorr);
                        AngleForCI(CD,C,R,I,:) = TempAngle;
                        CorrForCI(CD,C,R,I,:) = TempCorr;
                    else
                        Angle(CD,C,R,I) = nan;
                        Corr(CD,C,R,I) = nan;
                        AngleForCI(CD,C,R,I,:) = nan(length(Index),1);
                        CorrForCI(CD,C,R,I,:) = nan(length(Index),1);
                    end
                end
            end
        end
    end
    
    %% full cross class (LDA)
    for CD = 1:2
        for C = 1:length(Ts)-1 % the test
            for R = 1:length(Ts)-1 % the model
                [TempOut] = encode({DFFs;Trials{CD}'},'Model','LDA','Folds',-1,'CCD',CD-1,...
                    'Window',[0 Ts(R+1)],'Lag',Ts(R),'Equate',false,'Iterate',1,...
                    'MultiValue',{[0 Ts(C+1)];Ts(C)});
                CrossClass(CD,C,R) = nanmean(TempOut{3});
                CrossClassForCI(CD,C,R,:) = TempOut{3};
            end
        end
    end
    
    %% average and ci and sig the results
    for CD = 1:2
        for C = 1:length(Ts)-1
            for R = 1:length(Ts)-1
                % NEED TO LINEARALIZE AND CAT S'S AND I'S AND THEN CI
                % PROPERLY
                % angle
                PD = fitdist(squeeze(Angle(CD,C,R,~isnan(Angle(CD,C,R,:)))),'Normal');
                TempCI = paramci(PD);
                AngleCI(CD,C,R,:) = [TempCI(1,1) TempCI(2,1)];
                AvgAngle(CD,C,R) = PD.mu;
                
                % cor
                PD = fitdist(squeeze(Corr(CD,C,R,~isnan(Corr(CD,C,R,:)))),'Normal');
                TempCI = paramci(PD);
                CorrCI(CD,C,R,:) = [TempCI(1,1) TempCI(2,1)];
                AvgCorr(CD,C,R) = PD.mu;
                
                % cross class
                
            end
        end
    end
end

%% plot
ToPlot = {squeeze(AvgAngle(1,:,:));squeeze(AvgAngle(2,:,:));...
    squeeze(AvgCorr(1,:,:));squeeze(AvgCorr(2,:,:));...
    squeeze(CrossClass(1,:,:));squeeze(CrossClass(2,:,:))};
Titles = {'Subspace angle';'Subspace correlation';'Cross-temporal classification'};
Scales = {[0 0.7];[0 0.7];[0.5 1]};
for Plot = 1:6
    figure;imagesc(ToPlot{Plot},Scales{ceil(Plot./2)});
    axis square
    title(Titles{ceil(Plot/2)});
    Ax = gca;
    Ax.XTick = [];
    Ax.YTick = [];
    
    if Plot <5
        xlabel('Subspace from random 1/2 of trials (600 ms bins)');
        ylabel('Subspace from remaining 1/2 of trials (600 ms bins)');
    elseif Plot >=5
        xlabel('Training window (600 ms bins)');
        ylabel('Testing window (600 ms bins)');
    end
    CB = colorbar;
    CB.Ticks = [CB.Limits(1):0.1:CB.Limits(2)];
end

Out{1} = ToPlot;
Out{2} = ToPlot;

% figure;imagesc(squeeze(AvgAngle(1,:,:)),[0 0.7]); colorbar; axis square
% figure;imagesc(squeeze(AvgAngle(2,:,:)),[0 0.7]); colorbar; axis square
% figure;imagesc(squeeze(AvgCorr(1,:,:)),[0 0.7]); colorbar; axis square
% figure;imagesc(squeeze(AvgCorr(2,:,:)),[0 0.7]); colorbar; axis square
% figure;imagesc(squeeze(CrossClass(1,:,:)),[0.5 1]); colorbar; axis square
% figure;imagesc(squeeze(CrossClass(2,:,:)),[0.5 1]); colorbar; axis square

% figure;Colours;
% for CD = 1:2
%     subplot(1,2,CD);
%     errorbar([1:length(Ts)-1],AvgAngle(CD,:,1),AvgAngle(CD,:,1) - CI(CD,:,1,1),AvgAngle(CD,:,1) - CI(CD,:,1,2),'LineWidth',1,'color',Grey,'Marker','o','MarkerFaceColor',Grey,'MarkerSize',5);
%     hold on;
%     errorbar([1:length(Ts)-1],AvgAngle(CD,:,2),AvgAngle(CD,:,2) - CI(CD,:,2,1),AvgAngle(CD,:,2) - CI(CD,:,2,2),'LineWidth',1.5,'color',Black,'Marker','o','MarkerFaceColor',Black,'MarkerSize',5);
%     Ax = gca;
%     Ax.XTick = [1:length(Ts)-2];
%     Ax.XLim = [0.5 length(Ts)-2 + 0.5];
%     Ax.YLim = [0 0.25];
%     Ax.YTick = [];
%
% end