function romo_identifier(Index,varargin)
FPS = 4.68;


%% PASS CONTROL
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% rip
[DFFs,Trials] = rip(Index,'S','Context','DeNaN','Active','Focus','StimulusResponsive');

%% what are the delay responses of stimulus responsive cells?
Traces = (avg_triggered(DFFs,Trials,1,'Window',[-1800 2000],'FPS',FPS))';
figure; Colours;
line([9 9],...
    [0 1.5],'color','k','LineWidth',2);

[~,IDs] = sort(nanmean(Traces(12:17,:),1),'descend');
Romo = zeros(size(Traces,2),1); Romo(IDs(1:4)) = true;
hold on;
Z = 1; Colour = {Purple;Silver.*0.7;Metal;Brown./0.8};
for Cell = 1:size(Traces,2)
    P = plot(Traces(:,Cell),'Color',Black,'LineWidth',1);
    P.Color = cat(2,Black,0.15);
end

for Cell = 1:size(Traces,2)
    if Romo(Cell)
        plot(Traces(:,Cell),'Color',Colour{Z},'LineWidth',1.5);
        Z = Z + 1;
    end
end
plot(nanmean(Traces,2),'color',Black','LineWidth',5);
Ax = gca;
Ax.XTick = [1 9 18];
Ax.XLim = [1 18];
Ax.XTickLabel = {'-2000 ms';'0 ms';'+2000 ms'};
Ax.YTick = [0 1.5];
Ax.YLim = [0 1.5];
axis square

%% what are the cue encoding of these cells?
SessionCells = cellfun(@(x) size(x,1),DFFs);
S = 1; Carry = 0;
for C = 1:size(Traces,2)
    if C > (SessionCells(S) + Carry)
        Carry = Carry + SessionCells(S);
        S = S + 1;
    end
    Sessions(C) = S;
    if Romo(C)
        Romo(C) = C - sum(SessionCells(1:S-1));
    end
end

figure; Z = 1; Colour = {Green;Orange};
for Cell = 1:size(Traces,2)
    if Romo(Cell)
        subplot(2,2,Z);
        line([9 9],...
            [0 1.5],'color','k','LineWidth',2);
        hold on;
        for Cue = 1:2
            TempTrial = Trials{Sessions(Cell)}(destruct(Trials{Sessions(Cell)},'Block')==Cue-1);
            TrigPre =  destruct(TempTrial,strcat('Trigger.Pre.Frame')) + 3;
            TrigOn = destruct(TempTrial,strcat('Trigger.Delay.Frame'))+1;
            TrigOff = destruct(TempTrial,strcat('Trigger.Stimulus.Frame'));
            TempTrace = wind_roi(DFFs{Sessions(Cell)}(Romo(Cell),:),{TrigPre;TrigOn;TrigOff},'Window',frame([-1800 2000],FPS));
            for II = 1:size(TempTrace,2)
                PD = fitdist(squeeze(TempTrace(1,II,:)),'Normal');
                TempCI = paramci(PD);
                CIs(II,:) = [TempCI(2,1) TempCI(1,1)];
            end
            patches([],CIs,[1:size(TempTrace,2)],'Colour',Colour{Cue});
            plot(nanmean(TempTrace,3),'color',Colour{Cue},'LineWidth',2);
        end
        Ax = gca;
        Ax.XTick = [1 9 18];
        Ax.XLim = [1 18];
        Ax.XTickLabel = {'-2000 ms';'0 ms';'+2000 ms'};
        Ax.YTick = [0 1.5];
        Ax.YLim = [0 1.5];
        axis square
        Z = Z + 1;
        
    end
end
