function compare_sorted_values(Index,Indices,varargin)

% to what to demultiply into
for S = 1:length(Index)
   NumTrials(S) = sum(~isnan(Index(S).Score));
end
MaxNum = max(NumTrials) .* length(NumTrials);

% cat the scores
Scores = [];
% OriginalInd = nan(MaxNum,1);
OriginalInd = cell(length(Index),1);
for Session = 1:length(Index)
    Scores = Index(Session).Score;
    OriginalNotNaN{Session} = ~isnan(Index(Session).Score);
    Scores = Scores(OriginalNotNaN{Session});
%     [~,TempInd] = sort(Scores);
    [~,OriginalInd{Session}] = sort(Scores);
% 
% 
%     TempInd = TempInd ./ (length(Scores) /  max(NumTrials));
%     TempInsert = nan(max(NumTrials),1);
%     TempInsert(round(TempInd)) = 1:length(TempInd);
    
%     OriginalInd(Session:length(Index):end) = TempInsert;
end

%
Indices = cat(1,Index,Indices);
% get resorted of all indices

ToPlotInd = nan(MaxNum,size(Indices,1));

for K = 1:size(Indices,1)
    for Session = 1:length(Index)
        Scores = Indices(K,Session).Score;
        Scores = Scores(OriginalNotNaN{Session});
        
        [~,TempInd] = sort(Scores(OriginalInd{Session}));
        TempInd = TempInd ./ (length(Scores) /  max(NumTrials));
        TempInsert = nan(max(NumTrials),1);
        TempInsert(1:length(TempInsert)/length(TempInd):end) = round(TempInd);%1:FREQ:length(max(NumTrials));
        
        ToPlotInd((Session:length(Index):end),K) = TempInsert;
    end
end


ToPlotInd(isnan(ToPlotInd(:,1)),:) = [];






% 
%     
%     Scores = [];
%     for Session = 1:length(Indices(1,:))
%         Scores = cat(1,Scores,zscore(Indices(K,Session).Score,[],'omitnan'));
%     end
%     Scores(isnan(Scores))= [];
% %     Scores(24257:24267) = -1;
%     [~,ToPlotInd(:,K)] = sort(Scores(OriginalInd));
%     
%         Scores = + StaggerNum;
% 
% end

%% plot
Colours;
figure; hold on;
% get color
for R = 1:max(NumTrials)
    Colour(:,R) = (Red.* (R ./ max(NumTrials))) + (Blue.*(1-(R./max(NumTrials))));
end


for K = 1:size(Indices,1)
    for L = 1:11:size(ToPlotInd,1)
        if ~isnan(ToPlotInd(L,K))
        P = plot([0 1]+K,[L L],'color',Colour(:,ToPlotInd(L,K)),'LineWidth',1);
        P.Color(4) = 0.5;
        end
    end
end

Ax = gca;
if ~isempty(varargin)
    Ax.XTick = 1.5:size(Indices,1)+0.5;
    Ax.XTickLabel = varargin{1};
    xtickangle(30)
end
Ax.YLim = [1 size(ToPlotInd,1)];
Ax.YTick = [1 size(ToPlotInd,1)];
ylabel('WMCD sorted trials');
ytickformat('%,.0d');
Ax.YAxis.Exponent = 0;

%%
% % cat the scores
% Scores = [];
% for Session = 1:length(Indices(1,:))
%     Scores = cat(1,Scores,zscore(Indices(1,Session).Score,[],'omitnan'));
% end
% Scores(isnan(Scores))= [];
% hold on;plot(Scores(Ind));
% 
% 
% 
% 
% 
% 
% 
% Colours;
% RedColour = 0:Red./length(Ind):Red;
% BlueColour = 0:Blue./length(Ind):Blue;
% 
% SortedColour = RedColour + BlueColour;
% 
% %% now compare
% for I = 1:length(Indices)
%     figure; hold on;
%     % cat the scores
%     Contrast = [];
%     for Session = 1:length(Indices{I})
%         Contrast = cat(1,Contrast,zscore(Indices{I}(Session).Score));
%     end
%     
%     for Line = 1:length(Scores)
%         plot([0 1],[Scores(Line) Contrast(Line)],'color',SortedColour(Line));
%     end
% end