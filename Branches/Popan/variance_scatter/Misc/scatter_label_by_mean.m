function scatter_label_by_mean(Numbers,varargin)
Colour = 'k';
Axis = [];

%% parse args
for I = 3:2:numel(varargin)
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

%%
% figure;
X = Numbers(:,1);
Y = Numbers(:,2);

scatter(X,Y,'Marker','o','SizeData',ceil(15000 / length(X)),'MarkerEdgeColor','none','MarkerFaceColor',Colour,'MarkerFaceAlpha',1);
% plot(Pairs{1},Pairs{2},'LineStyle','none','Marker','o','color','k');
hold on;
XMax = max([X]);
XMin = min([X]);
YMax = max([Y]);
YMin = min([Y]);
if ~isempty(Axis)
    axis(Axis);
else
    axis([XMin XMax YMin YMax])
end
text(double(XMin+XMax/9),double(YMax-1*(YMax/9.9)),strcat({'Average of X = '},{num2str(nanmean(X),'%0.2g')}));
text(double(XMin+XMax/9), double(YMax-2*(YMax/9.9)),strcat({'Average of Y = '},{num2str(nanmean(Y),'%0.2g')}));
if ~isempty(varargin{1})
    % noise levels
end
if ~isempty(varargin{2})
    xlabel(varargin{2}{1});
    ylabel(varargin{2}{2});
else
    xlabel('Average firing rate of pair');
    ylabel('Pairwise noise correlations');
end


% % figure;
% Max = [];
% Min = [];
% for Task = 1:2
%     A = Mean(:,Task);
%     B = Cors(:,Task);
%     Max = max(max([A; B]),Max);
%     Min = min(min([A; B]),Min);
% end
% 
% for Task = 1:2
%     subplot(2,1,Task)
%     A = Mean(:,Task);
%     B = Cors(:,Task);
%     R = corrcoef(A,B);
%     
%     scatter(A,B,'Marker','o','SizeData',15,'MarkerEdgeColor','none','MarkerFaceColor','k','MarkerFaceAlpha',1);
%     hold on;
%     axis([Min Max Min Max])
%     xlabel('Average Activity of Pair');
%     if Task == 1
%         ylabel('Memory Task');
%     elseif Task == 2
%         ylabel('Discrimination Task');
%     end
%     line([Min Max],[Min Max],'color','k','LineWidth',1.5);
%     title(strcat({'Pearsons R^2 = ';num2str(R(2))}));
%     
%     
%     %     if ~isempty(varargin{1})
%     %         % shuffle
%     %     end
%     %     if ~isempty(varargin{2})
%     %         xlabel(varargin{2}{1});
%     %         ylabel(varargin{2}{2});
%     %
%     %     end
% end
% end