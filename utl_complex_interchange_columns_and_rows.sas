Complex reorganisation of a data frame in R and SAS/WPS


  Two solutions wps/proc-r and wps/sas

   WORKING CODE
   WPS/SAS

   1  proc transpose data=have out=havXpo;
      by species notsorted;

      WORK.HAVXPO total obs=30

      Obs     SPECIES     _NAME_    COL1

        1    Eupeodesc      V1      1-G3
        2    Eupeodesc      V2      1-F1
        3    Eupeodesc      V3      1-E11

      proc sort data=havXpo out=havSrt;
      by  col1 species;

      * create column names;
      retain cnt 0;
      set havSrt;
      by col1;
      if first.col1 then cnt=0;
      cnt=cnt+1;
      newNam=cats('Species_',put(cnt,1.));

      WORK.HAVSEQ total obs=30

      Obs     SPECIES     COL1      NEWNAM

        1    Diptera      1-A10    Species_1
        2    Episyrphu    1-A10    Species_2
        3    Eupeodesc    1-A3     Species_1


       proc transpose data=havSeq out=want;
       by col1;
       var species;
       id cnt;

       WORK.WANT total obs=18

       Obs    COL1     SPECIES_1    SPECIES_2    SPECIES_3

         1    1-A10    Diptera      Episyrphu
         2    1-A3     Eupeodesc
         3    1-B2     Diptera

    WPS/PROC R
    2  Remarkable this is almost one for one with SAS/WPS above

        input %>%
       # bring all of the data into a long table
       gather(Plate, Well, V1:V5) %>%

       # A tibble: 30 x 3
            SPECIES Plate  Well
        1 Eupeodesc    V1  1-G3
        2   Diptera    V1 1-A10
        3 Episyrphu    V1  2-C3

       # remove the column with the old column names,
       # this column will cause problems in spread if not removed
       select(-Plate) %>%

       # create the placeholder variable
       group_by(Well) %>%
       mutate(NewColumn = seq(1, n())) %>%

       # spread the data out based on the new column header
       spread(NewColumn, Species)

https://goo.gl/wAjKqk
https://stackoverflow.com/questions/46733372/complex-reorganisation-of-a-data-frame-in-r

HAVE                                                                                        RULES
====                                                                                        =====
SD1.HAVE total obs=6                                                          V1=1-A10         v4=1-A10
                                                                          species=Diptera  species=Episyrphu

                                                              Obs    COL1     SPECIES_1       SPECIES_2  SPECIES_3
   SPECIES      V1       V2       V3       V4       V5     |
                                                           |    1    1-A10    Diptera         Episyrphu
  Eupeodesc    1-G3     1-F1     1-E11    1-C10    1-A3    |
  Diptera      1-A10    1-B2     1-C1     1-G7     1-E11   |                  V5=1-A3
  Episyrphu    2-C3     2-A10    1-C11    1-A10    2-B4    |                 species=Eupeodesc
  Aphidie      1-B9     1-D7     2-A3     1-C8     2-C11   |
  Ericaphis    1-B9     1-D7     2-A3     1-C8     2-C11   |    2    1-A3     Eupeodesc
  Hemiptera    1-B9     1-D7     2-A3     1-C8     2-C11   |


WANT
====

WORK.WANT total obs=18

Obs    COL1     SPECIES_1    SPECIES_2    SPECIES_3

  1    1-A10    Diptera      Episyrphu
  2    1-A3     Eupeodesc
  3    1-B2     Diptera
  4    1-B9     Aphidie      Ericaphis    Hemiptera
  5    1-C1     Diptera
  6    1-C10    Eupeodesc
  7    1-C11    Episyrphu
  8    1-C8     Aphidie      Ericaphis    Hemiptera
  9    1-D7     Aphidie      Ericaphis    Hemiptera
 10    1-E11    Diptera      Eupeodesc
 11    1-F1     Eupeodesc
 12    1-G3     Eupeodesc
 13    1-G7     Diptera
 14    2-A10    Episyrphu
 15    2-A3     Aphidie      Ericaphis    Hemiptera
 16    2-B4     Episyrphu
 17    2-C11    Aphidie      Ericaphis    Hemiptera
 18    2-C3     Episyrphu

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
   informat Species V1 V2 V3 V4 V5 $10.;
input Species V1 V2 V3 V4 V5;
cards4;
Eupeodesc 1-G3 1-F1 1-E11 1-C10 1-A3
Diptera 1-A10 1-B2 1-C1 1-G7 1-E11
Episyrphu 2-C3 2-A10 1-C11 1-A10 2-B4
Aphidie 1-B9 1-D7 2-A3 1-C8 2-C11
Ericaphis 1-B9 1-D7 2-A3 1-C8 2-C11
Hemiptera 1-B9 1-D7 2-A3 1-C8 2-C11
;;;;
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

%utl_submit_wps64('
libname sd1 "d:/sd1";
libname wrk "%sysfunc(pathname(work))";

proc transpose data=sd1.have out=havXpo;
by species notsorted;
var v:;
run;quit;

proc sort data=havXpo out=havSrt;
by  col1 species;
run;quit;

data havSeq(drop=_name_ cnt);
  retain cnt 0;
  set havSrt;
  by col1;
  if first.col1 then cnt=0;
  cnt=cnt+1;
  newNam=cats("Species_",put(cnt,1.));
run;quit;

proc transpose data=havSeq out=wrk.want(drop=_name_);
by col1;
var species;
id newNam;
run;quit;
')'

*          _       _   _                ____
 ___  ___ | |_   _| |_(_) ___  _ __    |  _ \
/ __|/ _ \| | | | | __| |/ _ \| '_ \   | |_) |
\__ \ (_) | | |_| | |_| | (_) | | | |  |  _ <
|___/\___/|_|\__,_|\__|_|\___/|_| |_|  |_| \_\

;

%utl_submit_wps64('
libname sd1 "d:/sd1";
options set=R_HOME "C:/Program Files/R/R-3.4.0";
libname wrk "%sysfunc(pathname(work))";
proc r;
submit;
source("c:/Program Files/R/R-3.4.0/etc/Rprofile.site",echo=T);
library(tidyr);
library(dplyr);
library(haven);
input<-read_sas("d:/sd1/have.sas7bdat");
input %>%
gather(Plate, Well, V1:V5)  %>% select(-Plate) %>% group_by(Well);
output <-
        input %>%
        gather(Plate, Well, V1:V5) %>%
        select(-Plate) %>%
        group_by(Well) %>%
        mutate(NewColumn = seq(1, n())) %>%
        spread(NewColumn, SPECIES);
endsubmit;
import r=output data=wrk.want;
run;quit;
');


