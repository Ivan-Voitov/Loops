%% ANALYSIS OF CODING DIMENSIONS
% Fig 3 and Supp Fig 10

%% LOAD
% slow...
% CDTASK
[Meso] = encode(Meso); %l1o crossval
[MesoTrain] = encode(Meso,'Folds',1); % no cross val
[Meso5] = encode(Meso,'Five',true,'Iterate',1); % for behaviour. snr control

% CDCUE
[Meso] = encode(Meso,'CCD',true); 
[MesoTrace] = encode(Meso,'CCD',true,'Lag',600); % off response control/visualization
[MesoTrain] = encode(MesoTrain,'CCD',true,'Folds',1);
[Meso5] = encode(Meso5,'CCD',true,'Five',true,'Iterate',1);

% CDSTIMULUS
[Meso] = encode(Meso,'CCD',true,'Stim',true);
[Meso] = encode(Meso,'CCD',false,'Stim',true);

save('Meso.mat','Meso','Meso5','MesoTrain','-append');

% or...
load('Meso.mat')
load('CDRepository.mat')

% define area indexes
AreaIndex = destruct(Meso,'Area');
AreaNames = {'M2';'AM'};

%% MAIN FIGURES
% Fig 3b - sweep both areas
[Sweep,Explanations] = sweep_wrapper(Meso,'ReCalc',true,'AreaSplit',false);
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - TCD Both areas.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - CCD Both areas.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - Stim Both areas.pdf'})),'ContentType','vector');

