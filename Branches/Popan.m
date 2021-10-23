%% ANALYSIS OF CODING DIMENSIONS
% Fig 3 and Supp Fig 10

%% LOAD
load('Meso.mat')
save('Meso.mat','Meso');

% CDt
[Meso] = encode(Meso,'Window',[-1000 3200],'Iterate',1,'Equate',false,'Smooth',1); % useful for all
[MesoTrain] = encode(Meso,'Window',[-1000 3200],'Folds',1); % useful for all
% [Meso800] = encode(Meso,'Window',[-1000 800],'Threshold',[]); % useful for beh
[MesoMinus800] = encode(Meso,'Window',[-1000 800],'Minus',true,'Threshold',[]); % useful for beh
[Meso5] = encode(Meso5,'Window',[-1000 3200],'Five',true);

% CDc
[Meso] = encode(Meso,'CCD',true,'Window',[-1000 3200],'Lag',600,'Smooth',1); % lag 600 = 400 really
[MesoTrain] = encode(MesoTrain,'CCD',true,'Window',[-1000 3200],'Folds',1);
% [Meso800] = encode(Meso800,'CCD',true,'Window',[-1000 1000]);
[MesoMinus800] = encode(MesoMinus800,'CCD',true,'Window',[-1000 800],'Minus',true,'Threshold',[]);
[Meso5] = encode(Meso5,'CCD',true,'Window',[-1000 3200],'Five',true);

save('CDRepository.mat','Meso','Meso5','MesoTrain','-append');

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
    plot_trial_traces(Meso(swaparoo([15 16],Area)),'Types',{'Trace'},'CI',false,'Smooth',1,'CCD',false,'Sub',false,'OnlyDelay',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Trial trace WMCD '},AreaNames{Area},'.pdf')),'ContentType','vector');
    plot_trial_traces(Meso(swaparoo([15 16],Area)),'Types',{'CueTrace'},'CI',false,'Smooth',1,'CCD',true,'Sub',false,'OnlyDelay',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Trial trace CCD '},AreaNames{Area},'.pdf')),'ContentType','vector');
    
    % 3.d, g, j, m - consistency of traces. % 2800 and 1400 also work
    dynamics_scatter(Meso(AreaIndex==Area),'LimitBound',1800,'HalfWindow',1800,'Sub',false); %1800 = 1600 
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Francisco '},AreaNames{Area},'.pdf')),'ContentType','vector');
    dynamics_scatter(Meso(AreaIndex==Area),'LimitBound',1800,'HalfWindow',1800,'CCD',true,'Sub',false);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Francisco Cue '},AreaNames{Area},'.pdf')),'ContentType','vector');

    % 3.e, j, k, n - decoding vs behaviour
    decoding_behaviour(Meso5(AreaIndex==Area),'CCD',false);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding WMCD Five '},AreaNames{Area},' CI.pdf')),'ContentType','vector');
    decoding_behaviour(Meso5(AreaIndex==Area),'CCD',true);
    exportgraphics(gcf,decell(strcat({'Plots/Popan/Beh decoding CCD Five '},AreaNames{Area},' CI.pdf')),'ContentType','vector');
end

%% SUPPLEMENTS
% E10 - sweep area specific
[Sweep,Explanations] = sweep_wrapper({Sweep;Explanations},'AreaSplit',true);
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - TCD Area AM.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - CCD Area AM.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - Stim Area AM.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - TCD Area M2.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - CCD Area M2.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Sweep decoding - Stim Area M2.pdf'})),'ContentType','vector');

%% L.F.R.
% rotation of the CDs over the course of the delay
[ToPlot] = rotation(Meso); % hours to run
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Corr TCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Corr CCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Cross Class TCD.pdf'})),'ContentType','vector');
exportgraphics(gcf,decell(strcat({'Plots/Popan/Rotation - Cross Class CCD.pdf'})),'ContentType','vector');

% CCD and TCD vectors compare
cd_comparison(Meso);
exportgraphics(gcf,strcat({'Plots/Popan/cue decoding '},AreaIndex{Area},'.pdf'),'ContentType','vector');

for Area = 1:2
    % beh decoding controls
    decoding_behaviour(Meso(AreaIndex==Area));
    exportgraphics(gcf,strcat({'Plots/Popan/Beh decoding full delay '},AreaIndex{Area},'.pdf','ContentType','vector');
    decoding_behaviour(MesoMinus800(AreaIndex==Area));
    exportgraphics(gcf,strcat({'Plots/Popan/Beh decoding MINUS 800 '},AreaIndex{Area},'.pdf','ContentType','vector');
end

% decode same db different cue/tasks works
cross_db(Meso);

% ecode different time within task NULL
decode_time_control(Meso);
exportgraphics(gcf,'Plots/Popan/Example of how to decode time.pdf');
exportgraphics(gcf,'Plots/Popan/Decode time with WMCD.pdf','ContentType','vector');

% robustness
Temp = cat(1,Meso800,MesoClever,MesoNoReg,MesoRegression,MesoUnEquated,MesoNotOnlyCorrect);
compare_sorted_values(Meso,Temp,...
    {'Original';'800';'Clever';'NoReg';'Regression';'UnEquated';'NotOnlyCorrect'});
exportgraphics(gcf,'Plots/Popan/TCD robustness.pdf','ContentType','vector');