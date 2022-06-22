function imaging_movement_control(Indices)
Meso = Indices{1};
Reso = Indices{2};

Remove1 = false(length(Meso),1); clearvars TempNames
for Session = 1:length(Meso)
    TempName = strsplit(Meso(Session).Name,'_');
    TempNames{Session} = cat(2,TempName{1},'_',TempName{2});
    if any(strcmp(TempNames{Session},TempNames(1:end-1)))
        Remove1(Session) = true;
    end
end

Remove2 = false(length(Reso),1); clearvars TempNames
for Session = 1:length(Reso)
    TempName = strsplit(Reso(Session).Name,'_');
    TempNames{Session} = cat(2,TempName{1},'_',TempName{2});
    if any(strcmp(TempNames{Session},TempNames(1:end-1)))
        Remove2(Session) = true;
    end
end

DataSet{1} = Meso(~Remove1); DataSet{2} = Reso(~Remove2);  FPSs = {4.68;22.39};
for D = 1:length(DataSet)
    Trials = []; Datas = []; Pupils = [];
    for Session = 1:length(DataSet{D})
        Temp = load(DataSet{D}(Session).Name,'Trial','Data','Pupil','IgnoreSeries');
        Trials{end+1} = Temp.Trial(~destruct(Temp.Trial,'Ignore'));
        Datas{end+1} = Temp.Data(~destruct(Temp.Trial,'Ignore'));
        Pupils{end+1} = nan;
        if isfield(Temp,'Pupil')
            if ~isempty(Temp.Pupil)
                Temp.Pupil(Temp.IgnoreSeries,:) = nan; %Temp.Pupil(Temp.Pupil(:,4)==1,:) = nan;
                Pupils{end} = Temp.Pupil;
            end
        end
    end
    Temp = selector(Trials,Datas,'NoReset','NoLight','Post');
%     if D == 2
%         Pupils{24} = nan;
%     end
    [Plotted{D}] = movement_control(Temp{1},Temp{2},Pupils,'FPS',FPSs{D});
end
