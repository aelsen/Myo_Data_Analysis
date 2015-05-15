clc; clear; clf; close all; 
format compact;

cc = hsv(20);        % HSV colormap for plot line colors

elecnum = 8;
EMG_Data = {};
cd('R:\Documents\Git\Myo_Data_Analysis\data');
folders = dir();
folders = folders(3:end); 
foldernames = {folders.name};

numvols = 17; %DEBUG

% Initialize figures
for gestnum = 1:numel(folders)
    set(0,'DefaultFigurePosition',[1930, 100, 875, 800]);
    fig_averages{gestnum} = figure('Name',['Gesture: '...
        char(foldernames(gestnum)) ' - EMG Averages'],...
        'NumberTitle','off','Position',[-1920+(1920/4*(gestnum-1))  400 650 710]);
    fig_shifted_averages{gestnum} = figure('Name',['Gesture: '...
    char(foldernames(gestnum)) ' - EMG Averages'],...
    'NumberTitle','off','Position',[-1920+(1920/4*(gestnum-1))  0 650 710]);
%     fig_interp{gestnum} = figure('Name',['Gesture: '...
%         char(foldernames(gestnum)) ' - EMG Interpolated Data'],...
%         'NumberTitle','off','Position',[-1920+(1920/4*(gestnum-1))  400 650 710]);
%     fig_shifted{gestnum} = figure('Name',['Gesture: '...
%         char(foldernames(gestnum)) ' - EMG Interpolated Data'],...
%         'NumberTitle','off','Position',[-1920+(1920/4*(gestnum-1))  400 650 710]);
%     legend_samples{volunteer} = {};
end

% Retrieve and package folder data
disp([num2str(numel(folders)) ' folders found.'])
disp('Harvesting data.')
for gestnum = 1: numel(folders)
    foldernamesch{gestnum} = char(foldernames(gestnum));
    dirname = ['R:\Documents\Git\Myo_Data_Analysis\data\' foldernamesch{gestnum}...
        '\!postprocessing\data.mat'];
    S = load(dirname);
    F{gestnum} = S;
    
end
Folder_Data = struct('Name',foldernamesch,'Data',F);
clearvars S foldernames

for gestnum = 1: numel(folders)
    name = getfield(Folder_Data(gestnum),'Name');
    data = getfield(Folder_Data(gestnum),'Data');
    filenum{gestnum} = getfield(data,'filenum');
    Interp_Elec{gestnum} = getfield(data,'Interp_Elec');
    Mean{gestnum} = getfield(data,'Mean');
    vol_folds{gestnum} = getfield(data,'folders');
    volunteers = {vol_folds{gestnum}.name};
    legend_samples{gestnum} = getfield(data,'legend_samples');
end
Means = struct('Name',foldernamesch,'Mean',Mean);
% numvols = numel(volunteers);




% % Combine all data into one cell array, per gesture
% disp('Combining Data.')
% for gestnum = 1:numel(folders)
%     disp(['Transferring interpolated data from gesture #' num2str(gestnum) '.'])
%     for elec = 1:elecnum
%         samplecount = 1;
%         for volunteer = 1:numvols
%             for samp = 1:filenum{gestnum}{volunteer}
%                 for elem = 1:numel(Interp_Elec{gestnum}{volunteer}{samp}(:,elec))
%                     EMG_Data{gestnum}{elec}(elem,samplecount) = Interp_Elec{gestnum}{volunteer}{samp}(elem,elec);
%                 end
%                 samplecount = samplecount + 1;
%             end
%         end
%     end
%     totalsamples = samplecount
% end
% save('R:\Documents\Git\MYO-Python\scripts_analysis\EMG_Data.mat', 'EMG_Data')

load('R:\Documents\Git\Myo_Data_Analysis\Paper_Assets\matlab\EMG_Data.mat')

% Signal Analysis =====================================================



