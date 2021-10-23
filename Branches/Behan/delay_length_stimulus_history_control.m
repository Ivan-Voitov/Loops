function delay_length_stimulus_history_control(Trial)
ControlSize = 20;

%%
TaskLocation = 1; Trial(1).TaskLocation = TaskLocation;
for Tr = 2:length(Trial)
    if Trial(Tr).Task ~= Trial(Tr-1).Task
        TaskLocation = 1;
    else
        TaskLocation = TaskLocation + 1;
    end
    Trial(Tr).TaskLocation = TaskLocation;
end
trial_history(selector(Trial,'Post','NoReset','NoLight'),2);

%%
Trial = selector(Trial,'Post','NoReset','NoLight');
Label = false(length(Trial),1);
DistractorFlag = ControlSize;
CueFlag = destruct(Trial,'BlockLocation') == ControlSize;

for T = 2:length(Trial)
    if Trial(T).Task ~= Trial(T-1).Task
        DistractorFlag = ControlSize;
        Trial
    else
        DistractorFlag = DistractorFlag - 1;
    end
    if DistractorFlag > 0
        Label(T) = true;
    end
    if CueFlag(T) && T > ControlSize
        CueFlag(T-ControlSize:T) = true;
    end
end

delay_length(Trial(CueFlag),[],'PerfType','Response','ToPlot',[4 5 6],'Fit',0,'BinSize',8,'Triple',false,'Mice',false,'Split',false,'Tom',true);
delay_length(Trial(Label),[],'PerfType','Response','ToPlot',[1 2 3],'Fit',0,'BinSize',8,'Triple',false,'Mice',false,'Split',false,'Tom',true);

