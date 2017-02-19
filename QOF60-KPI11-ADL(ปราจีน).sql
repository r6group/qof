#SET @prov_c := '25';
SET	@b_year:=(SELECT yearprocess FROM sys_config LIMIT 1);
SET @start_d:=concat(@b_year-1,'0401');
SET @end_d:=concat(@b_year,'0331');
#1.minspecialpp เอาเลขประชาชน มาจาก person
DROP TABLE IF EXISTS _qof60_kpi11_tmp_specialpp;
CREATE TABLE IF NOT EXISTS _qof60_kpi11_tmp_specialpp(
PRIMARY KEY (HOSPCODE,PID,DATE_SERV,PPSPECIAL) 
,KEY (cid)
,KEY (hospcode,pid)
,KEY (date_serv)
,KEY (ppspecial)
)(
SELECT 
s.HOSPCODE
,s.PID
,min(s.DATE_SERV) as DATE_SERV
,s.SEQ
,s.SERVPLACE
,s.PPSPECIAL
,s.PPSPLACE
,s.PROVIDER
,s.D_UPDATE
,p.CID
FROM specialpp s LEFT JOIN person p ON s.HOSPCODE=p.HOSPCODE AND s.PID=p.PID
WHERE 
s.PPSPECIAL="1b1282"
and (
DATE_SERV BETWEEN @start_d AND @end_d
)
GROUP BY
s.HOSPCODE
,s.PID

);

#2.min rehabilitation เอาเลขประชาชน มาจาก person
DROP TABLE IF EXISTS _qof60_kpi11_tmp_rehabilitation;
CREATE TABLE IF NOT EXISTS _qof60_kpi11_tmp_rehabilitation(
PRIMARY KEY (HOSPCODE,PID,DATE_SERV,rehabcode) 
,KEY (cid)
,KEY (hospcode,pid)
,KEY (date_serv)
,KEY (rehabcode)
)(
SELECT 
r.HOSPCODE
,r.PID
,min(r.DATE_SERV) as DATE_SERV
#,group_concat(concat('(',r.seq,'-',r.REHABCODE,'-',r.REHABPLACE,'-',')') ORDER BY r.REHABCODE) as REHABPLACE
,r.SEQ
,r.REHABCODE
,r.REHABPLACE
,r.PROVIDER
,r.D_UPDATE
,p.CID
FROM rehabilitation r LEFT JOIN person p ON r.HOSPCODE=p.HOSPCODE AND r.PID=p.PID
WHERE 
DATE_SERV BETWEEN @start_d AND @end_d

GROUP BY
r.HOSPCODE
,r.PID

);

#3.create table individual target name _qof60_kpi11_t_adl4
DROP TABLE IF EXISTS _qof60_kpi11_t_adl4;
CREATE TABLE IF NOT EXISTS _qof60_kpi11_t_adl4(
 `HOSPCODE` varchar(5) NOT NULL,
 `CID` varchar(13) DEFAULT NULL,
 `PID` varchar(15) NOT NULL,
 `BIRTH` DATE,
 `AGE_Y` varchar(3) DEFAULT '0',
 `TYPEAREA` varchar(1) DEFAULT NULL,
 `DATE_SERV` date DEFAULT NULL,
 `PPSPECIAL` VARCHAR(6) DEFAULT NULL,
  `PP_HOSP` VARCHAR(5) DEFAULT NULL,	
 `DATE_SERV_R` date DEFAULT NULL,
 `REHABCODE` VARCHAR(6) DEFAULT NULL,
  `R_HOS` VARCHAR(5) DEFAULT NULL,	
PRIMARY KEY (`CID`),
  KEY  (`HOSPCODE`,`PID`),
  KEY  (`HOSPCODE`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT IGNORE INTO _qof60_kpi11_t_adl4 (HOSPCODE,CID,PID,BIRTH,AGE_Y,TYPEAREA)
(
SELECT check_hosp,CID,PID,BIRTH,AGE_Y,check_typearea 
FROM t_person_cid 
WHERE 
LENGTH(cid)=13  
#AND check_typearea in(1,3) 
#AND NATION in(99) 
AND age_y >=60 AND age_y < 200 
#AND DISCHARGE in(9)
);


UPDATE _qof60_kpi11_t_adl4 INNER JOIN _qof60_kpi11_tmp_specialpp
on _qof60_kpi11_t_adl4.cid=_qof60_kpi11_tmp_specialpp.cid 
set  _qof60_kpi11_t_adl4.DATE_SERV=_qof60_kpi11_tmp_specialpp.DATE_SERV
     ,_qof60_kpi11_t_adl4.PPSPECIAL=_qof60_kpi11_tmp_specialpp.PPSPECIAL
     ,_qof60_kpi11_t_adl4.PP_HOSP=_qof60_kpi11_tmp_specialpp.PPSPLACE
;

UPDATE _qof60_kpi11_t_adl4 INNER JOIN _qof60_kpi11_tmp_rehabilitation
on _qof60_kpi11_t_adl4.CID=_qof60_kpi11_tmp_rehabilitation.CID
set  _qof60_kpi11_t_adl4.DATE_SERV_R=_qof60_kpi11_tmp_rehabilitation.DATE_SERV
     ,_qof60_kpi11_t_adl4.REHABCODE=_qof60_kpi11_tmp_rehabilitation.REHABCODE
     ,_qof60_kpi11_t_adl4.R_HOS=_qof60_kpi11_tmp_rehabilitation.REHABPLACE
;
drop TABLE _qof60_kpi11_tmp_specialpp;
DROP TABLE _qof60_kpi11_tmp_rehabilitation;

#COMPLETE

