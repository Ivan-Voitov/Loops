function scatter_label_by_label(Numbers,varargin)
%% parse args
Colour = 'k';

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
R = corrcoef(X,Y,'Rows','complete');
if ~isempty(varargin{1})
    XX = varargin{1}(:,1);
    YY = varargin{1}(:,2);
    RR = corrcoef(XX,YY,'Rows','complete');
end
scatter(X,Y,'Marker','o','SizeData',ceil(15000 / length(X)),'MarkerEdgeColor','none','MarkerFaceColor',Colour,'MarkerFaceAlpha',1);
% plot(Pairs{1},Pairs{2},'LineStyle','none','Marker','o','color','k');
hold on;
Max = max([X; Y]);
Min = min([X; Y]);
axis([Min Max Min Max])

line([Min Max],[Min Max],'color','k','LineWidth',1.5);
text(double(Min+Max/9), double(Max-1*(Max/9.9)),strcat({'Average of X = '},{num2str(nanmean(X),'%0.2g')}));
text(double(Min+Max/9), double(Max-2*(Max/9.9)),strcat({'Average of Y = '},{num2str(nanmean(Y),'%0.2g')}));
text(double(Min+Max/9), double(Max-3*(Max/9.9)),strcat({'Pearsons R^2 = '},{num2str(R(2),'%0.2g')}));

if ~isempty(varargin{1})
    % draw shuffle
    text(double(Min+Max/9), double(Max-4*(Max/9.9)),strcat({'Control Pearsons R^2 = '},{num2str(RR(2),'%0.2g')}));
end
if ~isempty(varargin{2})
    xlabel(varargin{2}{1});
    ylabel(varargin{2}{2});
else
    xlabel('Memory task');
    ylabel('Discrimination task');
end
