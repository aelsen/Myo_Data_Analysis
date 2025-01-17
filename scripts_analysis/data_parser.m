clc; clear; clf; close all; 
format compact;

% Initialize Variables
% ------------------------------------------------------------------------
cc = hsv(10);        % HSV colormap for plot line colors
Time = {};          % {sample}(tick,:)
Raw_Data = {};      % {sample}(tick,electrode)
Data = {};
Mean_Unshifted = {};
Mean = {};
spr = 3; spc = 2;
elecnum = 8;

% Gather all original Data{volunteer} files in dir, create array of filenames.
cd('R:\Documents\Git\MYO-Python\data\WaveLeft');
folders = dir();

startindex = 0;
for folder = 1:numel(folders)
    if strcmp(char(folders(folder).name),'!postprocessing')
        startindex = folder;
        break
    end
end
folders = folders(startindex+1:end);
folders = folders(3:end); 
foldernames = {folders.name};
disp([num2str(numel(folders)) ' folders found.'])

% Initialize figures
for volunteer = 1:numel(folders)
    set(0,'DefaultFigurePosition',[1930, 100, 875, 800]);
%     fig_interp{volunteer} = figure('Name',['Volunteer #' num2str(volunteer) ' - '...
%         char(foldernames(volunteer)) ' - EMG Data'],'NumberTitle','off','Position',[-1300  400 650 710]);
    % fig_uninterp_mean = figure('Name','EMG Data{volunteer} - Mean_Data{volunteer}','NumberTitle','off');
%     fig_shifted{volunteer} = figure('Name',['Volunteer #' num2str(volunteer) ' - '...
%         char(foldernames(volunteer)) ' - EMG Data - Shifted'],'NumberTitle','off','Position',[-650 400 650 710]);
%     fig_MC{volunteer} = figure('Name',['Volunteer #' num2str(volunteer) ' - '...
%         char(foldernames(volunteer)) ' - EMG Data - Correlated with Mean, Shifted'],'NumberTitle','off','Position',[-650 400 650 710]);
%     fig_mean{volunteer} = figure('Name',['Volunteer #' num2str(volunteer) ' - '...
%         char(foldernames(volunteer)) ' - EMG Data - Mean_Data{volunteer}'],'NumberTitle','off','Position',[-1920  400 650 710]);
%     legend_samples{volunteer} = {};
end

disp('Processing data.')
% ------------------------------------------------------------------------
for volunteer = 1:numel(folders)
    disp(['     ' 'Processing data from volunteer #' num2str(volunteer) ', ' char(foldernames(volunteer)) '.'])
%     disp(['         ' 'Opening folder "' char(foldernames(volunteer)) '".'])
    oldfolder = cd(char(foldernames(volunteer)));
    % HARVEST Data{volunteer} -----------------------------------------------------------
    files = dir('*.csv');
    files = {files.name};
    files = files';
    filenum{volunteer} = numel(files);
    % newfilename = 'allData{volunteer}.xlsx';
    for fileiter = 1:filenum{volunteer} % Iterate through all files in dir
        % Open files
        name = cellstr(files(fileiter,:));
        legend_samples{volunteer}{fileiter} = ['Sample ' num2str(fileiter)];


        filec = char(files(fileiter));
        fid = fopen(filec,'r');

        % Scan page of one file
        fs = textscan(fid, repmat('%s',1,10), 'delimiter',',', 'CollectOutput',true);
        fs = fs{1};
        fssize = size(fs);
        if fssize(1) == 0;
            delete(filec);
            return
        end



        % HARVEST Time{volunteer} ------------------------------
        t=1;
        % Ensure first row is the correct format. If not, remove row.
        firstchar=char(fs{1,1}); charray=strfind(firstchar, ':'); 
        chs = size(charray);
        if  chs(1) == 0
            fs = fs(2:end,:);
        end
        for row = 1:numel(fs(:,1)) % Iterate through the rows in col 1
            % Change format from cell > str, then split
            tempchar = char(fs{row,1});
            Timearrays = strsplit(tempchar, ':');

            % Convert to seconds
            valseconds = str2double(char(Timearrays(3))) + str2double(char(Timearrays(4)))/1000000;

            Time{volunteer}{fileiter}(t,:) = valseconds;
            % Check to make sure value is not 0.
    %         if Time{volunteer}(t, fileiter) == 0
    %             if t > 1
    %                 Time{volunteer}(t, fileiter) = Time{volunteer}(t-1, fileiter)
    %             end
    %         end
            t = t+1;
        end

        % HARVEST ELECTRODE Data{volunteer} ------------------------------
        for col = 2:(numel(fs(1,:))-1) % For every electrode (ever col after the first)
            for row = 1:numel(fs(:,1)) %Iterate through every row
                Raw_Data{volunteer}{fileiter}(row, col-1) = str2double(fs{row, col}); % Add Data{volunteer} to col pertaining to file #
            end
        end 
    end
    fclose('all');
    clearvars col row t;
    clearvars files filec fileiter fid fssize;
    clearvars Time{volunteer}arrays tempchar charray chs valseconds firstchar;

