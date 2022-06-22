% does a weird thing where it averages in a triggered way...
% in order to plot delay > stim as one trace. something i dont have.
% and portions.

function trajectorize(Projections,Trials,varargin)
Average = false;
Dim = 3;
Explanations = [];
CCD = false;

%% PASS ARGUMENTS TO CONTROLS
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

rng(100)

if ~iscell(Projections)
    Projections = {Projections};
end

% Dim = size(Projections{1},1);
Frames = {[0 3200]; [0 2000]};
Portions = {[800 1600];[1600 2400];[2400 3200]};
% Portions = {[800 1600];[1600 3200]};

%% calculate
for Session = 1:length(Trials)
    Onsets = destruct(Trials{Session},'Trigger.Stimulus.Frame') - destruct(Trials{Session},'Trigger.Delay.Frame');
    if ~CCD
        Labels = 3 - destruct(Trials{Session},'Task');
    else
        Labels = destruct(Trials{Session},'Block') + 1;
    end
    % for each task and portion reorganize projections to trial-averagable
    TempAvg = Projections{Session};
    
    Range = cellfun(@frame, Portions,'UniformOutput',false);
    for Task = 1:2
        for Portion = 1:length(Portions)
            % common to all
            for II = 1:Range{Portion}(1)
                Selected = and(Labels == Task,Onsets >= II);
                Trajectory{Task,Portion}(:,II) = nanmean(TempAvg(1:Dim,II,Selected),3);
            end
            % only onsets which are less than or equal to the last frame of
            % common
            for II = Range{Portion}(1)+1:Range{Portion}(2)+frame(2000)
                Selected = and(Labels == Task,Onsets <= Range{Portion}(2));
                Trajectory{Task,Portion}(:,II) = nanmean(TempAvg(1:Dim,II,Selected),3);
            end
        end
    end
    
    if ~Average && Session == 1% plot
        Plot(Trajectory,Explanations{Session},Dim,Portions,Range)
    else
        Trajectories{Session} = Trajectory;
    end
end

if Average
    for Task = 1:2
        for Portion = 1:length(Portions)
            Trajectory{Task,Portion} = zeros(size(Trajectories{Session}{Task,Portion}));
            %             CITrajectory{Task,Portion} = zeros([size(Trajectories{Session}{Task,Portion}) 2]);
            clearvars TempIes
            % convert to temp to be able to fit across sessions
            for Session = 1:length(Trajectories)
                TempIes(:,:,Session) = Trajectories{Session}{Task,Portion};
            end
            
            % for each time point and each dimension
            for II = 1:size(TempIes,2)
                for Dim = 1:size(TempIes,1)
                    PD = fitdist(squeeze(TempIes(Dim,II,:)),'Normal');
                    Trajectory{Task,Portion}(Dim,II) = PD.mu;
                end
            end
        end
    end
    plot_rough(Trajectory,Explanations,Dim,Portions,Range)
    plot_smooth(Trajectory,Explanations,Dim,Portions,Range)
    
end

end
%%
function plot_rough(Trajectory,Explanations,Dim,Portions,Range)
figure; hold on;
Colours; Colour = {Blue;Red};
OnsetColour = {Black,Grey,White};
for Task = 1:2
    for Portion = 1:length(Portions)
        if Dim == 2
            plot(Trajectory{Task,Portion}(1,1:Range{Portion}(1)),Trajectory{Task,Portion}(2,1:Range{Portion}(1)),'color',([0.7 0.7 0.7]+Colour{Task}) ./ 2,'LineWidth',4.5-Portion)
            plot(Trajectory{Task,Portion}(1,Range{Portion}(1):end),Trajectory{Task,Portion}(2,Range{Portion}(1):end),'color',([0.1 0.1 0.1]+Colour{Task}) ./ 2,'LineWidth',1.5)
        elseif Dim == 3
            plot3(Trajectory{Task,Portion}(1,1:Range{Portion}(1)),Trajectory{Task,Portion}(2,1:Range{Portion}(1)),Trajectory{Task,Portion}(3,1:Range{Portion}(1)),'color',([0.7 0.7 0.7]+Colour{Task}) ./ 2,'LineWidth',2)
            plot3(Trajectory{Task,Portion}(1,Range{Portion}(1):end),Trajectory{Task,Portion}(2,Range{Portion}(1):end),Trajectory{Task,Portion}(3,Range{Portion}(1):end),'color',([0.1 0.1 0.1]+Colour{Task}) ./ 2,'LineWidth',1.5)
        end
    end