% disp('Correlating all samples, for each gesture.')
% for gestnum = 1:numel(folders)
%     disp(['     Correlating data for gesture #' num2str(gestnum) '.'])
%     PI{gestnum} = []; % peak indeces
%     Correlations{gestnum} = {};
%     Lags{gestnum} = {};
%     Zeroshift{gestnum} = {};
%     minshift{gestnum} = zeros(1,elecnum);
%     for volunteer = 1:numvols;
%         % Determine shift necessary to align signals
%         for elec = 1:elecnum
%             dims = size(EMG_Data{gestnum}{elec});
%             dims(2);
%             for samp = 1:dims(2)%filenum{volunteer}
%             
%                 % Calculate correlation and lag
%                 [Correlations{gestnum}{elec}(:,samp), Lags{gestnum}{elec}(:,samp)]...
%                     = xcorr(EMG_Data{gestnum}{elec}(:,1), EMG_Data{gestnum}{elec}(:,samp), 'coeff');
% 
%                 % Calculate peak indeces
%                 [~,PI{gestnum}(samp,elec)] = max(abs(Correlations{gestnum}{elec}(:,samp))); 
%                 Zeroshift{gestnum}{elec}(:,samp) = Lags{gestnum}{elec}(PI{gestnum}(samp,elec),samp);
%                 zshift = Zeroshift{gestnum}{elec}(:,samp);
%                 if Zeroshift{gestnum}{elec}(:,samp) < minshift{gestnum}(elec)
%                     minshift{gestnum}(elec) = zshift;
%                 end
%             end
%         end
%     end
% 
%     % Shift All signals
%     disp(['     Shifting data for gesture #' num2str(gestnum) '.'])
%     for elec = 1:elecnum
%         dims = size(EMG_Data{gestnum}{elec});
%         dims(2);
%         for samp = 1:dims(2) %filenum{volunteer}
%             if samp ==1 % Shift sample 1
%                 numzeros = abs(minshift{gestnum}(elec));
%                 shiftedcorr = [zeros(numzeros,1); Correlations{gestnum}{elec}(:,samp)];
%                 shiftedarray = [zeros(numzeros,1); EMG_Data{gestnum}{elec}(:,samp)];
%             else % Shift other samples
%                 numzeros = abs(abs(Zeroshift{gestnum}{elec}(:,samp)) + minshift{gestnum}(elec));
%                 shiftedcorr = [zeros(numzeros,1); Correlations{gestnum}{elec}(:,samp)];
%                 shiftedarray = [zeros(numzeros,1); EMG_Data{gestnum}{elec}(:,samp)];
%             end
%             % Add shifted Data{volunteer} to Data{volunteer} array
%             ss = size(shiftedarray);
%             for Datapt = 1:ss(1)
%                 Data{gestnum}{elec}(Datapt,samp) = shiftedarray(Datapt);
%             end
%             ss = size(shiftedcorr); 
%             for Datapt = 1:ss(1)
%                 Shifted_Corr{gestnum}{elec}(Datapt,samp) = shiftedcorr(Datapt);
%             end
%         end
%     end
% end
% disp('Saving correlated data.')
% save('R:\Documents\Git\MYO-Python\scripts_analysis\Corr_Data.mat', 'Correlations')
% save('R:\Documents\Git\MYO-Python\scripts_analysis\Shifted_Data.mat', 'Data')
% clearvars Correlations Shifted_Corr Lags...
%     shiftedcorr shiftedarray  Zeroshift

 disp('Correlating all averages, for each gesture.')