%     disp(['         ' 'numel(filenum{volunteer}): ' num2str(numel(filenum{volunteer}))])
    % Clean up Time{volunteer} Data{volunteer} -----------------------------------------------------
    for col = 1:numel(filenum{volunteer}) % For every sample
        % Shift all Time{volunteer} arrays to begin at zero.
        firstval = Time{volunteer}{col}(1,:);
        Time{volunteer}{col} = Time{volunteer}{col} - firstval;

        % Remove faulty (negative, >3) Time{volunteer} values 
        for row = 2:numel(Time{volunteer}{col})
            lastindex = -1;
            % Ensure values are increasing; if not, replace next val.
            if Time{volunteer}{col}(row,1) < 0
                lastindex = row;
                break;
            end
            if Time{volunteer}{col}(row,1) > 3
                lastindex = row;
                break;
            end
        end
        if lastindex > 0
                Time{volunteer}{col} = Time{volunteer}{col}(1:lastindex-1,:);
                Raw_Data{volunteer}{col} = Raw_Data{volunteer}{col}(1:lastindex-1,:);
        end
    end
    clearvars firstval lastindex col row;


    % Signal Analysis =====================================================
    Interp_Elec{volunteer} = {};
    Interp_Time{volunteer} = {};
    interpnum = 3000;

    % Interpolate Data{volunteer}
    for samp = 1:filenum{volunteer} % For each electrode %% DEBUG
        for elec = 1:elecnum %filenum{volunteer}  % For each sample
            % Interpolate Data{volunteer} -> variable sample rate to nonvariable
            x = Time{volunteer}{samp};
            xi = linspace(min(Time{volunteer}{samp}), max(Time{volunteer}{samp}), interpnum)';
            y = Raw_Data{volunteer}{samp}(:,elec);
            yi = interp1(x,y,xi);

            Interp_Time{volunteer}{samp}(:,elec) = xi;
            Interp_Elec{volunteer}{samp}(:,elec) = yi;
        end
    end

    % Correlate and shift, using first sample as baseline ================
    disp('          Correlating and shifting signals vs 1st.')
    PI = []; % peak indeces
    Timediff = [];      % [Sampnum , electrode]
    Correlations{volunteer} = {};
    Lags = {};
    Zeroshift = {};
    minshift(elecnum) = 0;

    % Determine shift necessary to align signals
    for samp = 1:filenum{volunteer} %filenum{volunteer}
        for elec = 1:elecnum
            % Calculate correlation and lag
            [Correlations{volunteer}{samp}(:,elec), Lags{samp}(:,elec)]... 
                = xcorr(Interp_Elec{volunteer}{1}(:,elec), Interp_Elec{volunteer}{samp}(:,elec), 'coeff');

            % Calculate peak indeces
            [~,PI(samp,elec)] = max(abs(Correlations{volunteer}{samp}(:,elec))); 
            Zeroshift{samp}(:,elec) = Lags{samp}(PI(samp,elec),elec);
            zshift = Zeroshift{samp}(:,elec);
            if Zeroshift{samp}(:,elec) < minshift(elec)
                minshift(elec) = zshift;
            end
        end
    end

    % Shift All signals
    for samp = 1:filenum{volunteer} %filenum{volunteer}
        for elec = 1:elecnum
            if samp ==1 % Shift sample 1
                numzeros = abs(minshift(elec));
                shiftedcorr = [zeros(numzeros,1); Correlations{volunteer}{samp}(:,elec)];
                shiftedarray = [zeros(numzeros,1); Interp_Elec{volunteer}{samp}(:,elec)];
            else % Shift other samples
                numzeros = abs(abs(Zeroshift{samp}(:,elec)) + minshift(elec));
                shiftedcorr = [zeros(numzeros,1); Correlations{volunteer}{samp}(:,elec)];
                shiftedarray = [zeros(numzeros,1); Interp_Elec{volunteer}{samp}(:,elec)];
            end
            % Add shifted Data{volunteer} to Data{volunteer} array
            ss = size(shiftedarray);
            for datapt = 1:ss(1)
                Data{volunteer}{samp}(datapt,elec) = shiftedarray(datapt);
            end
            ss = size(shiftedcorr); 
            for datapt = 1:ss(1)
                Shifted_Corr{volunteer}{samp}(datapt,elec) = shiftedcorr(datapt);
            end
        end
    end

    % Average shifted signals
    disp('          Calculating mean.')
    temp = {};
    for samp = 1:filenum{volunteer} %filenum{volunteer}
        for elec = 1:elecnum
            tempcol = Data{volunteer}{samp}(:,elec);
            for elem = 1:numel(tempcol)
                temp{elec}(elem,samp) = tempcol(elem);
