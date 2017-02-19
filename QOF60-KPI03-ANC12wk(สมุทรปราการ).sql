/*-----qof60-3_ร้อยละของหญิงมีครรภ์ได้รับการฝากครรภ์ครั้งแรกภายใน12สัปดาห์------*/
##improve 2017-01-24 14.06

#SET @prov_c := '11';	 
SET @b_year:=(SELECT yearprocess FROM sys_config LIMIT 1); 
SET	@start_d:=concat(@b_year-1,'-04-01'); 
SET @end_d:=concat(@b_year,'-03-31'); 
SET @start_o:=concat(@b_year-2,'-07-01'); #'2015-07-01' 
SET @end_o:=concat(@b_year-1,'-03-31'); #'2016-03-31'


SELECT
LEFT(IF(tqof3.1st_date IS NULL,(GROUP_CONCAT(tqof3.hospcode,'-',tqof3.pid ORDER BY tqof3.min_date)),tqof3.hospcode),5) AS 'hospcode',
SUBSTRING_INDEX(IF(tqof3.1st_date IS NULL,(GROUP_CONCAT(tqof3.pid,'-',tqof3.hospcode ORDER BY tqof3.min_date)),tqof3.pid),'-',1) AS 'pid',

GROUP_CONCAT(tqof3.hospcode,' ',tqof3.min_date,' ',tqof3.pid ORDER BY tqof3.min_date) AS 'hosp_check',
GROUP_CONCAT(tqof3.hospcode ORDER BY tqof3.1st_date) AS 'grp_hospcode',
GROUP_CONCAT(tqof3.hospcode,' ',tqof3.pid) AS 'pid_check',
tqof3.cid,
tqof3.gravida,
GROUP_CONCAT(tqof3.hospcode,' ',tqof3.1st_date ORDER BY tqof3.1st_date) AS '1st_date',
tqof3.gravida_check,
tqof3.ancno,
GROUP_CONCAT(tqof3.grp_ga) AS 'grp_ga'

FROM (
SELECT
tanc.*,
tanc1.grp_dateserv,
tanc1.1st_date,
tanc1.gravida AS 'gravida_check',
tanc1.ancno,
tanc1.grp_ga,
oanc.dateserv AS 'dateserv_59',
oanc.gravida AS 'gravida_59',
oanc.ancno AS 'ancno_59',
oanc.ga AS 'ga_59'

FROM (

##
SELECT
anc.HOSPCODE,
anc.PID,
anc.GRAVIDA,
GROUP_CONCAT(anc.ANCNO) AS 'grp_ancno',
GROUP_CONCAT(anc.DATE_SERV ORDER BY anc.DATE_SERV) AS 'grp_date',
MIN(anc.DATE_SERV) AS 'min_date',
person.CID,
person.NATION,
person.DISCHARGE
#,mod11(person.CID) AS 'mod_11'

FROM
anc
INNER JOIN person ON anc.HOSPCODE=person.HOSPCODE AND anc.PID=person.PID
WHERE
anc.DATE_SERV BETWEEN @start_d AND @end_d
#AND anc.ANCNO='1' 
AND anc.SEQ IS NOT NULL
AND person.NATION='099'
AND LEFT(person.CID,1)<>'0'
#AND mod11(person.CID)=1
GROUP BY anc.HOSPCODE,anc.PID,anc.GRAVIDA

#ORDER BY CID
) tanc 

##anc ปีเก่า
LEFT JOIN (
SELECT
anc.HOSPCODE,anc.PID,
#anc.SEQ,
GROUP_CONCAT(anc.DATE_SERV) AS 'dateserv',
GROUP_CONCAT(anc.GRAVIDA) as 'gravida',
GROUP_CONCAT(anc.ANCNO) AS 'ancno',
GROUP_CONCAT(anc.GA) AS 'ga'
FROM anc
WHERE
anc.DATE_SERV BETWEEN @start_o AND @end_o  
#AND anc.ANCNO='1' AND anc.GA<=12
AND anc.SEQ IS NOT NULL
GROUP BY anc.HOSPCODE,anc.PID,anc.GRAVIDA
) oanc ON tanc.HOSPCODE=oanc.HOSPCODE AND tanc.PID=oanc.PID AND tanc.GRAVIDA=oanc.GRAVIDA

##anc ครั้งที่ 1
LEFT JOIN (
SELECT
anc.HOSPCODE,
anc.PID,
#SUBSTRING_INDEX((GROUP_CONCAT(anc.PID ORDER BY anc.DATE_SERV)),',',1) AS '1st_pid',
anc.SEQ,
#anc.DATE_SERV,
GROUP_CONCAT(anc.DATE_SERV ORDER BY anc.DATE_SERV) AS 'grp_dateserv',
LEFT((GROUP_CONCAT(anc.DATE_SERV ORDER BY anc.DATE_SERV)),10) AS '1st_date',
anc.GRAVIDA,
anc.ANCNO,
GROUP_CONCAT(anc.GA ORDER BY anc.DATE_SERV) AS 'grp_ga'

FROM anc
WHERE
anc.DATE_SERV BETWEEN @start_d AND @end_d  AND
anc.ANCNO='1' AND anc.GA<=12
AND anc.SEQ IS NOT NULL
GROUP BY anc.HOSPCODE,anc.PID,anc.GRAVIDA
) tanc1 ON tanc.HOSPCODE=tanc1.HOSPCODE AND tanc.PID=tanc1.PID AND tanc.GRAVIDA=tanc1.GRAVIDA

WHERE
oanc.dateserv IS NULL	#ตัด anc 9เดือนย้อนหลังออก

#GROUP BY cid
) tqof3

GROUP BY tqof3.cid,tqof3.gravida


