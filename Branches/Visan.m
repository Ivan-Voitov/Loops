%% ANALYSIS OF SINGLE CELLS AND LOW-DIMENSIONAL DYNAMICS
% Fig 2 and Supp Fig 8-9

%% LOAD
load('Meso.mat')

% define area indexes
AreaIndex = destruct(Meso,'Area');
AreaNames = {'M2';'AM'};
% don't count same cells twice
Remove = false(length(Meso),1); clearvars TempNames
for Session = 1:length(Meso)
    TempNames{Session} = Meso(Session).Name;
    if any(strcmp(TempNames{Session},TempNames(1:end-1)))
        Remove(Session) = true;
    end
end
AreaIndex = destruct(Meso,'Area');
AreaIndex(Remove) = AreaIndex(Remove) + 2;
AreaNames = {'M2';'AM';'M2 Remaining';'AM Remaining'};

%% MAIN
for Area = 1:2
    % 2.c - single cell examples
    % Area 1 : DT [4 7 9] DR [105 121 139 144] ST [26 41 60]
    % Area 2 : DT [15 20 33 36] DR [147 167 195 196] ST [21 36 43 47]
    triggered_single_cells(Meso(AreaIndex==Area),'ResponseType','DelayResponsive','Sort','Latency','LineLimit',40,...
        'Ind',swaparoo({[4 7 9];[15 20 33 36]},Area));
    exportgraphics(gcf,decell(strcat({'Plots/Visan/Single cell example '},AreaNames{Area},{' DT.pdf'})),'ContentType','vector');
    triggered_single_cells(Meso(AreaIndex==Area),'ResponseType','DelayResponsive','Sort','Latency','LineLimit',40,...
        'Ind',swaparoo({[105 121 139 144];[147 167 195 196]},Area));
    exportgraphics(gcf,decell(strcat({'Plots/Visan/Single cell example '},AreaNames{Area},{' DR.pdf'})),'ContentType','vector');
    triggered_single_cells(Meso(AreaIndex==Area),'ResponseType','StimulusResponsive','Sort','Latency','LineLimit',40,...
        'Ind',swaparoo({[26 41 60];[21 36 43 47]},Area),'Window',[-1000 2000]);
    exportgraphics(gcf,decell(strcat({'Plots/Visan/Single cell example '},AreaNames{Area},{' ST.pdf'})),'ContentType','vector');
    
    % 2.d, f - list phases of activity
    list_all_cells(Meso(AreaIndex==Area),'Bounds',[0 1],'Normalize',1,'TomMemory',true);
    exportgraphics(gcf,decell(strcat('Plots/Visan/',AreaNames{Area},{' Memory cell list norm 1.pdf'})),'ContentType','vector');
    list_all_cells(Meso(AreaIndex==Area),'Bounds',[0 1],'Normalize',1,'TomDiscrimination',true);
    exportgraphics(gcf,decell(strcat('Plots/Visan/',AreaNames{Area},{' Discrimination cell list norm 1.pdf'})),'ContentType','vector');

    % 2.e, g - plot avg traces of all cells for the three triggers for task
    [Traces{Area}] = plot_experiment_traces(Meso(AreaIndex==Area),'Spikes',false,'CI',true);
    Ax = gca; Ax.YLim = [0 1.2]; Ax.YTick = [0 1.2];
    exportgraphics(gcf,decell(strcat({'Plots/Visan/Area '},AreaNames{Area},{' cell averaged activity - DELAY CELLS.pdf'})),'ContentType','vector');
    exportgraphics(gcf,decell(strcat({'Plots/Visan/Area '},AreaNames{Area},{' cell averaged activity - STIMULUS CELLS.pdf'})),'ContentType','vector');
    % stats
    [~,P(1)] = ttest2(nanmean(Traces{Area}{1,1},2), nanmean(Traces{Area}{2,1},2));
    [~,P(2)] = ttest2(nanmean(Traces{Area}{1,2},2), nanmean(Traces{Area}{2,2},2));
    
    % 2.h-k - low dim dynamics
    plot_lowdim_trajectories(Meso(AreaIndex==Area),'Space','PCA','Smooth',[],'Folds',1,'Dimensions',3,'Focus',true,'Equate',true);
    axis square; Ax = gca; if Area == 1; Ax.View =  [111.5048   16.0723]; elseif Area == 2; Ax.View =  [-110.3567    5.7300]; end
    exportgraphics(gcf,decell(strcat({'Plots/Visan/PCA trajectories trial averaged - '},AreaNames{Area},'.pdf')),'ContentType','vector');
    exportgraphics(gcf,decell(strcat({'Plots/Visan/PCA trajectories trial averaged - STATS - '},AreaNames{Area},'.pdf')),'ContentType','vector');
