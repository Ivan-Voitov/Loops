function plot_fano_factor(Index,varargin)
%% variables
FPS = 4.68;
Window = {[0 3200];[0 2000]};

%% parse
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% extract
[DFFs,Trials] = rip(Index,'S','Hyper','DeNaN','Active');

%% calculate
Traces{1,1} = avg_triggered(DFFs,selector(Trials,'Discrimination'),1,'Window',Window{1},'FPS',FPS,'FF',1);
Traces{1,2} = avg_triggered(DFFs,selector(Trials,'Discrimination'),2,'Window',Window{2},'FPS',FPS,'FF',1);
Traces{2,1} = avg_triggered(DFFs,selector(Trials,'Memory'),1,'Window',Window{1},'FPS',FPS,'FF',1);
Traces{2,2} = avg_triggered(DFFs,selector(Trials,'Memory'),2,'Window',Window{2},'FPS',FPS,'FF',1);

%% plot
figure; hold on;
Colours;
plot([1:size(Traces{1,1},2)],nanmean(Traces{1,1},1),'color',Blue);
plot([size(Traces{1,1},2)+1:size(Traces{1,1},2)+size(Traces{1,2},2)],nanmean(Traces{1,2},1),'color',Blue);
plot([1:size(Traces{2,1},2)],nanmean(Traces{2,1},1),'color',Red);
plot([size(Traces{2,1},2)+1:size(Traces{2,1},2)+size(Traces{2,2},2)],nanmean(Traces{2,2},1),'color',Red);

