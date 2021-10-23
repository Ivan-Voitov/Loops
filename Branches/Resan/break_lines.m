function break_lines(Stat,varargin)
%% params
FPS = 22.39;

%% pass params
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% convert to clear delay-averaged data
for Area = 1:2
    for CD = 1:size(Stat,2)
        for Condition = 1:2
            for Trigger = 1:2
                TempData1 = Stat{Area,CD}{1}{Condition,Trigger};
                TempData2 = Stat{Area,CD}{2}{Condition,Trigger};
                TempData1 = TempData1 .* swaparoo(cat(1,ones(size(Stat,2)-1, 1),-1)',CD);
                Data(:,Area,CD,Condition,Trigger) = nanmean(cat(2,TempData1,TempData2),2);
            end
        end
    end
end

%% plot and stats
Colours;
figure;
set(gcf,'Position',[200 200 1050 550]);
for SP = 1:length(Stat(:))
    subplot(1,length(Stat(:)),SP);
%     CD = ceil(SP / 2);
%     Area = rem(SP,2) + 1;
    CD = rem(SP-1,3) +1;
    Area = (SP>(size(Stat(:),1)./2))+1;
    
    plot(repmat([1 1.5],[size(Data,1) 1])',squeeze([Data(:,Area,CD,1,1) Data(:,Area,CD,2,1)])',...
        'color',Grey,'LineWidth',0.5,'Marker','none','MarkerFaceColor',Grey,'MarkerSize',6,'MarkerEdgeColor','none');
    hold on;
    
    plot(repmat(1,[size(Data,1) 1])',squeeze([Data(:,Area,CD,1,1)]),...
        'color',Black,'Marker','o','MarkerFaceColor',White,'MarkerSize',6,'MarkerEdgeColor',Black,'LineWidth',1,'LineStyle','none');
    plot(repmat(1.5,[size(Data,1) 1])',squeeze([Data(:,Area,CD,2,1)]),...
        'color',Red,'Marker','o','MarkerFaceColor',White,'MarkerSize',6,'MarkerEdgeColor',Red,'LineWidth',1,'LineStyle','none');
    P = signrank(Data(:,Area,CD,1,1),Data(:,Area,CD,2,1));
    text(1,max(max(Data(:,Area,CD,:,1)))+0.05,num2str(P),'color',Black)
    
    line([1-0.14 1+0.14],[nanmedian([Data(:,Area,CD,1,1)]) nanmedian([Data(:,Area,CD,1,1)])],'LineWidth',2,'Color',Black)
    line([1.5-0.14 1.5+0.14],[nanmedian([Data(:,Area,CD,2,1)]) nanmedian([Data(:,Area,CD,2,1)])],'LineWidth',2,'Color',Black)
    
    % set plotting parameters
    Ax= gca;
    Ax.XTick = [1 1.5];
    Ax.XLim  = [0.75 1.75];
    if exist('YLim','var')
        Ax.YLim = YLim;
    else
        Ax.YLim = round([(min(min(Data(:,Area,CD,:,1))) - nanstd(lineate(Data(:,Area,CD,:,1)))) (max(max(Data(:,Area,CD,:,1))) + nanstd(lineate(Data(:,Area,CD,:,1))))],1);
    end
%     Ax.YTick = sort(cat(2,Ax.YLim,0));
    Ax.YTick = sort(cat(2,Ax.YLim,0));

    Ax.XTickLabel = {'Off';'On'};
    
    ylabel(swaparoo({'Avg';'PC1';'CCD'},CD));
end