for gestnum = 1:numel(folders)
    disp(['     Correlating averages for gesture #' num2str(gestnum) '.'])
    PI{gestnum} = []; % peak indeces
    Correlations{gestnum} = {};
    Lags{gestnum} = {};
    Zeroshift{gestnum} = {};
    minshift{gestnum} = zeros(1,elecnum);
    
    % Determine shift necessary to align signals ==========================
    % Calculate max length of average signals
    maxlength = 0;
    for elec = 1:elecnum
        for volunteer = 1:numvols;
            dims = size(Mean{gestnum}{volunteer});
            length = dims(1);
            if length > maxlength
                maxlength = length;
            end
        end
    end
    % Add zeroes, then correlate
    for elec = 1:elecnum
        for volunteer = 1:numvols;
            % Add zeroes;
            temp_size = size(Mean{gestnum}{volunteer}); temp_length = temp_size(1);
            if temp_length < maxlength
                diff = maxlength - temp_length;
                counter = 1;
                while counter <= diff
                    Mean{gestnum}{volunteer}(temp_length+counter,elec) = 0;
                    counter = counter + 1;
                end
            end
            
            % Calculate correlation and lag
            [Correlations{gestnum}{volunteer}(:,elec), Lags{gestnum}{volunteer}(:,elec)]...
                = xcorr(Mean{gestnum}{1}(:,elec), Mean{gestnum}{volunteer}(:,elec), 'coeff');

            % Calculate peak indeces
            [~,PI{gestnum}(volunteer,elec)] = max(abs(Correlations{gestnum}{volunteer}(:,elec))); 
            Zeroshift{gestnum}{volunteer}(:,elec) = Lags{gestnum}{volunteer}(PI{gestnum}(volunteer,elec),elec);
            zshift = Zeroshift{gestnum}{volunteer}(:,elec);
            if Zeroshift{gestnum}{volunteer}(:,elec) < minshift{gestnum}(elec)
                minshift{gestnum}(elec) = zshift;
            end
        end
    end

    % Shift All signals
    disp(['     Shifting averages for gesture #' num2str(gestnum) '.'])
    for elec = 1:elecnum
        dims = size(Mean{gestnum});
        dims(2);
        for volunteer = 1:dims(2) %filenum{volunteer}
            if volunteer == 1 % Shift averages from volunteer 1
                numzeros = abs(minshift{gestnum}(elec));
                shiftedcorr = [zeros(numzeros,1); Correlations{gestnum}{volunteer}(:,elec)];
                shiftedarray = [zeros(numzeros,1); Mean{gestnum}{volunteer}(:,elec)];
            else % Shift averages from other volunteers
                numzeros = abs(abs(Zeroshift{gestnum}{volunteer}(:,elec)) + minshift{gestnum}(elec));
                shiftedcorr = [zeros(numzeros,1); Correlations{gestnum}{volunteer}(:,elec)];
                shiftedarray = [zeros(numzeros,1); Mean{gestnum}{volunteer}(:,elec)];
            end
            % Add shifted Data{volunteer} to Data{volunteer} array
            ss = size(shiftedarray);
            for Datapt = 1:ss(1)
                Means_Shifted{gestnum}{volunteer}(Datapt,elec) = shiftedarray(Datapt);
            end
            ss = size(shiftedcorr); 
            for Datapt = 1:ss(1)
                Shifted_Corr{gestnum}{volunteer}(Datapt,elec) = shiftedcorr(Datapt);
            end
        end
    end
    
    % Average shifted averages
    disp('      Calculating mean of means.')
    temp = {};
    for elec = 1:elecnum
        dims = size(Mean{gestnum});
        dims(2);
        for volunteer = 1:dims(2) %filenum{volunteer}
            tempcol = Means_Shifted{gestnum}{volunteer}(:,elec);
            for elem = 1:numel(tempcol)
                Temp_Array{gestnum}{elec}(elem,volunteer) = tempcol(elem);
            end
            clearvars tempcol;
        end
    end
    for elec = 1:elecnum
        Temp_Mean = mean(Temp_Array{gestnum}{elec}(:,volunteer),2);
        for elem = 1:numel(Temp_Mean)
            Master_Mean{gestnum}{volunteer}(:,elec) = Temp_Mean;
        end
        clearvars Temp_Mean;
    end
