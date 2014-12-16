function [elevation]=elevation_google_maps(latitude,longitude)
%ELEVATION_GOOGLE_MAPS Script used in gettin elevation data used in [1].
%
%   Reference: [1] Will Dynamic Spectrum Access Drain my Battery?

%   Code development: 

%   Last update: 7 July 2014

%   This work is licensed under a Creative Commons Attribution 3.0 Unported
%   License. Link to license: http://creativecommons.org/licenses/by/3.0/

key='"AIzaSyCCweYzxC6BHSFqDbvDr6Jf4k1GNKWpivI"'; %API key [replace by your own]

text_coding='"Content-Type: application/xml; charset=utf-8"';
server_name='http://maps.googleapis.com/maps/api/elevation/xml?locations=';

cmnd=['/usr/bin/curl -H ',text_coding,' ',server_name,...
    num2str(latitude),',',num2str(longitude),'&key=',key];

[status,response]=system(cmnd);

beg_query_str='<elevation>';
end_query_str='</elevation>';
pos_beg_query_str=findstr(response,beg_query_str);
pos_end_query_str=findstr(response,end_query_str);
length_beg_query_str=length(beg_query_str);
length_end_query_str=length(end_query_str);
elevation=str2num(response(pos_beg_query_str+length_beg_query_str:pos_end_query_str-1));