function [SVDout, SpatialAmp, SpatialPhase, TemporalAmp, TemporalPhase,GridOut ] = WaveSVD(data, N, Grid, BadChannels, Channels)
%UNTITLED2 Summary of this function goes here
% data is space by time matrix;
%  N is the number of components to take. 
% Grid is an array where every element is the position
% of an electrode in the array. 
% Channels is the total number of channels.
% BadChannels are missing or noisy channels. It is assumed that those were
% eliminated from data.

H=zeros(size(data));
for i=1:size(data,1)
   H(i,:)=hilbert(data(i,:)); 
end
    [U, S,V]=svd(H);
    SVDout.U=U;
    SVDout.S=S;
    SVDout.V=V;
    % now lets compute the spatial modes
    A=U*S;
    A=A(:, 1:N);                % only take N-modes
    SpatialAmp=real(A);
    SpatialPhase=angle(A);
    B=V*S';
    B=B(:,1:N);             % only take N-modes
    TemporalAmp=real(B);
    TemporalPhase=angle(B);
    %% now we can plot the modes onto electrode grid.
    goodChannels=setdiff(1:Channels, BadChannels);
    rows=[];
    columns=[];
        for i=1:length(goodChannels)
           [r,c]=find(Grid==goodChannels(i));       % identify positions of all electroes. 
           rows(end+1)=r;
           columns(end+1)=c;
        end
     GridOut.data=rearrangeData(data, rows, columns, Grid);   
     GridOut.SpatialAmp=rearrangeData(SpatialAmp, rows, columns, Grid); 
     GridOut.SpatialPhase=rearrangeData(SpatialPhase, rows, columns, Grid); 

        
    function [X]=rearrangeData(D, row, column, GR)
        % identify which dimension is space
       
        SpaceDim=find(size(D)==size(data,1));          % identify space dimension in D
        TimeDim=setdiff(1:2, SpaceDim);                % the other dimension is "time"
        X=NaN(size(GR,1), size(GR,2), size(D,TimeDim));
        % now iterate over space dimension
        for ii=1:size(D, SpaceDim)
            if SpaceDim==1
                X(row(ii), column(ii), :)=D(ii,:);
            elseif SpaceDim==2
                 X(row(ii), column(ii), :)=D(:,ii);
            end
        end        
    end

        
        
end

