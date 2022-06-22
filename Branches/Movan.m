%% ANALYSIS OF MOVEMENT, AROUSAL, AND LIGHT EFFECTS
% Supp Fig 2, 5

%% LOAD
load('Opto.mat');
load('Meso.mat');
load('Reso.mat');

%% SUPPLEMENTARY
% E2.b - task delay running and early licking
delay_speed_halt_lick(selector(Trial,Data,'NoLight','NoMaskOn2'),'EnMouse',true);
saveas(gcf,'Plots/Movan/Delay speed halt lick.pdf');

% E2.a, c, d - movement and arousal vs task
movement_control(selector(Trial,Data,'Post','NoReset'),[],[])
exportgraphics(gcf,'Plots/Movan/Behan running control.pdf','ContentType','vector');
imaging_movement_control({Meso;Reso});
exportgraphics(gcf,'Plots/Movan/Meso running control.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Meso pupil control.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Reso running control.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Reso pupil control.pdf','ContentType','vector');

% E5 - effect of silencing light on movement and arousal vs task
% SOLUTION: Run _old to make a plot with masking, do sign-ranks within the
% plot. Then, run standard version to obtain an ANOVA with only the
% silencing light. For Reso, run only the standard version for plotting and
% the respective ANOVA. Again, report both the sign-ranks within the plot
% (individual light effects), and the ANOVA for the task and interaction
% effect.
run_mask_light_old(selector(Trial,Data,'Post','NoReset'));
exportgraphics(gcf,'Plots/Movan/Masking effect per session opto.pdf','ContentType','vector');
run_mask_light(selector(Trial,Data,'Post','NoReset','M2'),[]);
exportgraphics(gcf,'Plots/Movan/Beh M2 movement light.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Beh M2 movement light ANOVA.pdf','ContentType','vector');
run_mask_light(selector(Trial,Data,'Post','NoReset','AM'),[]);
exportgraphics(gcf,'Plots/Movan/Beh AM movement light.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Beh AM movement light ANOVA.pdf','ContentType','vector');
run_mask_light(Reso(destruct(Reso,'Area')==2),[],'Imaging',true,'AreaM2',true);
exportgraphics(gcf,'Plots/Movan/Reso M2-silenced movement light.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Reso M2-silenced movement light running ANOVA.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Reso M2-silenced movement light pupil ANOVA.pdf','ContentType','vector');
run_mask_light(Reso(destruct(Reso,'Area')==1),[],'Imaging',true,'AreaM2',true);
exportgraphics(gcf,'Plots/Movan/Reso AM-silenced movement light.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Reso AM-silenced movement light running ANOVA.pdf','ContentType','vector');
exportgraphics(gcf,'Plots/Movan/Reso AM-silenced movement light pupil ANOVA.pdf','ContentType','vector');

%% MISC
perf_run_mask_light(selector(Trial,Data,'Post','NoReset','HasMasking'),[])
% NT version
perf_run_mask_light(selector(Trials(4:end),'Post','NoReset','HasMasking'),[],'EarData',true)