%                 Data2{volunteer}{samp}(:,elec)
            end
        end
    end
    for elec = 1:elecnum
        meanofrows = mean(temp{elec},2);
        for elem = 1:numel(meanofrows)
            Mean_Unshifted{volunteer}(:,elec) = meanofrows;
        end
    end
    clearvars Correlations Shifted_Corr Lags temp fs...
    shiftedcorr shiftedarray tempcol meanofrows xi yi Zeroshift x y
    
    
    % Save Variables
    %   Save means
    %   Save shifted data
    
    
    
    % Correlate and shift, using mean as baseline ========================
    disp('          Correlating and shifting signals vs mean.')
%     PI_MC = []; % peak indeces
%     Timediff_MC = [];      % [Sampnum , electrode]
%     Correlations_MC{volunteer} = {};
%     Lags_MC = {};
%     Zeroshift_MC = {};
    minshift_MC(elecnum) = 0;

    % Determine shift necessary to align signals
    for samp = 1:filenum{volunteer} %filenum{volunteer}
        for elec = 1:elecnum
            
            % Add zeroes
            mean_size = size(Mean_Unshifted{volunteer}(:,elec)); mean_length = mean_size(1);
            temp_size = size(Data{volunteer}{samp}(:,elec)); temp_length = temp_size(1);
            if temp_length < mean_length
                diff = mean_length - temp_length;
                counter = 1;
                while counter <= diff
                    Data{volunteer}{samp}(temp_length+counter,elec) = 0;
                    counter = counter + 1;
                end
            end
            
            % Calculate correlation and lag
            [Correlations_MC{volunteer}{samp}(:,elec), Lags_MC{samp}(:,elec)]... 
                = xcorr(Mean_Unshifted{volunteer}(:,elec), Data{volunteer}{samp}(:,elec), 'coeff');
            % Calculate peak indeces
            [~,PI_MC(samp,elec)] = max(abs(Correlations_MC{volunteer}{samp}(:,elec))); 
            Zeroshift_MC{samp}(:,elec) = Lags_MC{samp}(PI_MC(samp,elec),elec);
            zshift = Zeroshift_MC{samp}(:,elec);
            if Zeroshift_MC{samp}(:,elec) < minshift_MC(elec)
                minshift_MC(elec) = zshift;
            end
        end
    end

    % Shift All signals
    for samp = 1:filenum{volunteer} %filenum{volunteer}
        for elec = 1:elecnum
            numzeros = abs(minshift_MC(elec));
            shiftedmean = [zeros(numzeros,1); Mean_Unshifted{volunteer}(:,elec)];
            % Shift other samples
            numzeros = abs(abs(Zeroshift_MC{samp}(:,elec)) + minshift_MC(elec));
            shiftedcorr_MC = [zeros(numzeros,1); Correlations_MC{volunteer}{samp}(:,elec)];
            shiftedarray_MC = [zeros(numzeros,1); Data{volunteer}{samp}(:,elec)];

            % Add shifted Data{volunteer} to Data{volunteer} array
            ss = size(shiftedarray_MC);
            for datapt = 1:ss(1)
                Data_MC{volunteer}{samp}(datapt,elec) = shiftedarray_MC(datapt);
                
            end
            ss = size(shiftedmean);
            for datapt = 1:ss(1)
                Mean{volunteer}(datapt,elec) = shiftedmean(datapt);
            end
            ss = size(shiftedcorr_MC); 
            for datapt = 1:ss(1)
                Shifted_Corr_MC{volunteer}{samp}(datapt,elec) = shiftedcorr_MC(datapt);
            end
            
            [Max_Corr{volunteer}{samp}(:,elec),Max_index{volunteer}{samp}(:,elec)] =...
                max(Shifted_Corr_MC{volunteer}{samp}(:,elec));
        end
    end
    
    disp('          Calculating mean and std of correlated data.')
    % Reshape Max Corr Matrix
    for samp = 1:filenum{volunteer} %filenum{volunteer}
        for elec = 1:elecnum
            Data_Correlation{volunteer}(samp, elec) = Max_Corr{volunteer}{samp}(:,elec);
        end

    end
    for elec = 1:elecnum
        Data_Corr_Mean(volunteer,elec) = mean(Data_Correlation{volunteer}(:, elec));
        Data_StD(volunteer,elec) = std(Data_Correlation{volunteer}(:, elec));
    end
    disp('          Saving variables.')
    save('Mean_Correlated.mat', 'Mean','Data');
    save('Max_Correlation_vs_Mean.mat', 'Data_Correlation','Data_StD','Data_Corr_Mean');
    clearvars Correlations Lags_MC shiftedcorr_MC shiftedarray_MC...
        Zeroshift_MC Shifted_Corr_MC Correlations_MC Data Mean_Unshifted Raw_Data shiftedmean
    

    % Plotting ===========================================================
    % Plot Interpolated Data