end
% disp('Saving correlated data.')
% save('R:\Documents\Git\MYO-Python\scripts_analysis\Corr_Data.mat', 'Correlations')
% save('R:\Documents\Git\MYO-Python\scripts_analysis\Shifted_Data.mat', 'Data')
clearvars Correlations Shifted_Corr Lags...
    shiftedcorr shiftedarray  Zeroshift

% Plotting ===========================================================
disp('Plotting Data.')


for gestnum = 1: numel(folders)
% For each gesture, plot emg averages of each volunteer against eachother
    disp(['     Plotting unshifted averages for gesture #' num2str(gestnum) '.'])
    figure(fig_averages{gestnum});
    for volunteer = 1:numvols
        for elec = 1:elecnum %filenum{volunteer}
            hold on;
            subplot(4,2,elec)
            toplot = getfield(Means(gestnum),'Mean');
            plot(toplot{volunteer}(:,elec),'color',cc(volunteer,:))
            title(['Electrode ',num2str(elec)]);
            hold off;
        end
    end
    legend(volunteers);
    
    % For each gesture, plot shifted averages of each volunteer against eachother
    disp(['     Plotting shifted averages for gesture #' num2str(gestnum) '.'])
    figure(fig_shifted_averages{gestnum});
    for elec = 1:elecnum %filenum{volunteer}
        hold all;
        subplot(4,2,elec)
        hold all;
        for volunteer = 1:numvols
            plot(Means_Shifted{gestnum}{volunteer}(:,elec),'color',cc(volunteer,:))
        end
        plot(Master_Mean{gestnum}{volunteer}(:,elec),'color','black')
        title(['Electrode ',num2str(elec)]);
    end
    mean_legend = volunteers; 
    mean_legend{1,numel(volunteers)+1} = 'Mean';
    legend(mean_legend);

%   For each gesture, plot all interpolated emg signals 
%       of each volunteer against eachother
%     disp(['         Plotting interpolated data for gesture ' num2str(gestnum) '.'])
%     figure(fig_interp{gestnum});
%     for volunteer = 1:numvols
%         disp(['             Plotting data from volunteer ' num2str(volunteer) '.'])
%         for elec = 1:elecnum %filenum{volunteer}
%             for samp = 1:filenum{gestnum}{volunteer}
%                 hold on;
%                 subplot(4,2,elec)
%                 title(['Electrode ',num2str(elec)]);
%                 plot(Interp_Elec{gestnum}{volunteer}{samp}(:,elec),'color',cc(samp,:))
%                 hold off;
%             end
%             xlabel('Time (ms)')
%             ylabel('Amplitude')
%         end
%     end
%     legend(volunteers);

%     % Plot Interpolated Data
%     figure(fig_interp{gestnum})
%     for elec = 1:elecnum %filenum{volunteer}
%         for samp = 1:filenum{volunteer}
%             hold on;
%             subplot(4,2,elec)
%             title(['Electrode ',num2str(elec)]);
%             plot(Interp_Elec{volunteer}{samp}(:,elec),'color',cc(samp,:))
%             hold off;
%         end
%         xlabel('Time (ms)')
%         ylabel('Amplitude')
%     end
%     legend(legend_samples{volunteer}{1,:});

    % Plot Shifted Data
%     disp(['Plotting for gesture ' num2str(gestnum) '.'])
%     figure(fig_shifted{gestnum})
%     for elec = 1:elecnum %filenum{volunteer}
%         disp(['     Plotting electrode ' num2str(elec) '.'])
%         dims = size(EMG_Data{gestnum}{elec});
%         dims(2);
%         for samp = 1:dims(2)
% %             disp(['Plotting sample ' num2str(samp) '.'])
%             hold on;
%             subplot(4,2,elec)
%             title(['Electrode ',num2str(elec)]);
%             plot(Data{gestnum}{elec}(:,samp))
%             hold off;
%         end
%         xlabel('Time (ms)')
%         ylabel('Amplitude')
%     end
%     legend(legend_samples{volunteer}{1,:});
end

cd('R:\Documents\Git\Myo_Data_Analysis\scripts_analysis');
disp('Done.')