.data.load:{
  .data.loadTz x;
 };

.data.loadTz:{
  {.dict.fromTmpl[`dt_timezone_templ;enlist x`tz]; .dict.fromTmpl[`geo_city_templ;x`city`tz]} each .data.tz:("****";enlist ",") 0: ` sv x,`timezones.csv;
 };
