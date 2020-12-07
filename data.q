.data.load:{
  .data.loadTz x;
 };

.data.loadTz:{{.dict.fromTmpl[`dt_timezone_templ;enlist x`tz]} each .data.tz:("***";enlist ",") 0: ` sv x,`timezones.csv};
