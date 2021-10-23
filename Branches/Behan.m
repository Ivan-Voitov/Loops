%% ANALYSIS OF BEHAVIOUR
% First half of Fig 1 and Supp Fig 3-4

%% LOAD
Files = dir('D:/Data/Opto/*.mat');
AllTrial = [];
AllData = [];

for I = 1:length(Files)
    load(strcat('D:/Data/Opto/',Files(I).name),'Trial','Data','TrialMat');
    AllTrial = cat(1,AllTrial,Trial);
    AllData = cat(1,AllData,Data);
end

Trial = AllTrial;
Data = AllData;
clearvars AllTrial AllData

% or...
load('Opto.mat');

%% MAIN
% 1.b - context symmetry inset
symmetry(Trial,'EnMouse',true);
saveas(gcf,'Plots/Behan/Symmetry.pdf');
symmetry(Trial,'EnMouse',true,'TaskTest',true);

% 1.c and 1.d - delay length effect on performance
delay_length(selector(Trial,'Post','NoReset','NoLight'),[],'PerfType','Response','ToPlot',[1:6],'Fit',false,'BinSize',32,'Triple',false,'Mice',false,'Split',false,'Tom',true);
exportgraphics(gcf,'Plots/Behan/Delay vs responses.pdf','ContentType','vector');

% 1.e - d' 
delay_length(selector(Trial,'Post','NoReset','NoLight'),[],'D',true,'Centroids',4);
saveas(gcf,'Plots/Behan/d Prime.pdf');

% 1.f - reaction times
rxn_time(selector(Trial,'Post','NoReset','NoLight','NoMaskOn2'),1,'EnMouse',true);
saveas(gcf,'Plots/Behan/Reaction Times PDF.pdf');

% 3.b - behaviour vs db
load('Meso.mat')
load('Reso.mat')
db_performance({Meso;Reso});
saveas(gcf,'Plots/Behan/DB control.pdf');

%% SUPPLEMENTARY
% E2 - split by mouse and for statistics
[Model] = delay_length(selector(Trial,'Post','NoReset','NoLight'),[],'PerfType','Response','ToPlot',[1:6],'Fit',2,'Triple',false,'Mice',false,'Split',true,'Tom',true);
for Mouse = 1:9; for Type = 1:6; Stat(Mouse,Type) = Model{1}{Type,Mouse}.Coefficients.Estimate(2); end; end
for Type = 1:6; Sig(Type) = signrank(Stat(:,Type)); end % (only significance slopes were for mem cue)
text(1600,75,num2str(Sig'))
saveas(gcf,'Plots/Behan/Delay split per mouse and fit.pdf');

% E3 - reaction times
rxn_time(selector(Trial,'Post','NoReset','NoLight','NoMaskOn2'),0,'EnMouse',true);
saveas(gcf,'Plots/Behan/Reaction Times CDF.pdf');

% E4 - trial history and maneesh controls
trial_history(selector(Trial,'Post','NoReset','NoLight')); 
saveas(gcf,'Plots/Behan/Trial history all.pdf');
trial_history(selector(Trial,'Post','NoReset','NoLight','NotFAd')); 
saveas(gcf,'Plots/Behan/Trial history no FAd.pdf');
delay_length_stimulus_history_control(Trial)
saveas(gcf,'Plots/Behan/Trial history from Task switch.pdf');
saveas(gcf,'Plots/Behan/History delay vs responses - Discrimination.pdf');
saveas(gcf,'Plots/Behan/History delay vs responses - Memory.pdf');

%% L.F.R.
% DB symmetry
symmetry({Meso;Reso},'DBTest',true);
saveas(gcf,'Plots/Visan/Symmetry imaging -15.pdf');
saveas(gcf,'Plots/Visan/Symmetry imaging +15.pdf');
