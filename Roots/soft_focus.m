function [DFFs] = soft_focus(DFFs,Index)

for Session = 1:length(DFFs)
    load(Index(Session).Name,'Trial');
    Trial = selector(Trial,'HasFrames','Nignore','NoReset','EitherDB');
    Frames = [];
    for III = 1:length(Trial)
        Frames = cat(1,Frames,[Trial(III).Trigger.Delay.Frame:Trial(III).Trigger.Post.Frame]');
    end
    Focus = false(size(DFFs{Session},2),1);
    Focus(Frames(~isnan(Frames))) = true;
    DFFs{Session}(:,~Focus) = nan;
end