for Area = 1:2
    % 3.c, f, i, l - delay single trial traces
    plot_trial_traces(MesoTrace(swap([15 16],Area)),'Types',{'Trace'},'CI',false,'Smooth',1,'CCD',false,'Sub',false,'OnlyDelay',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Trial trace WMCD '},AreaNames{Area},'.pdf')),'ContentType','vector');
    plot_trial_traces(MesoTrace(swap([15 16],Area)),'Types',{'CueTrace'},'CI',false,'Smooth',1,'CCD',true,'Sub',false,'OnlyDelay',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Trial trace CCD '},AreaNames{Area},'.pdf')),'ContentType','vector');
    
    % 3.d, g, j, m - consistency of traces. % 2800 and 1400 works
    dynamics_scatter(Meso(AreaIndex==Area),'Focus',true,'LimitBound',1800,'HalfWindow',1800,'Sub',false); %1800 = 1600 
    axis(swap({[-1.5 2.6 -1.5 2.6];[-1.1 2.1 -1.1 2.1]},Area));
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Francisco '},AreaNames{Area},' - recalc.pdf')),'ContentType','vector');
    dynamics_scatter(Meso(AreaIndex==Area),'Focus',true,'LimitBound',1800,'HalfWindow',1800,'CCD',true,'Sub',false);
    axis(swap({[-1.6 2.4 -1.6 2.4];[-1 1.8 -1 1.8]},Area));
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Francisco Cue '},AreaNames{Area},' - recalc .pdf')),'ContentType','vector');

    % 3.e, j, k, n - decoding vs behaviour
    decoding_behaviour(Meso5(AreaIndex==Area),'CCD',false);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding TCD Five '},AreaNames{Area},' CI.pdf')),'ContentType','vector');
    decoding_behaviour(Meso5(AreaIndex==Area),'CCD',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding CCD Five '},AreaNames{Area},' CI.pdf')),'ContentType','vector');
end

%% SUPPLEMENTS
% E11 - sweep area specific / split % days to run
[Sweep,Explanations] = sweep_wrapper({Sweep;Explanations},'ReCalc',false,'AreaSplit',true);
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - TCD Area AM.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - CCD Area AM.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - Stim Area AM.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - TCD Area M2.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - CCD Area M2.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - Stim Area M2.pdf'})),'ContentType','vector')

for Area = 1:2
    % E12 - behaviour decoding split by experiments
    decoding_behaviour(Meso5(AreaIndex==Area),'CCD',false);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding TCD Five '},AreaNames{Area},' Sessioned Accuracy.pdf')),'ContentType','vector');
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding TCD Five '},AreaNames{Area},' Sessioned Score.pdf')),'ContentType','vector');
    decoding_behaviour(Meso5(AreaIndex==Area),'CCD',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding CCD Five '},AreaNames{Area},' Sessioned Accuracy.pdf')),'ContentType','vector');
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding CCD Five '},AreaNames{Area},' Sessioned Score.pdf')),'ContentType','vector');
    
    % E13.a, e - main line plot
    distractor_memory(rescore(Meso(AreaIndex==Area)));
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Distractor memory - '},AreaNames{Area},'.pdf')),'ContentType','vector');
    
    % E13.b, f - stimulus memory control #1: ccd in disc task    
    plot_trial_traces(rescore(Meso(swap([15 16],Area))),'Cross',true,'Types',{'CueTrace'},'CI',false,'Smooth',1,'CCD',false,'Sub',false,'OnlyDelay',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Trial trace CCD - distractor cross-task - '},AreaNames{Area},'.pdf')),'ContentType','vector');

    % E13.c, g
    dynamics_scatter(rescore(Meso(AreaIndex==Area)),'Focus',true,'LimitBound',1800,'HalfWindow',1800,'CCD',false,'Sub',false,'Cross',true);
    axis(swap({[-1.982 2.9476 -1.982 2.9476];[]},Area))
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Francisco - CCD distractor cross-task - '},AreaNames{Area},'.pdf')),'ContentType','vector');
    
    % E13.d, h
    decoding_behaviour(rescore(Meso5(AreaIndex==Area)),'CCD',false,'DistractorEncoding',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding - Distractor encoding - '},AreaNames{Area},' CI.pdf')),'ContentType','vector');
  
    % E14 - correlate CDTASK and CDCUE
    coding_compensation(Meso(AreaIndex == Area));
    exportgraphics(gcf,decell(strcat({'Plots/Popan/CDTASK CDCUE compensation - '},AreaNames{Area},'.pdf')),'ContentType','vector');
end

%% MISC
% EXXX - premotoration
% CR/FAs were not predicted by dimensionality collapse and in general were
% not predictable at least in disc task (CD stuff)
% CD of action (CR<>FA)
for Area = 1:2
    premotoration(Meso(AreaIndex==Area));
    exportgraphics(gcf,decell(strcat({'Plots/Popan/FA decoding - '},AreaNames{Area},'.pdf')),'ContentType','vector');
end

% EXX - rotating coding dimensions
[ToPlot] = rotation(Meso); % hours to run
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Corr TCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Corr CCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Cross Class TCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Cross Class CCD.pdf'})),'ContentType','vector');

coding_compensation(Meso(AreaIndex == Area),'Short',true);
exportgraphics(gcf,decell(strcat({'Plots/Popan/CDTASK CDCUE compensation - short delay - '},AreaNames{Area},'.pdf')),'ContentType','vector');
coding_compensation(Meso(AreaIndex == Area),'Long',true);
exportgraphics(gcf,decell(strcat({'Plots/Popan/CDTASK CDCUE compensation - long delay - '},AreaNames{Area},'.pdf')),'ContentType','vector');

% premotoration
% last 800 ms
premotoration(Meso(AreaIndex==Area),'Minus',true,'Window',[0 1000]);
% stimulus period
premotoration(Meso(AreaIndex==Area),'Stimulus',true,'Window',[0 2000]);

% rotation of the CDs over the course of the delay
[ToPlot] = rotation(Meso,'Iterate',3); % hours to run
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Corr TCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Corr CCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Cross Class TCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Cross Class CCD.pdf'})),'ContentType','vector');
    
% CCD and TCD vectors compare
cd_comparison(Meso);
exportgraphics(gcf,strcat({'Plots/Popan/cue decoding '},AreaIndex{Area},'.pdf'),'ContentType','vector');

% beh decoding controls using full delay and only first 800 ms
for Area = 1:2
    decoding_behaviour(Meso(AreaIndex==Area));
    exportgraphics(gcf,strcat({'Plots/Popan/Beh decoding full delay '},AreaIndex{Area},'.pdf','ContentType','vector');
    decoding_behaviour(MesoMinus800(AreaIndex==Area));
    exportgraphics(gcf,strcat({'Plots/Popan/Beh decoding MINUS 800 '},AreaIndex{Area},'.pdf','ContentType','vector');
end

% ecode different time within task control
decode_time_control(Meso);
exportgraphics(gcf,'Plots/Popan/Example of how to decode time.pdf');
exportgraphics(gcf,'Plots/Popan/Decode time with WMCD.pdf','ContentType','vector');

% robustness of CDs
Temp = cat(1,Meso800,MesoClever,MesoNoReg,MesoRegression,MesoUnEquated,MesoNotOnlyCorrect);
compare_sorted_values(Meso,Temp,...
    {'Original';'800';'Clever';'NoReg';'Regression';'UnEquated';'NotOnlyCorrect'});
exportgraphics(gcf,'Plots/Popan/TCD robustness.pdf','ContentType','vector');

% CDHISTORY DOESNT WORK
[MesoM] = encode(Meso,'Memory',true,'History',true); 
[MesoC] = encode(Meso,'Memory',true,'CCD',true); 
[MesoD] = encode(Meso,'Discrimintion',true,'History',true); 