end
for Task = 1:2
    for Portion = 1:length(Portions)
        if Dim == 2
            scatter(Trajectory{Task,Portion}(1,Range{Portion}(1)),Trajectory{Task,Portion}(2,Range{Portion}(1)),80,'Marker','o','MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceColor',OnsetColour{Portion},'LineWidth',1.5)
        else
            scatter3(Trajectory{Task,Portion}(1,Range{Portion}(1)),Trajectory{Task,Portion}(2,Range{Portion}(1)),Trajectory{Task,Portion}(3,Range{Portion}(1)),80,'Marker','o','MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceColor',OnsetColour{Portion},'LineWidth',1.5)
        end
    end
end
Ax = gca;
Ax.XTick = [];
Ax.YTick = [];
try Ax.ZTick = []; end
if ~isempty(Explanations)
    Ax.XLabel.String = strcat('PC1,',{' '},num2str(Explanations(1,1)),'% of variance explained');
    Ax.YLabel.String = strcat('PC2,',{' '},num2str(Explanations(2,1)),'% of variance explained');
    try Ax.ZLabel.String = strcat('PC3,',{' '},num2str(Explanations(3,1)),'% of variance explained'); end
end



end

function plot_smooth(Trajectory,Explanations,Dim,Portions,Range)
figure; hold on;
Colours; Colour = {Blue;Red};
OnsetColour = {Black,Grey,White};

%% interpolate 100
for On = 1:3
    Range{On} = Range{On} .* 100;
    for T = 1:2
        clearvars TempOut
        for D = 1:Dim
            TempOut(D,:) = interp1(100:100:size(Trajectory{T,On},2).*100,Trajectory{T,On}(D,:),1:size(Trajectory{T,On},2).*100,'linear','extrap');
        end
        Trajectory{T,On} = TempOut;
    end
end
%% smooth
% more complicated... smooth seperately
for T = 1:2
    for D = 1:Dim
        for On = 1:3
            Trajectory{T,On}(D,:) = gaussfilt(1:length(Trajectory{T,On}(D,:)),Trajectory{T,On}(D,:),50,'Ivan');
        end
        %
        %         % 5 smooths
        %         % short compoennt
        %         Trajectory{T,1}(D,1:Range{1}(1)) = gaussfilt(1:length(Trajectory{T,1}(D,1:Range{1}(1))),Trajectory{T,1}(D,1:Range{1}(1)),100);
        %         Trajectory{T,1}(D,Range{1}(1)+1:end) = gaussfilt(1:length(Trajectory{T,1}(D,Range{1}(1)+1:end)),Trajectory{T,1}(D,Range{1}(1)+1:end),100);
        %
        %         % middle component
        %         Trajectory{T,2}(D,1:Range{1}(1)) = Trajectory{T,1}(D,1:Range{1}(1));%gaussfilt(1:length(Trajectory{T,On}(D,:)),Trajectory{T,On}(D,:),100);
        %         Trajectory{T,2}(D,Range{1}(1)+1:Range{2}(1)) = gaussfilt(1:length(Trajectory{T,2}(D,Range{1}(1)+1:Range{2}(1))),Trajectory{T,2}(D,Range{1}(1)+1:Range{2}(1)),100);
        %         Trajectory{T,2}(D,Range{2}(1)+1:end) = gaussfilt(1:length(Trajectory{T,2}(D,Range{2}(1)+1:end)),Trajectory{T,2}(D,Range{2}(1)+1:end),100);
        %
        %         % last component
        %         Trajectory{T,3}(D,1:Range{1}(1)) = Trajectory{T,1}(D,1:Range{1}(1));%gaussfilt(1:length(Trajectory{T,On}(D,:)),Trajectory{T,On}(D,:),100);
        %         Trajectory{T,3}(D,Range{1}(1)+1:Range{2}(1)) = Trajectory{T,2}(D,Range{1}(1)+1:Range{2}(1));
        %         Trajectory{T,3}(D,Range{2}(1)+1:end) = gaussfilt(1:length(Trajectory{T,3}(D,Range{2}(1)+1:end)),Trajectory{T,3}(D,Range{2}(1)+1:end),100);
        %         % maybe one more here fore delay of last component
        %
        %
        %         %         % common
        %         %         Trajectory{T,1}(D,:) = gaussfilt(1:length(Trajectory{T,1}(D,:)),Trajectory{T,1}(D,:),100);
        %         %
        %         %         % shared
        %         %         Trajectory{T,2}(D,1:Range{1}(1)) = Trajectory{T,1}(D,1:Range{1}(1));%gaussfilt(1:length(Trajectory{T,On}(D,:)),Trajectory{T,On}(D,:),100);
        %         %         Trajectory{T,2}(D,Range{1}(1)+1:end) = gaussfilt(1:length(Trajectory{T,2}(D,Range{1}(1)+1:end)),Trajectory{T,2}(D,Range{1}(1)+1:end),100);
        %         %
        %         %         % shared
        %         %         Trajectory{T,3}(D,1:Range{2}(1)) = Trajectory{T,2}(D,1:Range{2}(1));%gaussfilt(1:length(Trajectory{T,On}(D,:)),Trajectory{T,On}(D,:),100);
        %         %         Trajectory{T,3}(D,Range{2}(1)+1:end) = gaussfilt(1:length(Trajectory{T,3}(D,Range{2}(1)+1:end)),Trajectory{T,3}(D,Range{2}(1)+1:end),100);
        %
    end
