function [BehRecovery] = recoveringness2(Trial,NeuralRecovery,varargin)
Window = 1600;
Pool = 'All';
IndexType = 1;

for I = 1:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

%% fill in the behavioural data
if isstruct(Trial) || iscell(Trial) % not sped up
    % do reso as well?
    if iscell(Trial)
        for Area = 1:2
            TempTrial{1} = selector(Trial{Area+1},'Post','NoReset','NoLight');
            TempTrial{2} = selector(Trial{Area+1},'Post','NoReset','Light');
            for LightStatus = 1:2
                TimeBin = (destruct(TempTrial{LightStatus},'Trigger.Stimulus.Time')>Window)+1;
                if ~strcmp(Pool,'All')
                    % get session/mouse and time vectors
                    [PoolName] = get_pool_names(TempTrial{LightStatus},Pool);
                    
                    % get stats
                    for Time = 1:2
                        for P = 1:length(unique(PoolName))
                            Responses = destruct(TempTrial{LightStatus}(and(PoolName==P,(TimeBin == Time)')),'ResponseType');
                            BehRecovery{Area}(Time,LightStatus,P) = sum(or(Responses == 1,Responses==4)) ./ length(Responses);
                        end
                    end
                    NumPooled(Area) = size(BehRecovery{Area},3);
                elseif strcmp(Pool,'All')
                    for Time = 1:2
                        Responses = destruct(TempTrial{LightStatus}(TimeBin == Time),'ResponseType');
                        BehRecovery{Area}{Time,LightStatus} = or(Responses == 1,Responses==4);
                    end
                end
            end
        end
        
        % remove the raw data
        Trial = Trial{1};
        
    else
        NumPooled(1) = 0; NumPooled(2) = 0;
    end
    
    TempTrial{1} = selector(Trial,'Post','NoReset','NoLight');
    for Area = 1:2
        TempTrial{2} = selector(Trial,'Post','NoReset',swaparoo({'M2';'AM'},Area),'EarlyDelayOnset','Light');
        for LightStatus = 1:2
            TimeBin = (destruct(TempTrial{LightStatus},'Trigger.Stimulus.Time')>Window)+1;
            if ~strcmp(Pool,'All')
                [PoolName] = get_pool_names(TempTrial{LightStatus},Pool);
                
                for Time = 1:2
                    for P = 1:length(unique(PoolName))
                        Responses = destruct(TempTrial{LightStatus}(and(PoolName==P,(TimeBin == Time)')),'ResponseType');
                        BehRecovery{Area}(Time,LightStatus,P+NumPooled(Area)) = sum(or(Responses == 1,Responses==4)) ./ length(Responses);
                    end
                end
            elseif strcmp(Pool,'All')
                for Time = 1:2
                    Responses = destruct(TempTrial{LightStatus}(TimeBin == Time),'ResponseType');
                    try
                        BehRecovery{Area}{Time,LightStatus} =  cat(1,BehRecovery{Area}{Time,LightStatus}, or(Responses == 1,Responses==4));
                    catch
                        BehRecovery{Area}{Time,LightStatus} =  or(Responses == 1,Responses==4);
                    end
                end
            end
        end
    end
else
    BehRecovery = Trial; % vecotr for speed
end

% early/late Off/on Disc/mem sessions
% for A = 1:2
% BehRecovery{A} = nanmean(BehRecovery{A},4)
% NeuralRecovery{A} = nanmean(NeuralRecovery{A},4)
% end

%% get indices and statistics
for Area = 1:2
    if IndexType == 1
        NeuralIndex{Area} = squeeze((NeuralRecovery{Area}(1,1,:) - NeuralRecovery{Area}(1,2,:)) - (NeuralRecovery{Area}(2,1,:) - NeuralRecovery{Area}(2,2,:)));
    elseif IndexType == 2
        NeuralIndex{Area} = squeeze((NeuralRecovery{Area}(2,1,:) - NeuralRecovery{Area}(2,2,:)) ./ (NeuralRecovery{Area}(1,1,:) - NeuralRecovery{Area}(1,2,:)));
    end
    [NeuralPoint(3-Area),~,NeuralCI(3-Area,:)] = normfit(NeuralIndex{Area}(~isnan(NeuralIndex{Area})));
    
    if ~strcmp(Pool,'All')
        if IndexType == 1
            BehaviouralIndex{Area} = squeeze((BehRecovery{Area}(1,1,:) - BehRecovery{Area}(1,2,:)) - (BehRecovery{Area}(2,1,:) - BehRecovery{Area}(2,2,:)));
        elseif IndexType == 2
            BehaviouralIndex{Area} = squeeze((BehRecovery{Area}(1,1,:) - BehRecovery{Area}(1,2,:)) ./ (BehRecovery{Area}(2,1,:) - BehRecovery{Area}(2,2,:)));
        end
        BehaviouralIndex{Area}(isinf(BehaviouralIndex{Area})) = nan;
        [BehaviouralPoint(Area),~,BehaviouralCI(Area,:)] = normfit(BehaviouralIndex{Area}(~isnan(BehaviouralIndex{Area})));
    else
        if IndexType == 1
            BehaviouralPoint(Area) = squeeze((nanmean(BehRecovery{Area}{1,1}) - nanmean(BehRecovery{Area}{1,2})) - (nanmean(BehRecovery{Area}{2,1}) - nanmean(BehRecovery{Area}{2,2})));
        elseif IndexType == 2
            BehaviouralPoint(Area) = squeeze((nanmean(BehRecovery{Area}{1,1}) ./ nanmean(BehRecovery{Area}{1,2})) - (nanmean(BehRecovery{Area}{2,1}) - nanmean(BehRecovery{Area}{2,2})));
        end
        TempTemp = cat(1,BehRecovery{Area}{1,1},BehRecovery{Area}{1,2},BehRecovery{Area}{2,1},BehRecovery{Area}{2,2});
        Temp = nanmean(TempTemp);
        TempTempTemp = (((Temp * (1-Temp)./length(TempTemp))).^0.5)* 1.96;
        BehaviouralCI(Area,:) =   [BehaviouralPoint(Area) - TempTempTemp   BehaviouralPoint(Area)+TempTempTemp];
    end
end

%% plot behaviour
figure; Colours; Colour = {Black;Red};
for Area = 1:2
    subplot(1,2,Area)
    
    if  ~strcmp(Pool,'All')
        IsNotNaN = and(~isnan(BehRecovery{3-Area}(1,1,:)),~isnan(BehRecovery{3-Area}(1,2,:)));
        IsNotNaN = and(IsNotNaN,and(~isnan(BehRecovery{3-Area}(2,1,:)),~isnan(BehRecovery{3-Area}(2,2,:))));
        for Light = 1:2
            [M1(Light),~,CI1] = normfit(squeeze(BehRecovery{3-Area}(1,Light,IsNotNaN)));
            [M2(Light),~,CI2] = normfit(squeeze(BehRecovery{3-Area}(2,Light,IsNotNaN)));
            errorbar([1 2],[M1(Light) M2(Light)], [M1(Light)-CI1(2) M2(Light)-CI2(2)],[M1(Light)-CI1(1) M2(Light)-CI2(1)],'color',Colour{Light},...
                'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Colour{Light},'LineWidth',1);
            hold on;
        end
        % test is not sign rank!
        P1 = ranksum(squeeze(BehRecovery{3-Area}(1,1,IsNotNaN)),squeeze(BehRecovery{3-Area}(1,2,IsNotNaN)));
        P2 = ranksum(squeeze(BehRecovery{3-Area}(2,1,IsNotNaN)),squeeze(BehRecovery{3-Area}(2,2,IsNotNaN)));
        text(1,M1(1) + 0.05,decell(strcat({'p = '},num2str(P1))))
        text(2,M2(1) + 0.05,decell(strcat({'p = '},num2str(P2))))
    else
        for Light = 1:2
            [M1(Light),CI1] = binofit(sum(BehRecovery{3-Area}{1,Light}),length(BehRecovery{3-Area}{1,Light}));
            [M2(Light),CI2] = binofit(sum(BehRecovery{3-Area}{2,Light}),length(BehRecovery{3-Area}{2,Light}));
            errorbar([1 2],[M1(Light) M2(Light)], [M1(Light)-CI1(2) M2(Light)-CI2(2)],[M1(Light)-CI1(1) M2(Light)-CI2(1)],'color',Colour{Light},...
                'Marker','o','MarkerFaceColor',White,'MarkerEdgeColor',Colour{Light},'LineWidth',1);
            hold on;
        end
        
        [~,P1] = fishertest([sum(squeeze(BehRecovery{3-Area}{1,1})),sum(squeeze(BehRecovery{3-Area}{1,2})) ;sum(squeeze(BehRecovery{3-Area}{1,1})==0),sum(squeeze(BehRecovery{3-Area}{1,2})==0)]);
        [~,P2] = fishertest([sum(squeeze(BehRecovery{3-Area}{2,1})),sum(squeeze(BehRecovery{3-Area}{2,2})) ;sum(squeeze(BehRecovery{3-Area}{2,1})==0),sum(squeeze(BehRecovery{3-Area}{2,2})==0)]);
        text(1,M1(1) + 0.05,decell(strcat({'p = '},num2str(P1))))
        text(2,M2(1) + 0.05,decell(strcat({'p = '},num2str(P2))))
    end
    axis([0.75 2.25 0.5 1])
    Ax= gca;
    Ax.XTick = [1 2];
    Ax.XTickLabels = {'Early delay';'Late delay'};
    Ax.YTick = [0.5 1];
    Ax.YTickLabels = {'50%';'100%'};
end

% EXCLUDES (sum(2-IsNotNaN)) SESSIONS !!!


%% plot main
figure;
Colours;
Marker = {'o','d'};
for Area = 1:2
    plot(squeeze(NeuralCI(Area,:)),[BehaviouralPoint(Area) BehaviouralPoint(Area)],'color',Black,'LineWidth',2);
    hold on
    plot([NeuralPoint(Area) NeuralPoint(Area)],squeeze(BehaviouralCI(Area,:)),'color',Black,'LineWidth',2);
    plot(NeuralPoint(Area),BehaviouralPoint(Area),'Marker',Marker{Area},'color',Black,'MarkerSize',15,'MarkerFaceColor',White,'LineWidth',2);
    hold on
end

xlabel('Neural robustness')
ylabel('Behavioural robustness')
axis([-0.2 0.2 -0.2 0.2])
axis tight
axis square
Ax = gca;
try
    Ax.XTick = [Ax.XLim(1) 0  Ax.XLim(2)];
    Ax.YTick = [Ax.YLim(1) 0  Ax.YLim(2)];
catch
    Ax.XTick = [Ax.XLim(1)  Ax.XLim(2)];
    Ax.YTick = [Ax.YLim(1) Ax.YLim(2)];
end
% legend({'M2 Discrimination';'M2 ';'';''})

%%
function [PoolName] = get_pool_names(Trial,Pool)

% get session/mouse and time vectors
for I = 1:length(Trial)
    if strcmp(Pool,'Mice')
        try
            PoolNames{I} = Trial(I).Mouse;%find(strcmp(Trial(I).Mouse,PoolNames));
        catch
            PoolNames{I} =Trial(I).MouseName;% find(strcmp(Trial(I).MouseName,PoolNames));
        end
    elseif strcmp(Pool,'Sessions')
        try
            PoolNames(I) = Trial(I).SessionNumber;
        catch
            PoolNames{I} = Trial(I).FileName;
        end
    end
end

PoolNames = unique(PoolNames);
clearvars PoolName
for I = 1:length(Trial)
    if strcmp(Pool,'Mice')
        try
            PoolName(I) = find(strcmp(Trial(I).Mouse,PoolNames));
        catch
            PoolName(I) = find(strcmp(Trial(I).MouseName,PoolNames));
        end
    else
        try
            PoolName(I) = find(Trial(I).SessionNumber==PoolNames);
        catch
            PoolName(I) = find(strcmp(Trial(I).FileName,PoolNames));
        end
    end
end