end

%% SUPPLEMENTARY
% cell # table maker
cell_numbers_table(Meso(AreaIndex==2)); % am
cell_numbers_table(Meso(AreaIndex==1)); % m2

% E7 - latencies of peak responses test (also no interactions)
area_task_latencies(Meso);
exportgraphics(gcf,'Plots/Visan/Latencies vs task.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Visan/Latencies vs area.pdf','ContentType','vector');

% E8 - scatter cells
for Area = 1:2
    variance_scatter(Meso(AreaIndex==Area),'Segments',20,'CCD',false);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Scatter TCD'}, AreaNames{Area} ,'.pdf')),'ContentType','vector');
    variance_scatter(Meso(AreaIndex==Area),'Segments',20,'CCD',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Scatter CCD'}, AreaNames{Area} ,'.pdf')),'ContentType','vector');
end

%% L.F.R.
propie(Meso)

for Area = 1:2
    plot_lowdim_trajectories(Meso(AreaIndex==Area),'CCD',true,'Space','PCA','Smooth',[],'Folds',1,'Dimensions',3,'Focus',true,'Equate',true);
end

% romo cell search
romo_identifier(Meso(AreaIndex==Area));
exportgraphics(gcf,decell(strcat({'Plots/Visan/Romo cell null all - '},AreaNames{Area},'.pdf')),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Visan/Romo cell null most Romo - '},AreaNames{Area},'.pdf')),'ContentType','vector');

% latencies correlations
DLatencies = [];
MLatencies = [];
for Z = 1:length(Meso)
    DLatencies = cat(2,DLatencies,Meso(Z).ShiftRightLatency((Meso(Z).StimulusResponsive)));
    MLatencies = cat(2,MLatencies,Meso(Z).ShiftLeftLatency((Meso(Z).StimulusResponsive)));
end
corrcoef(DLatencies(~isnan(MLatencies)),MLatencies(~isnan(MLatencies)))

% deconvolved activity
plot_task_traces(Meso(destruct(Meso,'Area')==1),'S',true,'CI',true);
saveas(gcf,'Plots/Visan/Area M2 cell averaged deconvolved activity - DELAY CELLS.pdf');
saveas(gcf,'Plots/Visan/Area M2 cell averaged deconvolved activity - STIMULUS CELLS.pdf');
plot_task_traces(Meso(destruct(Meso,'Area')==2),'S',true,'CI',true);
saveas(gcf,'Plots/Visan/Area AM cell averaged deconvolved activity - DELAY CELLS.pdf');
saveas(gcf,'Plots/Visan/Area AM cell averaged deconvolved activity - STIMULUS CELLS.pdf');

% different list normalizations
list_all_cells(Meso,'Bounds',[0 1.6],'Normalize',false,'OnlyMemory',true);
exportgraphics(gcf,'Plots/Visan/Discrimination cell list no norm.pdf','ContentType','vector');
list_all_cells(Meso,'Bounds',[0 1],'Normalize',2,'OnlyMemory',true);
exportgraphics(gcf,'Plots/Visan/Discrimination cell list norm 2.pdf','ContentType','vector');
list_all_cells(Meso,'Bounds',[0 1.6],'Normalize',false,'OnlyDiscrimination',true);
exportgraphics(gcf,'Plots/Visan/Memory cell list  no norm.pdf','ContentType','vector');
list_all_cells(Meso,'Bounds',[0 1],'Normalize',2,'OnlyDiscrimination',true);
exportgraphics(gcf,'Plots/Visan/Memory cell list norm 2.pdf','ContentType','vector');
list_all_cells(Meso,'Bounds',[0 1],'Normalize',1,'OnlyMemory',true);
exportgraphics(gcf,'Plots/Visan/Discrimination cell list norm 1.pdf','ContentType','vector');
list_all_cells(Meso,'Bounds',[0 1],'Normalize',1,'OnlyDiscrimination',true);
exportgraphics(gcf,'Plots/Visan/Memory cell list norm 1.pdf','ContentType','vector');
list_all_cells(Meso,'Bounds',[0 1],'Normalize',1,'OnlyOdd',true);
exportgraphics(gcf,'Plots/Visan/Odd cell list norm 1.pdf','ContentType','vector');
list_all_cells(Meso,'Bounds',[0 1],'Normalize',1,'OnlyEven',true);
exportgraphics(gcf,'Plots/Visan/Even cell list norm 1.pdf','ContentType','vector');