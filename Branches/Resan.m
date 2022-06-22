%% ANALYSIS OF BREAKING THE LOOP
% Fig 4 and Supp Fig 15

%% LOAD
load('Reso.mat');
load('Opto','Trial');

% speed up plotting
[DFFs,Trials] = rip(Reso,'Ax','DelayResponsive','DeNaN','Active','Context','DeSet');
OutLDA = encode({DFFs;Trials},'CCD',true,'Window',[-1000 3200],'OnlyCorrect',false,'Equate',false,'DePre',true,'Clever',false,'Iterate',1,...
    'NormalizeLDA',1,'FPS',22.39,'Folds',1,'AverageProjection',false,'Regularization',1);
OutLDAL1O = encode({DFFs;Trials},'CCD',true,'Window',[-1000 3200],'OnlyCorrect',true,'Equate',false,'DePre',true,'Clever',false,'Iterate',1,...
    'NormalizeLDA',1,'FPS',22.39,'Folds',-1,'AverageProjection',false,'Regularization',1); % no iteration needed because leave one out can only be done one way

% or speed up even more...
load('ResoEncodeOut.mat')

% rename variables
AvgTraces = OutLDA{7};
PC1Traces = OutLDA{9};
CueTraces = OutLDA{6};
CueTracesL1O = OutLDAL1O{6};

% define area indexes
AreaIndex = destruct(Reso,'Area');
Areas = {'M2';'AM'};

%% MAIN
for Area = 1:2
    % 4.b, h - effect hisograms raw, pick a time
    break_histogram({DFFs(AreaIndex==Area);Trials(AreaIndex==Area)},'Window',[0 3200],'FPS',22.39,'Z',true,'Ratio',false,'BinWidth',0.05);
    exportgraphics(gcf,strcat('Plots/Resan/Area', Areas{Area} ,'effect histogram Memory - recalc.pdf'),'ContentType','vector');

    % 4.c, i - avg traces 
    plot_experiment_traces({{AvgTraces(AreaIndex==Area);AvgTraces(AreaIndex==Area)};...
        {selector(Trials(AreaIndex==Area),'NoLight');selector(Trials(AreaIndex==Area),'Light')}},...
        'CCD',true,'DBBased',swap({[1 10 13 17];[2 8 9]},Area),'Light',true,'Split',true,'FPS',22.39,'CI',1,...
        'Normalize2',true,'Smooth',1,'Mirror',false,'OfAvg',true,'Bin',3,'YLim',swap({[-0.9 1.7];[-0.9 1.9]},Area));
    exportgraphics(gcf,strcat('Plots/Resan/Area', Areas{Area} ,' AVG Light Split.pdf'),'ContentType','vector');
    
    % 4.d, j - avg traces stats
    early_vs_late_light2({AvgTraces(AreaIndex==Area);Trials(AreaIndex==Area)},...
        'FPS',22.39,'LimitBound',0,'HalfWindow',1600,'Sub',false,'Option',1,'PlotOut',true,'OfAvg',true,'YLim',[-0.4 1.3]);
    axis square
    exportgraphics(gcf,strcat('Plots/Resan/Area', Areas{Area} ,' AVG Statistics.pdf'),'ContentType','vector');
    
    % 4.e, k - CCD traces 
    plot_experiment_traces({{CueTraces(AreaIndex==Area);CueTraces(AreaIndex==Area)};...
        {selector(Trials(AreaIndex==Area),'NoLight');selector(Trials(AreaIndex==Area),'Light')}},...
        'CCD',true,'DBBased',swap({[1 10 13 17];[2 8 9]},Area),'Light',true,'Split',false,'FPS',22.39,'CI',1,...
        'Normalize2',true,'Smooth',0,'Mirror',false,'Bin',3,'YLim',swap({[-1 1];[-1.3 1.3]},Area));
    exportgraphics(gcf,strcat('Plots/Resan/Area', Areas{Area} ,' CCD Light.pdf'),'ContentType','vector');
    
    % 4.f, l - CCD traces stats
    [NeuralRecovery{Area}] = early_vs_late_light2({CueTracesL1O(AreaIndex==Area);Trials(AreaIndex==Area)},...
        'FPS',22.39,'LimitBound',0,'HalfWindow',1600,'Sub',false,'Option',1,'PlotOut',true,'YLim',swap({[-0.3 0.5];[-0.1 0.8]},Area));
    axis square
    exportgraphics(gcf,strcat('Plots/Resan/Area', Areas{Area} ,' CCD Statistics.pdf'),'ContentType','vector');
end

% 4.m-n recoveringness analysis
for S = 1:length(Trials); for T = 1:length(Trials{S}); Trials{S}(T).FileName = Reso(S).Name; Trials{S}(T).SessionNumber = S; end; end

