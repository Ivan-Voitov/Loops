function brain_plot(Trial,Option,varargin)
Threshold = 1; %1-((1-0.05)^(1/6)); % needs to be around ~0.02
% Threshold = 0.01;
Amp = 1;

%% pass
for I=1:2:numel(varargin)
    eval([varargin{I} '= varargin{I+1};']);
end

%% get data
I = 0;
BrainColours = cell(1,1);
for Onset = [{'EarlyDelayOnset'} {'LateDelayOnset'} {'StimulusOnset'}]
    I = I + 1;
    [Perf,~,LightSig] = performance(selector(Trial,Onset{:},'NoReset','Post'),'Responses','OptoDelta',true);
    TempPerf = cat(3,Perf{3:end});
    for K = 3:length(Perf)
        Perf{K}(LightSig{K} > Threshold) = 0;
    end
    if Option == 1 % delta task delta perf
        BrainColours{I} = Perf(2,3:end) - Perf(1,3:end);
    end
    if Option == 2 % seperate task delta perf
        BrainColours{I,1} = squeeze(TempPerf(1,1,:) - TempPerf(1,3,:));
        BrainColours{I,2} = squeeze(TempPerf(2,1,:) - TempPerf(2,3,:));
    end
    if Option == 3 % delta task seperate fa/miss
        %         [TempColoursFA,~] = performance(selector(Trial,Onset{:},'NoReset','Post'),'FA','Delta',true,'Threshold',Threshold);
        %         [TempColoursMiss,~] = performance(selector(Trial,Onset{:},'NoReset','Post'),'Miss','Delta',true,'Threshold',Threshold);
        BrainColours{I,1} = TempColoursFA(2,3:end) - TempColoursFA(1,3:end);
        BrainColours{I,2} = TempColoursMiss(2,3:end) - TempColoursMiss(1,3:end);
    end
end

%% output
figure; hold on;
for K = 1:size(BrainColours,2)
    if K == 1
        subplot(size(BrainColours,2),6,1:5);
    else
        subplot(size(BrainColours,2),6,7:11);
    end
    for I = 1:size(BrainColours,1)
        for II = 1:6
            Image(I,II) = BrainColours{I,K}(II);
        end
    end
    Colours;
    Brains = (Image)+50;
    if Option == 2
       Red = Purple;
       Blue = Green;
    end
    %%
    ColourMap = [];
    %
    II = 1;
    Z = 0;
    ZZ = [];
    for Z = -100:0.1:100
        ZZ(II) =  1/(1+((1.3^(-Z))));
%                 ZZ(II) =  1/(1+((exp(-Z))));
%                 ZZ(II) =  1/(1+abs(Z));
        II = II + 1;
    end
    %     ZZ = ZZ(900:1099) - 0.5;
    %%
    for RGB = ZZ(901:2:1100)
        %     Colour(RGB*100,:) = ;
        if RGB <=0.5
            ColourMap = cat(1,ColourMap,(White.*(RGB.*2)) + (Blue.*(1-(RGB.*2))));
        else
            ColourMap = cat(1,ColourMap,((Red.*((RGB-0.5).*2))) + ((White.*(1-((RGB-0.5).*2)))));
        end
    end
    % Amp = 2.5;
    image(((Brains-50)*Amp) +50);
    colormap(ColourMap);
    subplot(size(BrainColours,2),6,(6*K));
    %     image(50-33:0.01:86)
    image(2.5:1:102.5)
end

% for I = 1:18
%     subplot(3,6,I);
%     if isstruct(Brains)

%     end
% end

% saveas(gcf,'Plots/Optan/Brain colours.bmp');

end