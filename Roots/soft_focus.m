function [DFFs] = soft_focus(DFFs,Index,Mode)
if ~exist('Mode','var')
    Mode = 1;
end

for Session = 1:length(DFFs)
    load(Index(Session).Name,'Trial');
    if Mode == 1
        Trial = selector(Trial,'HasFrames','Nignore','NoReset','EitherDB');
    elseif Mode == 2
         % still keeps track of combob'd. basically a context AND a matched
        % distractor
        TempDB = Trial(and(Index(Session).Combobulation,destruct(Trial,'Task')==1)).DB;
        
        Trial = Trial(or(and(destruct(Trial,'DB')~=TempDB,destruct(Trial,'Task')==2),...
            and(destruct(Trial,'DB')==TempDB,destruct(Trial,'Task')==1)));
        
        Trial = selector(Trial,'NoReset','HasFrames','Nignore','Post');
    end
    
    Frames = [];
    for III = 1:length(Trial)
        Frames = cat(1,Frames,[Trial(III).Trigger.Delay.Frame:Trial(III).Trigger.Post.Frame]');
    end
    Focus = false(size(DFFs{Session},2),1);
    Focus(Frames(~isnan(Frames))) = true;
    DFFs{Session}(:,~Focus) = nan;
end