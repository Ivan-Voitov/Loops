function scatter_sym(Data,Noise,varargin)
%% parse args
% Colours = 'k';
Labels = {'Discrimination';'Memory'};
Segments = 5;

for I = 1:2:numel(varargin) % first one is reserved for
    if ~exist(varargin{I},'var')
        sprintf('Warning: one of the ParseArgs did not exist \r');
    end
    eval([varargin{I} '= varargin{I+1};']);
end

% if numel(Colours) == 1
%     Colours = {Colours;Colours};
% end

%% define
R = corrcoef(Data(:,1),Data(:,2),'Rows','complete');
if ~isempty(Noise)
    NoiseR = corrcoef(Noise(:,1),Noise(:,2),'Rows','complete');
end

% get ci lines
Data(:,3) = Data(:,1) + Data(:,2);
Noise(:,3) = Noise(:,1) + Noise(:,2);
Blocks = 100 ./ Segments;
[LowLine,HighLine] = percentile_line(Data,Blocks,1);
[NoiseLowLine,NoiseHighLine] = percentile_line(Noise,Blocks,1);

% Max = max([Data(:,1); Data(:,2)]);
% Min = min([Data(:,1); Data(:,2)]);
Max = (max(max(NoiseHighLine(:)), max(NoiseLowLine(:))));
Min = (min(min(NoiseHighLine(:)), min(NoiseLowLine(:))));
Min = min(Min,0);

%% plot
[~, ~] = tight_fig(1, 1, 0.02, [0.1 0.1], [0.1 0.1],1,600,600);
axis([Min Max Min Max])

Colours;
hold on;
if ~exist('PointSize','var')
scatter(Data(:,1),Data(:,2),'Marker','o','SizeData',ceil(300 / length(Data(:,1))),'MarkerEdgeColor','none','MarkerFaceColor',Grey,'MarkerFaceAlpha',1);
else
%     scatter(Data(:,1),Data(:,2),'Marker','o','SizeData',PointSize,'MarkerEdgeColor','none','MarkerFaceColor',Grey,'MarkerFaceAlpha',1);
    scatter(Data(:,1),Data(:,2),'Marker','o','SizeData',PointSize,'MarkerEdgeColor','none','MarkerFaceColor',Black,'MarkerFaceAlpha',0.3);
end
patch([[NoiseLowLine(:,1); Max]; NoiseHighLine(end:-1:1,1) ],[[NoiseLowLine(:,2) ; Max]; NoiseHighLine(end:-1:1,2) ],Grey,'EdgeColor','none','FaceAlpha',0.2)

% line(NoiseLowLine(:,1),NoiseLowLine(:,2),'color',[0.5 0.5 0.5],'LineWidth',2)
% line(NoiseHighLine(:,1),NoiseHighLine(:,2),'color',[0.5 0.5 0.5],'LineWidth',2)
% patch([[NoiseLowLine(:,1); Max]; NoiseHighLine(end:-1:1,1) ],[[NoiseLowLine(:,2) ; Max]; NoiseHighLine(end:-1:1,2) ],Grey,'EdgeColor','none')

line(LowLine(:,1),LowLine(:,2),'color',Black,'LineWidth',2)
line(HighLine(:,1),HighLine(:,2),'color',Black,'LineWidth',2)

line([Min Max],[Min Max],'color','k','LineWidth',1.5,'LineStyle','--');
text(double(Min+Max/9), double(Max-1*(Max/9.9)),strcat({'Average of X = '},{num2str(nanmean(Data(:,1)),'%0.2g')}));
text(double(Min+Max/9), double(Max-2*(Max/9.9)),strcat({'Average of Y = '},{num2str(nanmean(Data(:,2)),'%0.2g')}));
text(double(Min+Max/9), double(Max-3*(Max/9.9)),strcat({'Pearsons R = '},{num2str(R(2),'%0.2g')}));
text(double(Min+Max/9), double(Max-4*(Max/9.9)),strcat({'Noise Pearsons R = '},{num2str(NoiseR(2),'%0.2g')}));

xlabel(Labels{1});
ylabel(Labels{2});
Ax = gca;
Ax.XTick = [Min Max];
Ax.YTick = [Min Max];
Ax.XTickLabel = [Min Max];
Ax.YTickLabel = [Min Max];
axis([Min Max Min Max]);