end


%%
for Task = 1:2
    for Portion = 1:length(Portions)
        if Dim == 2
            plot(Trajectory{Task,Portion}(1,1:Range{Portion}(1)),Trajectory{Task,Portion}(2,1:Range{Portion}(1)),'color',([0.7 0.7 0.7]+Colour{Task}) ./ 2,'LineWidth',4.5-Portion)
            plot(Trajectory{Task,Portion}(1,Range{Portion}(1):end),Trajectory{Task,Portion}(2,Range{Portion}(1):end),'color',([0.1 0.1 0.1]+Colour{Task}) ./ 2,'LineWidth',1.5)
            %             if ~isempty(CITrajectory)
            %                 patches([],...
            %                     squeeze(CITrajectory{Task,Portion}(2,1:Range{Portion}(1),2:-1:1)),...
            %                     Trajectory{Task,Portion}(1,1:Range{Portion}(1)))
            %
            %             end
        elseif Dim == 3
            plot3(Trajectory{Task,Portion}(1,1:Range{Portion}(1)),Trajectory{Task,Portion}(2,1:Range{Portion}(1)),Trajectory{Task,Portion}(3,1:Range{Portion}(1)),'color',([0.7 0.7 0.7]+Colour{Task}) ./ 2,...
                'LineWidth',3)
            plot3(Trajectory{Task,Portion}(1,Range{Portion}(1):end),Trajectory{Task,Portion}(2,Range{Portion}(1):end),Trajectory{Task,Portion}(3,Range{Portion}(1):end),'color',([0.1 0.1 0.1]+Colour{Task}) ./ 2,...
                'LineWidth',1.5)
        end
    end
end
for Task = 1:2
    for Portion = 1:length(Portions)
        if Dim == 2
            scatter(Trajectory{Task,Portion}(1,Range{Portion}(1)),Trajectory{Task,Portion}(2,Range{Portion}(1)),80,'Marker','o','MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceColor',OnsetColour{Portion},'LineWidth',1.5)
        else
            scatter3(Trajectory{Task,Portion}(1,Range{Portion}(1)),Trajectory{Task,Portion}(2,Range{Portion}(1)),Trajectory{Task,Portion}(3,Range{Portion}(1)),80,'Marker','o','MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceColor',OnsetColour{Portion},'LineWidth',1.5)
        end
    end
end
Ax = gca;
Ax.XTick = [];
Ax.YTick = [];
try Ax.ZTick = []; end
if ~isempty(Explanations)
    Ax.XLabel.String = strcat('PC1,',{' '},num2str(Explanations(1,1)),'% of variance explained');
    Ax.YLabel.String = strcat('PC2,',{' '},num2str(Explanations(2,1)),'% of variance explained');
    try Ax.ZLabel.String = strcat('PC3,',{' '},num2str(Explanations(3,1)),'% of variance explained'); end
end

end