%     figure(fig_interp{volunteer})
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
%     
% 
%     % Plot Shifted Data
%     figure(fig_shifted{volunteer})
%     for elec = 1:elecnum %filenum{volunteer}
%         for samp = 1:filenum{volunteer}
%             hold on;
%             subplot(4,2,elec)
%             title(['Electrode ',num2str(elec)]);
%             plot(Data{volunteer}{samp}(:,elec),'color',cc(samp,:))
%             hold off;
%         end
%         xlabel('Time (ms)')
%         ylabel('Amplitude')
%     end
%     legend(legend_samples{volunteer}{1,:});
%     
% 
%     % Plot Mean_Data{volunteer} shifted Data
%     figure(fig_mean{volunteer})
%     for elec = 1:elecnum %filenum{volunteer}
%         hold on;
%         subplot(4,2,elec)
%         plot(Mean_Unshifted{volunteer}(:,elec),'color','black')
%         title(['Electrode ',num2str(elec)]);
%         hold off;
%     end
%     legend('Signal Average');
% 
%     % Plot Mean-Correlated Shifted Data
%     figure(fig_MC{volunteer})
%     for elec = 1:elecnum %filenum{volunteer}
%         hold on;
%         for samp = 1:filenum{volunteer}
%             hold on;
%             subplot(4,2,elec)
%             title(['Electrode ',num2str(elec)]);
%             plot(Data_MC{volunteer}{samp}(:,elec),'color',cc(samp,:))
%             
%         end
%         subplot(4,2,elec);
%         plot(Mean{volunteer}(:,elec),'color','black')
%         xlabel('Time (ms)')
%         ylabel('Amplitude')
%     end
%     mean_legend{volunteer} = legend_samples{volunteer}; 
%     mean_legend{volunteer}{1,filenum{volunteer}+1} = 'Mean';
%     legend(mean_legend{volunteer});





