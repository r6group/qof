# SET @pv='24';
# กำหนดช่วงเวลาผลงาน เริ่มจากกรกฎาคม 2558 ที่มีงานนี้เกิดขึ้น 
SET @start_d:='2016-08-01';
SET @end_d:='2017-03-31';
# กำหนดช่วงวันเกิด ของเด็กที่อยู่ในกลุ่มเป้าหมาย 
SET @begin_d=DATE_ADD(@start_d,INTERVAL -43 month);
SET @tablename='_qof60_kpi08_t_develop';

/*หาเด็กกลุ่มเป้าหมาย*/
DROP TABLE IF EXISTS t_childdev_QOF;
CREATE TABLE  IF NOT EXISTS t_childdev_QOF(
  `HOSPCODE` varchar(5) NOT NULL DEFAULT '',
  `PID` varchar(15) NOT NULL DEFAULT '',
  `CID` varchar(13) NOT NULL,
  `BIRTH` date  DEFAULT NULL,
  `SEX` varchar(1) NOT NULL DEFAULT '',
  `AGE_9` int(1) NOT NULL DEFAULT '0',
  `AGE_18` int(1) NOT NULL DEFAULT '0',
  `AGE_30` int(1) NOT NULL DEFAULT '0',
  `AGE_42` int(1) NOT NULL DEFAULT '0',
	PRIMARY KEY (`HOSPCODE`,`PID`),
	KEY (`HOSPCODE`,`PID`,`CID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
#.ใส่เด็กที่อยู่ในช่วงวันเกิดที่คำนวณแล้ว  ยังไม่ตาย  เป็นคนไทย รหัส 13 
INSERT IGNORE INTO t_childdev_QOF (SELECT
 p.HOSPCODE,p.PID,p.CID,p.BIRTH,p.SEX,0,0,0,0
FROM hdc.t_person_cid  p
WHERE BIRTH BETWEEN @begin_d AND @end_d AND
						p.DISCHARGE='9' AND LENGTH(trim(p.CID))=13 AND mod11(p.CID)=1 AND LEFT(p.CID,6)<>CONCAT('0',p.HOSPCODE) AND  NATION in(99) 
);

# คำนวณว่หาว่าเด็กจะมีอายุ 9,18,30,42    หรือไม่   
UPDATE t_childdev_QOF SET AGE_9=1 WHERE (DATE_ADD(BIRTH,INTERVAL 9 month)  BETWEEN @start_d AND @end_d) 
			OR (DATE_ADD(BIRTH,INTERVAL 10 month)  BETWEEN @start_d AND @end_d);
UPDATE t_childdev_QOF SET AGE_18=1 WHERE (DATE_ADD(BIRTH,INTERVAL 18 month)  BETWEEN @start_d AND @end_d)
			OR (DATE_ADD(BIRTH,INTERVAL 19 month)  BETWEEN @start_d AND @end_d);
UPDATE t_childdev_QOF SET AGE_30=1 WHERE (DATE_ADD(BIRTH,INTERVAL 30 month)  BETWEEN @start_d AND @end_d)
			OR (DATE_ADD(BIRTH,INTERVAL 31 month)  BETWEEN @start_d AND @end_d);
UPDATE t_childdev_QOF SET AGE_42=1 WHERE (DATE_ADD(BIRTH,INTERVAL 42 month)  BETWEEN @start_d AND @end_d)
			OR (DATE_ADD(BIRTH,INTERVAL 43 month)  BETWEEN @start_d AND @end_d);

# สร้างตารางรับเด็กเป้าหมาย 9,18,30,42  อาจจะมี 13 หลักซ้ำได้ ถ้าเด็กอายุ 2 ช่วง
DROP TABLE IF  EXISTS _qof60_kpi08_t_develop;
CREATE TABLE IF NOT EXISTS _qof60_kpi08_t_develop(
  `hospcode` char(5) NOT NULL DEFAULT '',
  `pid` varchar(15) NOT NULL,
  `cid` varchar(13) NOT NULL ,
  `sex` varchar(1) DEFAULT NULL ,
  `birth` date DEFAULT NULL,
	 inscl CHAR(5),
	 hospsub CHAR(5),
	 agemonth VARCHAR(3) DEFAULT NULL,
	 scr_hos char(5),
	 date_serv_first date  COMMENT 'วันที่คัดกรองครั้งแรก',
	 sp_first text COMMENT 'รหัสคัดกรองครั้งแรก',
	 date_start date,
	 date_end date,
PRIMARY KEY (CID,agemonth),
KEY `cid` (`cid`)
)ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT IGNORE INTO _qof60_kpi08_t_develop (hospcode,pid,cid,birth,sex,agemonth)
(
SELECT
p.hospcode,p.pid,p.cid,p.birth,p.sex,'42'
FROM t_childdev_QOF p
WHERE AGE_42=1
);
INSERT IGNORE INTO _qof60_kpi08_t_develop (hospcode,pid,cid,birth,sex,agemonth)
(
SELECT
p.hospcode,p.pid,p.cid,p.birth,p.sex,'30'
FROM t_childdev_QOF p
WHERE AGE_30=1
);
INSERT IGNORE INTO _qof60_kpi08_t_develop (hospcode,pid,cid,birth,sex,agemonth)
(
SELECT
p.hospcode,p.pid,p.cid,p.birth,p.sex,'18'
FROM t_childdev_QOF p
WHERE AGE_18=1
);
INSERT IGNORE INTO _qof60_kpi08_t_develop (hospcode,pid,cid,birth,sex,agemonth)
(
SELECT
p.hospcode,p.pid,p.cid,p.birth,p.sex,'9'
FROM t_childdev_QOF p
WHERE AGE_9=1
);

INSERT IGNORE INTO _qof60_kpi08_t_develop (hospcode,pid,cid,birth,sex,agemonth)
(SELECT
p.hospcode,p.pid,p.cid,p.birth,p.sex
,IF(age_18=1 AND age_9=1 , 18 ,0)
FROM t_childdev_QOF p
);
INSERT IGNORE INTO _qof60_kpi08_t_develop (hospcode,pid,cid,birth,sex,agemonth)
(SELECT
p.hospcode,p.pid,p.cid,p.birth,p.sex
,IF(age_18=1 AND age_9=1 , 9 ,0)
FROM t_childdev_QOF p
);
#ลบเด็กที่ไม่ตกในช่วง 9 18 30 42
DELETE FROM _qof60_kpi08_t_develop WHERE agemonth=0;

#อัพเดทช่วงวันที่ที่ทำแล้วถือว่าได้รับการคัดกรอง
UPDATE  _qof60_kpi08_t_develop SET date_start=DATE_ADD(BIRTH,INTERVAL 9 month) ,date_end=DATE_ADD(DATE_ADD(BIRTH,INTERVAL 10 month),INTERVAL -1 DAY)  WHERE agemonth=9;
UPDATE  _qof60_kpi08_t_develop SET date_start=DATE_ADD(BIRTH,INTERVAL 18 month) ,date_end=DATE_ADD(DATE_ADD(BIRTH,INTERVAL 19 month),INTERVAL -1 DAY)  WHERE agemonth=18;
UPDATE  _qof60_kpi08_t_develop SET date_start=DATE_ADD(BIRTH,INTERVAL 30 month) ,date_end=DATE_ADD(DATE_ADD(BIRTH,INTERVAL 31 month),INTERVAL -1 DAY)  WHERE agemonth=30;
UPDATE  _qof60_kpi08_t_develop SET date_start=DATE_ADD(BIRTH,INTERVAL 42 month) ,date_end=DATE_ADD(DATE_ADD(BIRTH,INTERVAL 43 month),INTERVAL -1 DAY)  WHERE agemonth=42;

#ค้นหาผลงานคัดกรอง
DROP TABLE IF EXISTS tmp_specialpp_qof;
CREATE TABLE IF NOT EXISTS tmp_specialpp_qof(
PRIMARY KEY (HOSPCODE,PID,DATE_SERV,PPSPECIAL) 
,KEY (cid)
,KEY (hospcode,pid)
,KEY (date_serv)
,KEY (ppspecial)
)(
SELECT 
s.*,p.CID,TIMESTAMPDIFF(MONTH,p.BIRTH,DATE_SERV) AS agemonth
FROM hdc.specialpp s LEFT JOIN hdc.person p ON s.HOSPCODE=p.HOSPCODE AND s.PID=p.PID
WHERE DATE_SERV BETWEEN @start_d AND @end_d AND 
PPSPECIAL in('1B260','1B261','1B262' ,'1B200'
			,'1B201','1B202','1B209','1B210','1B211','1B212'
			,'1B219','1B220','1B221','1B222','1B229','1B230'
			,'1B231','1B232','1B239','1B240','1B241','1B242','1B249') AND 
p.DISCHARGE='9' AND mod11(p.CID)=1 AND LEFT(p.CID,6)<>CONCAT('0',p.HOSPCODE) AND  p.NATION ='099'
);

/*หาวันที่วันแรกที่ได้รับการตรวจเอาวันน้อยที่สุดจากวันเกิดที่มีรหัสที่กำหนด*/
UPDATE _qof60_kpi08_t_develop s INNER JOIN 
(
			SELECT s1.cid,s1.date_start, s1.date_end ,MIN(t1.date_serv) min_date_serv
			FROM tmp_specialpp_qof  t1 INNER JOIN tmp_develop_QOF s1 ON  t1.cid=s1.cid
			WHERE t1.date_serv BETWEEN s1.date_start AND s1.date_end 
			AND PPSPECIAL in('1B260','1B261','1B262' ,'1B200'
			,'1B201','1B202','1B209','1B210','1B211','1B212'
			,'1B219','1B220','1B221','1B222','1B229','1B230'
			,'1B231','1B232','1B239','1B240','1B241','1B242','1B249')
			GROUP BY t1.cid,s1.date_start
)
t  ON s.cid=t.cid   AND s.date_start=t.date_start
SET s.date_serv_first= t.min_date_serv
WHERE t.min_date_serv BETWEEN s.date_start AND s.date_end ;

UPDATE _qof60_kpi08_t_develop s  INNER JOIN 
(
			SELECT cid,agemonth,MIN(date_serv) min_date_serv,GROUP_CONCAT(PPSPECIAL ORDER BY PPSPECIAL) spp,hospcode
			FROM tmp_specialpp_qof  t1 
			GROUP BY t1.cid,t1.agemonth 
)
t  ON s.cid=t.cid   AND s.agemonth=t.agemonth 
SET s.date_serv_first= t.min_date_serv ,s.scr_hos=t.hospcode,s.sp_first=t.spp 
WHERE t.min_date_serv BETWEEN s.date_start AND s.date_end;

#ปรับรหัสสิทธิ 
UPDATE _qof60_kpi08_t_develop s LEFT OUTER JOIN dbpop5908 d ON s.cid=d.pid 
SET s.inscl=d.maininscl,s.hospsub=d.hsub 
WHERE  s.date_serv_first IS NOT NULL AND LEFT(s.date_serv_first,7)='2016-08' AND d.hsub IS NOT NULL;

UPDATE _qof60_kpi08_t_develop s LEFT OUTER JOIN dbpop5909 d ON s.cid=d.pid 
SET s.inscl=d.maininscl,s.hospsub=d.hsub 
WHERE  s.date_serv_first IS NOT NULL AND LEFT(s.date_serv_first,7)>='2016-09';

# ลบตาราง tmp

DROP TABLE IF EXISTS t_childdev_QOF;
DROP TABLE IF EXISTS tmp_specialpp_qof;
