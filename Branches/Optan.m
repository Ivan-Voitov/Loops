%% ANALYSIS OF OPTOGENETIC EFFECTS
% Second half of Fig 1 and Supp Fig 6

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
% 1.h - brain colors
brain_plot(Trial,2,'Amp',1.25); %% 1.25 == 40% (is the +/- max)
saveas(gcf,'Plots/Optan/Brain colours.pdf');

% 1.i - AM and M2 bars
Stat = opto_bar(Trial,'Areas',[{'AM'}; {'M2'}],'EnMouse',false);
Areas = {'AM';'M2'}; Times = {'Delay','Stimulus'}; 
Tasks = {'Discrimination';'Memory'}; Stimuli = {'Cue';'Probe';'Target'};
for Area = 1:2; for Time = 1:2; for Task = 1:2; for Stimulus = 1:3;
    LightSig.(Areas{Area}).(Times{Time}).(Stimuli{Stimulus}).(Tasks{Task}) = Stat.Light{Time}{Area+2}(Task,Stimulus);
end; end ; end ; end
saveas(gcf,'Plots/Optan/Bars AM M2.pdf');

%% SUPPLEMENTARY
% E6 - full bar and stats
Stat = opto_bar(Trial,'Areas',[{'AM'}; {'M2'}; {'S1'}; {'V1'}; {'iAM'}; {'iM2'}],'TwoTime',true,'EnMouse',false);
saveas(gcf,'Plots/Optan/Full bar.pdf');
Areas = {'AM';'M2';'S1';'V1';'iAM';'iM2'};
C = 1;
for Area = 1:6
    R = 1;
    for Stimulus = 1:3; for Time = 1:2; for Task = 1:2;
       TableSig(R,C) = Stat.Light{Time}{Area+2}(Task,Stimulus);
       R = R + 1;
    end; end; end
    C = C + 1;
end
uitable('Data',TableSig,'ColumnName',Areas,'ColumnWidth',{80;80;80;80;80;80}','ColumnFormat',{'short e';'short e';'short e';'short e';'short e';'short e'}','Position',[20 20 800 300]);
saveas(gcf,'Plots/Optan/Full bar table.pdf');

%% L.F.R.
% recoveringness
delay_length(selector(Trial,'Post','NoReset','NoLight'),selector(Trial,'Post','NoReset','AM','EarlyDelayOnset','Light'),'ToPlot',[1 4],'BinSize',2,'PerfType','Correct','Fit',0,'Inset',false,'Tom',false,'Truncate',800);
delay_length(selector(Trial,'Post','NoReset','NoLight'),selector(Trial,'Post','NoReset','M2','EarlyDelayOnset','Light'),'ToPlot',[1:6],'BinSize',3,'PerfType','Response','Fit',0,'Inset',false,'Tom',true,'Truncate',800);

% 6 full bars 3 times
Stat = opto_bar(Trial,'Areas',[{'AM'}; {'M2'}; {'S1'}; {'V1'}; {'iAM'}; {'iM2'}],'TwoTime',true,'EnMouse',false);
saveas(gcf,'Plots/Optan/full bar.pdf');
Areas = {'AM';'M2';'S1';'V1';'iAM';'iM2'};
Times = {'Delay','Stimulus'};
Tasks = {'Discrimination';'Memory'};
Stimuli = {'Cue';'Probe';'Target'};
RowNames = {'';'';'';'';'';'';'';'';'';'';'';''};
C = 1;
for Area = 1:6
    R = 1;
    for Stimulus = 1:3
        for Time = 1:2
            for Task = 1:2
                TableSig(R,C) = Stat.Light{Time}{Area+2}(Task,Stimulus);
                R = R + 1;
            end
        end
    end
    C = C + 1;
end
uitable('Data',TableSig,'ColumnName',Areas,'ColumnWidth',{80;80;80;80;80;80}','ColumnFormat',{'short e';'short e';'short e';'short e';'short e';'short e'}','Position',[20 20 800 300]);

% opto effect vs trial history
Sel = destruct(Trial,'Post.Cue')>4;
Sel(isnan(destruct(Trial,'Post.Cue'))) = ...
    destruct(Trial(isnan(destruct(Trial,'Post.Cue'))),'Post.Distractor')>4;
Stat = opto_bar(Trial(~Sel),'Areas',[{'AM'}; {'M2'}],'EnMouse',false);
suptitle('Following <= 4 Cues')
Stat = opto_bar(Trial(Sel),'Areas',[{'AM'}; {'M2'}],'EnMouse',false);
suptitle('Following > 4 Cues')

% does it change rxn times?
rxn_time(selector(Trial,'Post','NoReset','NoLight','NoMaskOn2'),0)
rxn_time(selector(Trial,'Post','NoReset','Light','EarlyDelayOnset','AM'),0)
rxn_time(selector(Trial,'Post','NoReset','Light','EarlyDelayOnset','M2'),0)