%    ----------------------------------------------------------
%     % Plot shifted Data{volunteer} and Correlations{volunteer}
%     for elec = 1:elecnum
%         figures(elec) = figure('Name',strcat('EMG ',num2str(elec),' Data{volunteer}'),'NumberTitle','off','Position',[1930, 0, 875, 800]); 
%     end
%     for elec = 1:elecnum %filenum{volunteer}
%         figure(figures(elec))
%         % Set up subplots
%         hold on; subplot(spr,spc,1); hold all;
%         subplot(spr,spc,2); hold on;
%         subplot(spr,spc,3); hold on;
%             plot(Mean_Data{volunteer}(:,elec),'color','black')
%         subplot(spr,spc,4); hold on;
%         subplot(spr,spc,5); hold on;
%             plot(Mean_Data{volunteer}(:,elec),'color','black')
% 
%         for samp = 1:filenum{volunteer}
%             % Plot Correlations{volunteer}, Shifted Correlations{volunteer}, and Shifted Data{volunteer}
%             subplot(spr,spc,1)
%             plot(Interp_Time{volunteer}{samp}(:,elec),Interp_Elec{volunteer}{samp}(:,elec),'color',cc(samp,:))
%             subplot(spr,spc,2)
%             plot(Correlations{volunteer}{samp}(:,elec),'color',cc(samp,:))
%             subplot(spr,spc,3)
%             plot(Data{volunteer}{samp}(:,elec),'color',cc(samp,:)) 
%             subplot(spr,spc,4)
%             plot(Shifted_Corr{volunteer}{samp}(:,elec),'color',cc(samp,:))
%         end
%         subplot(spr,spc,1); xlim([0,3]); title('Unshifted Data{volunteer}'); xlabel('Time{volunteer} (seconds)')
%         subplot(spr,spc,2); xlim([0,6000]); title('Unshifted Correlation'); 
%         subplot(spr,spc,3); xlim([0,3000]); title('Shifted Data{volunteer}'); xlabel('Time{volunteer} (ms)')
%         subplot(spr,spc,4); xlim([0,6000]); title('Shifted Data{volunteer} Correlation'); 
%         subplot(spr,spc,5); xlim([0,3000]); title('Shifted Data{volunteer} Average'); xlabel('Time{volunteer} (ms)')  
%         hold off;
%     end
    cd(oldfolder)
end
disp('Processing complete.')

% disp('Saving figures.')
% for volunteer = 1:numel(folders)
%     name = char(foldernames(volunteer));
%     disp(['         ' 'Saving figures for ' name])
% %     savefig(fig_interp{volunteer},[name '\' name '_Interp'])
% %     savefig(fig_shifted{volunteer},[name '\' name '_Shifted'])
% %     savefig(fig_mean{volunteer},[name '\' name '_Mean']);
%     savefig(fig_MC{volunteer},[name '\' name '_Shifted_MeanCorrelated']);
% end

disp('Saving variables.')
clearvars fig_interp fig_mean fig_shifted
mkdir('!postprocessing');
save('!postprocessing\data');

% disp('Saving complete.')
disp('Done.')

cd('R:\Documents\Git\MYO-Python\scripts_analysis');
