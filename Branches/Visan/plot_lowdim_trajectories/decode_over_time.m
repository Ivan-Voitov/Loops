function decode_over_time(Statistic,Style)
Duration = size(Statistic{1,1},3);
DimNum = size(Statistic{1,1},2);
NumSessions = size(Statistic,1);


for Session = 1:NumSessions
    % what is the significance between disc memory?
    for II = 1:Duration
        %         if Style == 3; clearvars TempAvg TempShuffAvg;end
        for Dim = 1:DimNum
            clearvars TempAvg
            if Style == 1
                for Task = 1:2
                    TempAvg{Task}(:) = Statistic{Session,Task}(:,Dim,II); % all trials of task 1
                    TempAvg{Task}(isnan(TempAvg{Task})') = [];
                end
                try
                    Sig(Dim,II,Session) = ranksum(TempAvg{1},TempAvg{2});
                catch
                    Sig(Dim,II,Session) = nan;
                end
                
            elseif Style >= 2
                for Task = 1:2
                    TempAvg{Task}(:) = Statistic{Session,Task,1}(:,Dim,II); % all trials of task 1
                    TempAvg{Task}(isnan(TempAvg{Task})') = [];
                end
                Diff(Dim,II,Session) = nanmean(TempAvg{1}) - nanmean(TempAvg{2}); % mean trials M - D
                for Shuff = 2:size(Statistic,3)
                    clearvars TempShuffAvg
                    for Task = 1:2
                        TempShuffAvg{Task}(:) = Statistic{Session,Task,Shuff}(:,Dim,II); % all trials of task 1
                        TempShuffAvg{Task}(isnan(TempShuffAvg{Task})') = [];
                    end
                    TempCIDiff(Dim,II,Session,Shuff-1) = nanmean(TempShuffAvg{1}) - nanmean(TempShuffAvg{2}); % mean trials M - D
                end
            end
        end
        if Style >= 3
            NewDiff(II,Session) = (sum(Diff(:,II,Session) .^ 2)).^0.5;
            for Shuff = 1:size(TempCIDiff,4)
                ShuffleDiff(II,Session,Shuff) =  (sum(TempCIDiff(:,II,Session,Shuff).^2)).^ 0.5;
            end
        end
    end
end
if Style >= 3
    Diff = NewDiff;
end

% adjsut / average across sessions
if Style == 2
    for Dim = 1:DimNum
        for II = 1:Duration
            Trace(Dim,II) = nanmean(Diff(Dim,II,:));
            for Shuff = 1:length(Statistic)-1
                TempShuffDiff(Shuff) = nanmean(TempCIDiff(Dim,II,:,Shuff));
            end
            % averge across sessions and get CI
            CIDiff(Dim,II,1) = prctile(TempShuffDiff,2.5);
            CIDiff(Dim,II,2) = prctile(TempShuffDiff,97.5);
        end
    end
end

if Style == 3
    for II = 1:Duration
        Trace(II) = nanmean(Diff(II,:));
        for Shuff = 1:size(Statistic,3)-1
            TempShuffDiff(Shuff) = nanmean(ShuffleDiff(II,:,Shuff));
        end
        % averge across sessions and get CI
        CIDiff(II,1) = prctile(TempShuffDiff,2.5);
        CIDiff(II,2) = prctile(TempShuffDiff,97.5);
        %         pdfit(TempShuffDiff);
        P(II) = normcdf(-abs(Trace(II)),mean(TempShuffDiff),std(TempShuffDiff)) + (1-(normcdf(abs(Trace(II)),mean(TempShuffDiff),std(TempShuffDiff))));
        
        %
    end
end


if Style == 4
    for II = 1:Duration
        Trace(II) = nanmean(Diff(II,:));
        TempShuffDiff = nanmean(ShuffleDiff(II,:));
        
        CIDiff(II,1) = prctile(ShuffleDiff(II,:),2.5);
        CIDiff(II,2) = prctile(ShuffleDiff(II,:),97.5);
        
        P(II) = signrank(Diff(II,:),ShuffleDiff(II,:));
    end
end
%% plot

if Style  == 1
    figure;
    for Dim = 1:DimNum
        subplot(DimNum,1,Dim);
        %     plot(squeeze(Sig(Dim,:,:)));
        for II = 1:Duration
            clearvars TempData
            for BS = 1:1000
                TempData(BS) = nanmean(datasample(squeeze(Sig(Dim,II,:)),length(squeeze(Sig(Dim,II,:))),'Replace',true));
            end
            CIs(II,2) = prctile(TempData,2.5);
            CIs(II,1) = prctile(TempData,97.5);
            
        end
        
        
        Trace = squeeze(nanmean(Sig(Dim,:,:),3));
        patches([],CIs(1:15,:),[1:15])
        patches([],CIs(16:24,:),[16:24])
        hold on
        plot(Trace(1:15),'k','LineWidth',2)
        plot([16:24],Trace(16:24),'k','LineWidth',2)
        
        line([1 24],[0.05 0.05],'color','k','LineWidth',1.5,'LineStyle','--')
        line([15.5 15.5],[0 1],'color','r','LineWidth',1.5);
        Ax = gca;
        Ax.YTick = [0 1];
        axis([1 24 0 1]);
        Ax.XTick = [1 15 24];
        Ax.XTickLabel = {'0 ms';'3200 ms';'2000 ms'};
        
        
    end
elseif Style == 2
    figure;
    for Dim = 1:size(Statistic{1},2)
        subplot(size(Statistic{1},2),1,Dim);
        
        
        patches([],squeeze(CIDiff(Dim,1:15,:)),[1:15])
        patches([],squeeze(CIDiff(Dim,16:24,:)),[16:24])
        hold on
        plot(Trace(Dim,1:15),'k','LineWidth',2)
        plot([16:24],Trace(Dim,16:24),'k','LineWidth',2)
        
        line([1 24],[0 0],'color','k','LineWidth',1.5,'LineStyle','--')
        line([15.5 15.5],[-0.02 0.02],'color','r','LineWidth',1.5);
        Ax = gca;
        Ax.YTick = [-0.02 0.02];
        axis([1 24 -0.02 0.02]);
        Ax.XTick = [1 15 24];
        Ax.XTickLabel = {'0 ms';'3200 ms';'2000 ms'};
        
        
    end
    
    
    
elseif Style >= 3
    figure;
    
    patches([],squeeze(CIDiff(1:15,:)),[1:15])
    patches([],squeeze(CIDiff(16:24,:)),[16:24])
    hold on
    plot(Trace(1:15),'k','LineWidth',2)
    plot([16:24],Trace(16:24),'k','LineWidth',2)
    
    %     line([1 24],[0 0],'color','k','LineWidth',1.5,'LineStyle','--')
    line([15.5 15.5],[0 0.2],'color','r','LineWidth',1.5);
    Ax = gca;
    Ax.YTick = [0 0.2];
    axis([1 24 0 0.2]);
    Ax.XTick = [1 15 24];
    Ax.XTickLabel = {'0 ms';'3200 ms';'2000 ms'};
    
    text(2,0.1,strcat('all p are > ',num2str(min(P(2:end))))) % because first bin is not really during the delay
    text(2,0.08,'corrected alpha is 0.0020833');
    
end




