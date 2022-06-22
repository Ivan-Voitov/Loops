function scatter_asym(Data,Noise,varargin)
% Colours = 'k';
Labels = {'Log mean firing rate';'Noise correlations'};
Blocks = 5;
Axis = [];

%% parse args
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
% get CI lines
Data(:,3) = Data(:,1) + Data(:,2);
Noise(:,3) = Noise(:,1) + Noise(:,2);
[LowLine,HighLine] = percentile_line(Data,Blocks,0);
[NoiseLowLine,NoiseHighLine] = percentile_line(Noise,Blocks,0);

XMax = round(max(max(HighLine(:,1)), max(LowLine(:,1))),2);
XMin = round(min(min(HighLine(:,1)), min(LowLine(:,1))),2);
YMax = round(max(max(HighLine(:,2)), max(LowLine(:,2))),2);
YMin = round(min(min(HighLine(:,2)), min(LowLine(:,2))),2);

%% plot
hold on;
Colours;
scatter(Data(:,1),Data(:,2),'Marker','o','SizeData',ceil(20000 / length(Data(:,1))),'MarkerEdgeColor','none','MarkerFaceColor',Red,'MarkerFaceAlpha',0.2);
line(LowLine(:,1),LowLine(:,2),'color',Red,'LineWidth',2)
line(HighLine(:,1),HighLine(:,2),'color',Red,'LineWidth',2)

scatter(Noise(:,1),Noise(:,2),'Marker','o','SizeData',ceil(20000 / length(Data(:,1))),'MarkerEdgeColor','none','MarkerFaceColor',Blue,'MarkerFaceAlpha',0.2);
line(NoiseLowLine(:,1),NoiseLowLine(:,2),'color',Blue,'LineWidth',2)
line(NoiseHighLine(:,1),NoiseHighLine(:,2),'color',Blue,'LineWidth',2)

Ax = gca;
Ax.XTick = [XMin XMax];
Ax.YTick = [YMin YMax];
if ~isempty(Axis)
    axis(Axis);
else
    axis([XMin XMax YMin YMax])
end
% text(double(XMin+XMax/9), double(YMax-1*(YMax/9.9)),strcat({'Average of X = '},{num2str(nanmean(Data(:,1)),'%0.2g')}));
% text(double(XMin+XMax/9), double(YMax-2*(YMax/9.9)),strcat({'Average of Y = '},{num2str(nanmean(Data(:,2)),'%0.2g')}));

xlabel(Labels{1});
ylabel(Labels{2});
