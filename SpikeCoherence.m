% define directories where files are stored. 
clearvars;
addpath('Z:\alex\AdeetiFigures\');
stemDir  = 'Z:\adeeti\JenniferHelen\SpikeSortingResults\';
Dirs={[stemDir, 'LEDAwakeOnly\'], [stemDir, 'LEDKetOnly\'], [stemDir, 'LEDLowIsoOnly\']};
% create a table where data will be stored
T = table('Size',[1,11],'VariableTypes',["string","string", "string", "cell", "cell", "cell", "cell", "cell", "cell", "cell", "cell"]);
T.Properties.VariableNames=["MouseName", "File", "Condition", "V1Unit", "PPAUnit", "V1TrialCount", "PPATrialCount", "V1goodTrials", "PPAGoodTrials", "TakeSpikes","NumGoodTrials"];  % gives variables some useful names
counter=1;
spikeThreshold=10;
%%
conNames={'W', 'K', 'I'};
for i=1:numel(Dirs)
    % get the files from the current dirrectory
    currentDir=Dirs{i};
    cd(currentDir);
    fileNames=dir('*.mat');
    for j=1:numel(fileNames)
        load(fileNames(j).name);                    % load the file 
        V1Units=find(trueLoc'<=96);                 % V1 units are below channel 96
        PPAUnits=find(trueLoc'>96);                 % PPA units are in 97+
        V1Train=trialSpiketrain(V1Units,:);         % collect all V1 unit trains
        V1Counts=cellfun(@numel, V1Train);          % get spike counts for all V1 units in each trial
        PPATrain=trialSpiketrain(PPAUnits,:);       % collect all PPA unit trains
        PPACounts=cellfun(@numel, PPATrain);        % get spike counts for all PPA units in each trial 
        % now populate the table
        mouseName=strsplit(fileNames(j).name, '_');
        mouseName=mouseName{2};
        T.MouseName(counter)=mouseName;
        T.File(counter)=[currentDir fileNames(j).name];
        T.Condition(counter)=conNames{i};
        T.V1Unit(counter)={V1Units};
        T.PPAUnit(counter)={PPAUnits};
        T.V1TrialCount(counter)={V1Counts};
        T.PPATrialCount(counter)={PPACounts};
        T.V1goodTrials(counter)={V1Counts>=spikeThreshold};
        T.PPAGoodTrials(counter)={PPACounts>=spikeThreshold};
        goodV1=V1Counts>=spikeThreshold;
        goodPPA=PPACounts>=spikeThreshold;
        % find trials where both V1 and PPA spikes are above thre threshold
        % count
        takeSpikes=zeros(numel(V1Units), numel(PPAUnits), size(trialSpiketrain, 2));
        for V1s=1:numel(V1Units)
            for PPAs=1:numel(PPAUnits)
            takeSpikes(V1s, PPAs,:)=goodV1(V1s,:) & goodPPA(PPAs,:);               
            end
        
        
        end
        T.TakeSpikes(counter)={takeSpikes}; 
        T.NumGoodTrials(counter)={sum(takeSpikes,3)};
        counter=counter+1;    
    end
    
end
%% Now that the database is prepared we can analyze the coherence.
outputDir= [ stemDir, 'SpikeCoherence'];
outfile=neuronCoherence(T, 1, 20, outputDir);

%%
for r=6:size(T,1)
    outfile=neuronCoherence(T, r, 20, outputDir);

end
    
    