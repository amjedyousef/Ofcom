tic; 
clear; 
close all; 
clc;
%%
%Path to save files (select your own)
my_path='/home/amjed/Documents/Gproject/workspace/data/WSDB_DATA';
%%
num_of_steps = [1 2 4 8]% 16 32 64 128 256]; 
distance_divider =  num_of_steps(length(num_of_steps));
fileId = 0 ;
num_of_query_per_location = 10;
%%
    %The data stored in the file as longitude latitude longitude latitude
    format long;
    long_lat_ofcom = load('long_lat_ofcom.txt');
    [r ,c] = size(long_lat_ofcom);
    delay_ofcom_vec = [];
  
for k=1:r    
        %Location data    
        long_start= long_lat_ofcom(k , 1)
        lat_start=long_lat_ofcom(k , 2)
        long_end=long_lat_ofcom(k , 3)
        lat_end=long_lat_ofcom(k , 4)


        %collect the delay 
        delay_temp=[];
        delay_ofcom=[];
        for i = 1:length(num_of_steps)
                for j = 1:num_of_query_per_location
                    fileId = fileId + 1 ;
                        %disp(['key_counter' ,num2str(key_counter)]) % for debugging
                     cd([my_path,'/ofcom']);

                    [msg_ofcom,delay_ofcom_tmp,error_ofcom_tmp]=...
                        multi_location_query_ofcom_interval(...
                        lat_start ,lat_end ,long_start,long_end,num_of_steps(i) , distance_divider , my_path );

                    delay_temp = [delay_temp  delay_ofcom_tmp];

                    % writing the response to a file
                    if error_ofcom_tmp==0
                        var_name_txt=strcat(num2str(fileId));    
                        dlmwrite(['txt/',var_name_txt,'.txt'],msg_ofcom,'');
                    end
                end 
                %Get the average of the delay of the same queried area
                delay = sum(delay_temp)/length(delay_temp);
                %collecting the averaged delay 
                delay_ofcom = [delay_ofcom delay];
                delay_temp = [] ;
                delay = [] ;
        end
    %%
        hold on
            plot(num_of_steps , delay_ofcom , '-*', 'LineWidth' , 1);
            xlabel('Number of locations per one request');
            ylabel('Delay (sec)');  
            delay_ofcom_vec = [delay_ofcom_vec delay_ofcom];
            delay_ofcom = []; % reset required for the next step
end
legend('10km')%,'10km','10km','50km','across US')
hold off

%%
['Elapsed time: ',num2str(toc/60),' min']