function [outFile] = neuronCoherence(T,row, thresh, outputDir)
% T is the talbe created by SpikeCoherence script. The row is the row of
% the table to be analyzed. thresh is the minimum number of trials in which
% both cells have to be firing at sufficiently high rate. outputDir is the
% directory where the data will be saved;
offset=1001;        % stimulus offset in ms
totalDur=3000;       % trial duration in ms.
Fs=1000;            % sampling rate (1Khz default)
F=@(x) RasterToTrain(x, offset, totalDur);     % define function to convert spike times into raster to be used in wavelet coherence;


[V1ind,PPAind]=find(T.NumGoodTrials{row}>thresh);          % identify pairs of cells that have sufficient number of good trials
%[V1ind,PPAind]=find(toAnalyze);
ids=[V1ind'; PPAind']';

if ~ isempty(ids)
    %[V1ind,PPAind]=ind2sub(size(toAnalyze), ind);  % convert to indices of v1 and ppa neurons;
    takeSpikes=T.TakeSpikes{row};                  % this will be used to find which trials to collect
    load(T.File{row});                             % load the appropriate file that contains the spike times
    V1units=T.V1Unit{row};                         % get V1 units
    PPAunits=T.PPAUnit{row};                       % get PPA units;
    for i=1:size(ids,1)
            V=ids(i,1);
            P=ids(i,2);
            trials=find(squeeze(takeSpikes(V, P,:)));        % for each pair of cells identify trials meeting criteria
            V1Spikes=trialSpiketrain(V1units(V), trials);                            % get appropriate spike times and trials for V1 cell
            PPASpikes=trialSpiketrain(PPAunits(P), trials);                           % get appropriate spikes times and trials for PPA cell
            V1Raster=cellfun(F, V1Spikes, 'UniformOutput', false);
            PPARaster=cellfun(F, PPASpikes, 'UniformOutput', false);
            % now compute coherence for each trial
            disp(['V1 neuron ' num2str(V) ' PPA neuron  ' num2str(P) ])
            disp(i);
            for t=1:numel(trials)                                             % compute coherence for each trial 
                disp(['Trial Number ' num2str(t)]);
                [wcoh, ~, f, coi]=wcoherence(V1Raster{t},PPARaster{t},Fs);
                if t==1
                    coh=zeros(size(wcoh,1), size(wcoh,2), length(trials));
                end
                coh(:,:,t)=wcoh;
                
            end
            coh=mean(coh,3);            % average across trials
            % make output file name
            outFile=[T.MouseName{row} '_' T.Condition{row} '_' num2str(V) '_' num2str(P) '.mat'];
            cd(outputDir);
            save(outFile, 'coh', 'f', 'coi', 'trials', 'thresh');
            
            
            
    end
else
    outFile=[];
end
    
    
end

