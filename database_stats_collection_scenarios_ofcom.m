tic;
clear all;
close all;
clc;

%Switch which database you want to query
ofcom_test=1; %Query Ofcom database

%%
%Create legend for the figures
legend_string={'Ofcom'};
legend_flag=ofcom_test ;
legend_string(find(~legend_flag))=[];

%%
%Select which scenario to test
message_size_distribution=0;
response_error_calculation=0;
delay_distribution_per_location=1;
delay_distribution_area=0;

%%
%Plot parameters
ftsz=16;

%%
%Path to save files (select your own)
my_path='/home/amjed/Documents/MATLAB/WSDB_DATA';

%%
%Global Ofcom parameters 
type='"AVAIL_SPECTRUM_REQ"';
height='7.5';

if message_size_distribution==1
    
    %Location of start and finish query
    %Query start location
    WSDB_data{1}.name='BR'; % Bristol
    WSDB_data{1}.latitude='51.517010';
    WSDB_data{1}.longitude='-2.544678';
    WSDB_data{1}.delay_microsoft=[];
    WSDB_data{1}.delay_ofcom=[];
    
    %Query finish location
    WSDB_data{2}.name='LO'; % London UK
    WSDB_data{2}.latitude='51.517010';
    WSDB_data{2}.longitude='-0.094727';
    WSDB_data{2}.delay_microsoft=[];
    WSDB_data{2}.delay_ofcom=[];
    
    longitude_start=str2num(WSDB_data{1}.longitude); %Start of the spectrum scanning trajectory
    longitude_end=str2num(WSDB_data{2}.longitude); %End of spectrum scanning trajectory
    
    longitude_interval=100;
    longitude_step=(longitude_end-longitude_start)/longitude_interval;
    
    delay_ofcom=[];
    
    in=0; %Initialize request number counter
    ggl_cnt=0;
    
    for xx=longitude_start:longitude_step:longitude_end
        in=in+1;
        fprintf('Query no.: %d\n',in)
        
        %Fetch location data
        latitude=WSDB_data{1}.latitude;
        longitude=num2str(xx);
        instant_clock=clock; %Save clock for file name (if both WSDBs are queried)
        if ofcom_test==1
            %Query ofcom
            ggl_cnt=ggl_cnt+1;
            instant_clock=clock; %Start clock again if scanning only one database
            cd([my_path,'/ofcom']);
            [msg_ofcom,delay_ofcom_tmp,error_ofcom_tmp]=database_connect_ofcom(type,latitude,longitude,height,[my_path,'/ofcom'],ggl_cnt);
            var_name=(['ofcom_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
            fprintf('Ofcom\n');
            if error_ofcom_tmp==0
                dlmwrite([var_name,'.txt'],msg_ofcom,'');
                delay_ofcom=[delay_ofcom,delay_ofcom_tmp];
            end
        end
    end
    if ofcom_test==1
        %Clear old query results
        cd([my_path,'/ofcom']);
        %Message size distribution (Ofcom)
        list_dir=dir;
        [rowb,colb]=size({list_dir.bytes});
        ofcom_resp_size=[];
        for x=4:colb
            ofcom_resp_size=[ofcom_resp_size,list_dir(x).bytes];
        end    
    end

    
    %%
    %Plot figure
    if ofcom_test==1
        figure('Position',[440 378 560 420/3]);
        [fg,xg]=ksdensity(ofcom_resp_size,'support','positive');
        fg=fg./sum(fg);
        plot(xg,fg,'g-');
        grid on;
        box on;
        hold on;
        set(gca,'FontSize',ftsz);
        xlabel('Message size (bytes)','FontSize',ftsz);
        ylabel('Probability','FontSize',ftsz);
    end
    legend(legend_string);
    
    %%
    %Calculate statistics of message sizes for each WSDB
    %Mean
    mean_ofcom_resp_size=mean(ofcom_resp_size)
    
    %Variance
    var_ofcom_resp_size=var(ofcom_resp_size)
    
end
if response_error_calculation==1
    
    %Location of start and finish query
    %Query start location
    WSDB_data{1}.name='LO'; %London UK  NEED CHANGED
    WSDB_data{1}.latitude='51.431471';
    WSDB_data{1}.longitude='1';
    WSDB_data{1}.delay_ofcom=[];
    
    %Query finish location
    WSDB_data{2}.name='BR'; % Bristol
    WSDB_data{2}.latitude='51.431471';
    WSDB_data{2}.longitude='-2.577637';
    WSDB_data{2}.delay_ofcom=[];
    
    number_queries=100 
    number_batches=20; 
    
    %Initialize error counter vectors
    error_ofcom_vec=[];
    
    %Initialize Ofcom API request counter [important: it needs initliazed
    %manually every time as limit of 1e3 queries per API is enforced. Check
    %your Ofcom API console to check how many queries are used already]
    ggl_cnt=0;
    
    for bb=1:number_batches
        %Initialize error counters
        error_ofcom=0;
        %Initialize request number counter
        in=0;
        for xx=1:number_queries
            in=in+1;
            fprintf('[Batch no., Query no.]: %d, %d\n',bb,xx)
            
            %Fetch location data
            latitude=WSDB_data{1}.latitude;
            %Generate random longitude for one query
            a=str2num(WSDB_data{1}.longitude);
            b=str2num(WSDB_data{2}.longitude);
            longitude=num2str((b-a)*rand+a);
            
            instant_clock=clock; %Save clock for file name (if both WSDBs are queried)
            if ofcom_test==1
                %Query Ofcom
                ggl_cnt=ggl_cnt+1;
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/ofcom']);
                [msg_ofcom,delay_ofcom_tmp,error_ofcom_tmp]=database_connect_ofcom(type,latitude,longitude,height,[my_path,'/ofcom'],ggl_cnt);
                if error_ofcom_tmp==1
                    error_ofcom=error_ofcom+1;
                end
            end
        end
        if ofcom_test==1
            %Clear old query results
            cd([my_path,'/ofcom']);
            error_ofcom_vec=[error_ofcom_vec,error_ofcom/number_queries];
        end
    end
    if ofcom_test==1
        er_ofcom=mean(error_ofcom_vec)*100
        var_ofcom=var(error_ofcom_vec)*100
    end
end

if delay_distribution_per_location==1
    
    no_queries=50; %Select how many queries per location
    
    %Location data
     WSDB_data{1}.name='DA'; %Darvel
     WSDB_data{1}.latitude='55.624641';
     WSDB_data{1}.longitude='-4.283264';
     WSDB_data{1}.delay_microsoft=[];
     WSDB_data{1}.delay_ofcom=[];
     
     WSDB_data{2}.name='BO'; % Bournemouth
     WSDB_data{2}.latitude='50.748337';
     WSDB_data{2}.longitude='-1.918457';
     WSDB_data{2}.delay_microsoft=[];
     WSDB_data{2}.delay_ofcom=[];
     
     WSDB_data{3}.name='BR'; % Bristol
     WSDB_data{3}.latitude='51.431471';
     WSDB_data{3}.longitude='-2.577637';
     WSDB_data{3}.delay_microsoft=[];
     WSDB_data{3}.delay_ofcom=[];
    
    WSDB_data{4}.name='LO'; %London
    WSDB_data{4}.latitude='51.506753';
    WSDB_data{4}.longitude='-0.127686';
    WSDB_data{4}.delay_microsoft=[];
    WSDB_data{4}.delay_ofcom=[];
    
    WSDB_data{5}.name='CA'; %Cambridge
    WSDB_data{5}.latitude='52.205648';
    WSDB_data{5}.longitude='0.114014';
    WSDB_data{5}.delay_microsoft=[];
    WSDB_data{5}.delay_ofcom=[];
    
    [wsbx,wsby]=size(WSDB_data); %Get location data size
    
    delay_ofcom_vector=[];
    legend_label_ofcom=[];
    
    %Initialize Ofcom API request counter [important: it needs initliazed
    %manually every time as limit of 1e3 queries per API is enforced. Check
    %your Ofcom API console to check how many queries are used already]
    ggl_cnt=25;
    
    for ln=1:wsby
        
        delay_ofcom=[];
        for xx=1:no_queries
            fprintf('[Query no., Location no.]: %d, %d\n',xx,ln)
            
            %Fetch location data
            latitude=WSDB_data{ln}.latitude;
            longitude=WSDB_data{ln}.longitude;
            
            instant_clock=clock; %Save clock for file name (if both WSDBs are queried)
            if ofcom_test==1
                %Query Ofcom
                ggl_cnt=ggl_cnt+1;
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/ofcom']);

                [msg_ofcom,delay_ofcom_tmp,error_ofcom_tmp]=database_connect_ofcom(type,latitude,longitude,height,[my_path,'/ofcom'],ggl_cnt);
                var_name=(['ofcom_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
                
                if error_ofcom_tmp==0
                    dlmwrite([var_name,'.txt'],msg_ofcom,'');
                    delay_ofcom=[delay_ofcom,delay_ofcom_tmp];
              
               
                end
            end
        end
        if ofcom_test==1
            %Clear old query results
            cd([my_path,'/ofcom']);
            
            %Save delay data per location
            WSDB_data{ln}.delay_ofcom=delay_ofcom;
            legend_label_ofcom=[legend_label_ofcom,repmat(ln,1,length(delay_ofcom))]; %Label items for boxplot
     
            
            delay_ofcom_vector=[delay_ofcom_vector,delay_ofcom];


            labels_ofcom(ln)={WSDB_data{ln}.name};

            
            
        end
        end

       
        
    
    %Query general web services for comparison
    delay_ofcom_web=[];
    for xx=1:no_queries
        fprintf('Query no.: %d\n',xx)
        if ofcom_test==1
            dg=connect_webserver(4);
            
            delay_ofcom_web=[delay_ofcom_web,dg];
        end
    end
%     if ofcom_test==1
         legend_label_ofcom=[legend_label_ofcom,repmat(ln,1,length(delay_ofcom_web))]; %Label items for boxplot
         delay_ofcom_vector=[delay_ofcom_vector,delay_ofcom_web];
         

      %   labels_ofcom(ln+1)={'[GL]'};
%     end
    
    %%
    %Plot figure: Box plots for delay per location
    
    %Select maximum Y axis
    max_el=max([delay_ofcom_vector(1:end)]);
    if ofcom_test==1
        figure('Position',[440 378 560/2.5 420/2]);
        boxplot(delay_ofcom_vector,legend_label_ofcom,'labels',labels_ofcom,'symbol','g+','jitter',0,'notch','on','factorseparator',1);
        ylim([0 max_el]);
        set(gca,'FontSize',ftsz);
        ylabel('Response delay (sec)','FontSize',ftsz);
        set(findobj(gca,'Type','text'),'FontSize',ftsz); %Boxplot labels size
        %Move boxplot labels below to avoid overlap with x axis
        txt=findobj(gca,'Type','text');
        set(txt,'VerticalAlignment','Top');
    end
    
    %Reserve axex properties for all figures
    fm=[];
    xm=[];
    fs=[];
    xs=[];
    fg=[];
    xg=[];
    
    if ofcom_test==1
        figure('Position',[440 378 560 420/3]);
        name_location_vector=[];
        for ln=1:wsby
            delay_ofcom=WSDB_data{ln}.delay_ofcom;
            
            %Outlier removal (Ofcom delay)
            outliers_pos=abs(delay_ofcom-median(delay_ofcom))>3*std(delay_ofcom);
            delay_ofcom(outliers_pos)=[];
            
            [fg,xg]=ksdensity(delay_ofcom,'support','positive');
            fg=fg./sum(fg);
            plot(xg,fg);
            hold on;
            name_location=WSDB_data{ln}.name;
            name_location_vector=[name_location_vector,{name_location}];
        end
        %Add plot for general webservice
        
        %Outlier removal (Ofcom delay)
        outliers_pos=abs(delay_ofcom_web-median(delay_ofcom_web))>3*std(delay_ofcom_web);
        delay_ofcom_web(outliers_pos)=[];
        
         name_location_vector=[name_location_vector,'[GL]'];
        
        [fm,xg]=ksdensity(delay_ofcom_web,'support','positive');
        fg=fg./sum(fg);
        plot(xg,fg);
        
        box on;
        grid on;
        set(gca,'FontSize',ftsz);
        xlabel('Response delay (sec)','FontSize',ftsz);
        ylabel('Probability','FontSize',ftsz);
        legend(name_location_vector,'Location','Best');
    

end    
%Set y axis limit manually at the end of plot
ylim([0 max([fg,fm,fs])]);    
end

if delay_distribution_area==1
    
    %Location of start and finish query
    %Query start location
    WSDB_data{1}.name='LO'; %London
    WSDB_data{1}.latitude='51.506753';
    WSDB_data{1}.longitude='-0.127686';
    WSDB_data{1}.delay_ofcom=[];
    
    %Query finish location
    WSDB_data{2}.name='BR'; % Bristol
    WSDB_data{2}.latitude='51.431471';
    WSDB_data{2}.longitude='-2.577637';
    WSDB_data{2}.delay_ofcom=[];
    
    longitude_start=str2num(WSDB_data{1}.longitude); %Start of the spectrum scanning trajectory
    longitude_end=str2num(WSDB_data{2}.longitude); %End of spectrum scanning trajectory
    
    longitude_interval=50;
    longitude_step=(longitude_end-longitude_start)/longitude_interval;
    no_queries=20; %Number of queries per individual location
    
    delay_ofcom=[];
    
    inx=0; %Initialize position counter
    
    %Initialize Ofcom API request counter [important: it needs initliazed
    %manually every time as limit of 1e3 queries per API is enforced. Check
    %your Ofcom API console to check how many queries are used already]
    ggl_cnt=2029;
    
    for xx=longitude_start:longitude_step:longitude_end
        inx=inx+1;
        iny=0; %Initialize query counter
        for yy=1:no_queries
            iny=iny+1;
            fprintf('[Query no., Location no.]: %d, %d\n',iny,inx);
            
            %Fetch location data
            latitude=WSDB_data{1}.latitude;
            longitude=num2str(xx);
            
            instant_clock=clock; %Save clock for file name (if both WSDBs are queried)
            if ofcom_test==1
                %Query Ofcom
                fprintf('Ofcom\n')
                ggl_cnt=ggl_cnt+1;
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/ofcom']);
                [msg_ofcom,delay_ofcom_tmp,error_ofcom_tmp]=...
                    database_connect_ofcom(type,latitude,longitude,height,[my_path,'/ofcom'],ggl_cnt);
                var_name=(['ofcom_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
                if error_ofcom_tmp==0
                    dlmwrite([var_name,'.txt'],msg_ofcom,'');
                    delay_ofcom=[delay_ofcom,delay_ofcom_tmp];
                end
            end
        end
        %%
        %Assign delay per location per WSDB to a new variable
        if ofcom_test==1
            delay_ofcom_loc{inx}=delay_ofcom;
            delay_ofcom=[];
        end
    end
    
    %%
    %Get elavation data
    Elev=[];
    for xx=longitude_start:longitude_step:longitude_end
        pause(0.5); %Ofcom imposes cap on number of queries - delay query %%%% NEED TO CHECKED
        elevation=elevation_google_maps(str2num(latitude),xx);
        Elev=[Elev,elevation];
    end
    
    %%
    %Compute means of queries per location
    if ofcom_test==1
        Vm_ofcom=[];
        for xx=1:inx
            mtmp_ofcom=delay_ofcom_loc{xx};
            Vm_ofcom=[Vm_ofcom,mean(mtmp_ofcom)];
        end
        %Clear old query results
        cd([my_path,'/ofcom']);
        %system('rm *');
    end
    %%
    %Plot distribution curves
    Markers={'g-','b--','k-.'};
    %Plot figures
    if ofcom_test==1
        figure('Position',[440 378 560 420/3]);
        [fg,xg]=ksdensity(Vm_ofcom,'support','positive');
        fg=fg./sum(fg);
        plot(xg,fg,Markers{1});
        hold on;
    end
    
    box on;
    grid on;
    set(gca,'FontSize',ftsz);
    xlabel('Response delay (sec)','FontSize',ftsz);
    ylabel('Probability','FontSize',ftsz);
    legend(legend_string,'Location','Best');
    
    %Plot delay per location curves
    if ofcom_test==1
        figure('Position',[440 378 560 420/3]);
        hold on;
        plot(1:longitude_interval+1,Vm_ofcom./sum(Vm_ofcom),Markers{1});
    end
    
    box on;
    grid on;
    set(gca,'FontSize',ftsz);
    xlim([0 longitude_interval+1]);
    xlabel('Location number','FontSize',ftsz);
    ylabel('Response delay (sec)','FontSize',ftsz);
    legend([legend_string],'Location','Best');
    %legend([legend_string,'Normalized elevation'],'Location','Best');
    
end

%%
['Elapsed time: ',num2str(toc/60),' min']