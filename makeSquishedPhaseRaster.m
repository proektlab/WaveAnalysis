%function makeSquishedRasterPlot(trialSpiketrain, deltaPlot, gammaPlot, histogramOn, color, startLoc)
%this function plots a raster plot, with time warping so the delta phases
%line up
%output:    warpValues - values used to transform each trial
%inputs:    trialSpiketrain - 1xnumTrials cell vector containing spiketimes of
%           every trial
%           deltaPlot - values to plot for a delta overlay. should be
%           timepoints by trials
%           gamma plot - values for a gamma overlay, empty if no plot
%           histogramOn - whether or not there'll be a psth
%           color - color of plots
%           plotPoints - timepoints to plot
function warpValues = makeSquishedPhaseRaster(trialSpiketrain, deltaPlot, gammaPlot, histogramOn, color, plotPoints)
if nargin < 6
    plotPoints = 100:600;
end
if nargin < 5
    color = 'b';
end
if nargin < 4
    histogramOn = 0;
end
if nargin < 3
    gammaPlot = [];
end

x = [];
y = [];
squishedDelta = cell(1,100);
timePoints = cell(1, 100);
squishedX = cell(1,100);

numDeltas = size(deltaPlot, 2);
trialsToUse = 1:numDeltas;

warpValues = zeros(1, numel(trialsToUse));

deltaCycles = 3; %delta cycles to use

%delta trials
%find 3 delta cycles of first plot
currPhaseDelta = angle(hilbert(deltaPlot(:, 1)));
[~,locs] = findpeaks(currPhaseDelta, 'MinPeakDistance', 100);
currUsePeaks = locs(find(locs > plotPoints(1), deltaCycles + 1));

timePointsOriginal = currUsePeaks(1):currUsePeaks(end);

%get x and y values
for trial = trialsToUse
    
    %find 3 delta cycles of current plot
    currPhaseDelta = angle(hilbert(deltaPlot(:, trial)));
    [~,locs] = findpeaks(currPhaseDelta, 'MinPeakDistance', 100);
    currUsePeaks = locs(find(locs > plotPoints(1), deltaCycles + 1));
    %make timepoints for this trial with same number of peaks as the
    %original
    timePoints{trial} =currUsePeaks(1):currUsePeaks(end);
    
    %maximize the correlation between the first and current deltas
    d1 = deltaPlot(:, 1);
    d2 = deltaPlot(:, trial);
    
    func = @(x, d1, d2, timepoints) -correlDeltaShift(x(1), x(2), d1, d2, timePointsOriginal, timePoints{trial});
    func2 = @(x) func(x, d1, d2, timePoints{trial});
    
    optimalShift = fminsearch(func2, [0, 1]);
    
    
    [~, newSpiketimes, ~, corr2] =...
        correlDeltaShift(optimalShift(1), optimalShift(2), d1, d2, timePointsOriginal, timePoints{trial}, trialSpiketrain{trial} + 1000);
    
    squishedDelta{trial} = corr2;
    currX = newSpiketimes;
    
    x = [x, currX];
    y = [y, trial * ones(size(currX))];
    
    warpValues(trial) = optimalShift(2); %record smoosh
end


barPlotNums = zeros(1, 40);
binLims = linspace(0, timePointsOriginal(end) - timePointsOriginal(1), 41);
%histogram bin numbers
for bin = 1:40
    barPlotNums(bin) = nnz(x < binLims(bin+1) & x > binLims(bin));
end
%delta overlay
for trial = 1:10:numDeltas
    hold on
    plot(1:numel(squishedDelta{trial}), squishedDelta{trial}./max(squishedDelta{trial}) * 5 + 20 + trial, 'color', [0.8500 0.3250 0.0980])
end

%gamma overlay
if(~isempty(gammaPlot))
    plot(-1000:2000, averageGamma/5 - 25, 'color', [0.4660 0.6740 0.1880]);
    plot(-1000:2000, gammaAmp/5 - 25, 'color', [0.4660 0.6740 0.1880], "LineWidth", 1);
    ylim([-60, 120])
end

scatter(x, y + 20, 25, color , 'filled', 's', 'MarkerFaceAlpha',.75);
ylim([-20,120]);
yticks(20:20:120);
yticklabels({0:20:100});

%psth
if(histogramOn)
    bar(binLims(1:end-1), barPlotNums/max(barPlotNums) * 20, 'FaceAlpha', .5, 'FaceColor', color)
end
hold off
end