% reformat behavioural data to pool
Trials = selector(Trials,'NotProbe','NoReset','Nignore','Post');
TempTrial = selector(Trial,'NoReset','Nignore','Post','Memory','EarlyDelayOnset','NotProbe');
K = 1; TempTrials{K} = TempTrial(1);
for I = 2:length(TempTrial)
    if strcmp(TempTrial(I).FileName,TempTrial(I-1).FileName)
        TempTrials{K}(end+1) = TempTrial(I);
    else
        K = K +1;
        TempTrials{K}(1) = TempTrial(I);
    end
end
Input = {cat(2,selector(TempTrials,'M2'),Trials(AreaIndex==2));...
    cat(2,selector(TempTrials,'AM'),Trials(AreaIndex==1))};

[BehRecovery] = recoveringness(Input,NeuralRecovery,...
    'Pool','Sessions','IndexType',1,'Window',1600);
exportgraphics(gcf,'Plots/Resan/Beh recoveringness.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Resan/Recoveringness sessioned.pdf','ContentType','vector');

%% SUPPLEMENTS
% E15 - light effect no delay split
for Area = 1:2
    [Stat{Area,1}] = plot_experiment_traces({{AvgTraces(AreaIndex==Area);AvgTraces(AreaIndex==Area)};...
        {selector(Trials(AreaIndex==Area),'NoLight');selector(Trials(AreaIndex==Area),'Light')}},...
        'CCD',true,'DBBased',swap({[1 10 13 17];[2 8 9]},Area),'Light',true,'Split',true,'FPS',22.39,'CI',1,...
        'PlotOut',false,'Normalize2',true,'Smooth',1,'Mirror',false,'OfAvg',true,'Bin',3,'YLim',swap({[-0.9 1.7];[-0.9 1.9]},Area));
    
    % just for PC1 stat
    [Stat{Area,2}] = plot_experiment_traces({{PC1Traces(AreaIndex==Area);PC1Traces(AreaIndex==Area)};...
        {selector(Trials(AreaIndex==Area),'NoLight');selector(Trials(AreaIndex==Area),'Light')}},...
        'PlotOut',false,'CCD',true,'DBBased',swap({[1 10 13 17];[2 8 9]},Area),'Light',true,'Split',true,'FPS',22.39,'CI',1,...
        'Normalize2',true,'Smooth',1,'Mirror',false,'OfAvg',true,'PlotOut',0);
    
    % 4.e, k - CCD traces
    [Stat{Area,3}] = plot_experiment_traces({{CueTraces(AreaIndex==Area);CueTraces(AreaIndex==Area)};...
        {selector(Trials(AreaIndex==Area),'NoLight');selector(Trials(AreaIndex==Area),'Light')}},...
        'PlotOut',false,'CCD',true,'DBBased',swap({[1 10 13 17];[2 8 9]},Area),'Light',true,'Split',false,'FPS',22.39,'CI',1,...
        'Normalize2',true,'Smooth',1,'Mirror',false,'Bin',3,'YLim',swap({[-1 1];[-1.3 1.3]},Area));
end
break_lines(Stat);
exportgraphics(gcf,'Plots/Resan/Full delay light effect.pdf','ContentType','vector');

%% MISC
% sequences and control
list_all_cells(Reso,'Window',[0 3200],'FPS',22.39,'DFFsIn',DFFs,'Bounds',[0.2 0.6],'Light',0,'Smooth',2,'Z',true,'Types',{'DelayResponsive'});
list_all_cells(Reso,'Window',[0 3200],'FPS',22.39,'DFFsIn',DFFs,'Bounds',[0.2 0.6],'Light',1,'Smooth',2,'Z',true,'Types',{'DelayResponsive'});
list_all_cells(Reso,'Window',[0 3200],'FPS',22.39,'DFFsIn',DFFs,'Bounds',[0.2 0.6],'Light',2,'Smooth',2,'Z',true,'Types',{'DelayResponsive'});
exportgraphics(gcf,strcat('Plots/Resan/list boutons light OFF.pdf'),'ContentType','vector');
exportgraphics(gcf,strcat('Plots/Resan/list boutons light ON.pdf'),'ContentType','vector');
exportgraphics(gcf,strcat('Plots/Resan/list boutons light CNTRL.pdf'),'ContentType','vector');

for Area = 1:2
    % single trial (17 = 21, 2 = 21)
    plot_trial_traces({{CueTraces(AreaIndex==Area);CueTraces(AreaIndex==Area)};...
        {selector(Trials(AreaIndex==Area),'NoLight');selector(Trials(AreaIndex==Area),'Light')}},...
        'CCD',true,'Light',true,'Split',false,'DePre',false,'Z',[],'FPS',22.39,'CI',false,'Normalize',true,'Smooth',2);
    exportgraphics(gcf,strcat('Plots/Resan/Area', Areas{Area} ,' single session avg traces.pdf'),'ContentType','vector');
    
end
