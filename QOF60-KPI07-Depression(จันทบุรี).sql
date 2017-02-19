#SET @prov_c := '22';
SET @b_year:=(SELECT yearprocess FROM sys_config LIMIT 1);
SET	@start_d:=concat('2016-04-01');
SET @end_d:=concat('2016-09-30');

##########เตรียมข้อมูลแฟ้ม specialpp ตามช่วงเวลาที่กำหนด##########
DROP TABLE IF EXISTS _qof60_kpi07_tmp_specialpp;
CREATE TABLE IF NOT EXISTS _qof60_kpi07_tmp_specialpp(
PRIMARY KEY (HOSPCODE,PID,DATE_SERV,PPSPECIAL) 
,KEY (cid)
,KEY (hospcode,pid)
,KEY (date_serv)
,KEY (ppspecial)
)(
SELECT 
	s.HOSPCODE,s.PID,s.SEQ,MIN(s.DATE_SERV) AS 'DATE_SERV',s.SERVPLACE,
	s.PPSPECIAL,s.PPSPLACE,s.PROVIDER,s.D_UPDATE,p.CID
FROM specialpp s 
	LEFT JOIN person p ON s.HOSPCODE=p.HOSPCODE AND s.PID=p.PID
WHERE DATE_SERV BETWEEN @start_d AND @end_d
  AND s.PPSPECIAL IN ('1B026','1B0282','1B0283','1B0284','1B0285')
GROUP BY  s.HOSPCODE,s.PID
);

##########เตรียมข้อมูลแฟ้ม  diag_opd ตามช่วงเวลาที่กำหนด##########
#GROUP BY ให้เหลือกวันที่ แรกสุด
DROP TABLES IF EXISTS _qof60_kpi07_tmp_diag_opd;
CREATE TABLE IF NOT EXISTS _qof60_kpi07_tmp_diag_opd (
KEY(cid),KEY(hospcode),KEY(pid),KEY(seq),KEY(date_serv),KEY(diagcode),KEY(diagtype),KEY(hospcode,pid,seq)
) ENGINE=MyISAM  AS(
SELECT SQL_BIG_RESULT 
		o.HOSPCODE,o.PID,o.SEQ,MIN(o.DATE_SERV) 'DATE_SERV',o.DIAGTYPE,o.DIAGCODE,o.CLINIC,o.PROVIDER,o.D_UPDATE,p.CID
FROM
	diagnosis_opd o 
	LEFT JOIN t_person_db p ON o.HOSPCODE=p.HOSPCODE AND o.PID=p.PID
WHERE	DATE_SERV BETWEEN @start_d AND @end_d
	AND DIAGCODE = 'Z133'
GROUP BY  o.HOSPCODE,o.PID
);

##########สร้างตารางเก็บข้อมูล แม่ท้อง และผู้สูงอายุ  ผู้สูงอายุ##########
DROP  TABLE IF EXISTS  _qof60_kpi07_t_depression;
CREATE  TABLE IF NOT EXISTS _qof60_kpi07_t_depression (
  hospcode varchar(5) DEFAULT NULL,
  areacode varchar(8) DEFAULT NULL,
  cid varchar(13) NOT NULL DEFAULT '',
  pid varchar(15) DEFAULT NULL,
	age_y int(3) DEFAULT '0',
	Group_id int(1)  DEFAULT '0',
	Group_name varchar(8)  DEFAULT NULL,
	Typearea  varchar(1) DEFAULT NULL,
	dbpop_Hmain varchar(5) DEFAULT NULL,
	dbpop_Hsub varchar(5) DEFAULT NULL,
  dbpop_MainInScl varchar(5) DEFAULT NULL,
	special_FirstDate date ,  
	special_Hosp varchar(5) DEFAULT NULL,
	special_SEQ varchar(16) DEFAULT NULL,
	special_Instype  varchar(4) DEFAULT NULL,
	ppsplace varchar(5) DEFAULT NULL,
	diag_FirstDate date ,  
	diag_Hosp varchar(5) DEFAULT NULL,
	diag_SEQ varchar(16) DEFAULT NULL,
	diag_type varchar(1) DEFAULT NULL,
	diag_Diagcode varchar(6) DEFAULT NULL,	
	
  	
PRIMARY KEY (hospcode,pid),
	KEY (hospcode),
	KEY (cid),
	KEY (pid),
	KEY (areacode),
	KEY (typearea)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


### STEP1###
##################นำเข้าข้อมูลหญิงตั้งครรภ์สัญชาติไทยในเขตรับผิดชอบ ทุกหน่วยบริการ###################
#1.ไม่ได้ตัดคนซ้ำตัดซ้ำระหว่างสถานบริการ
##
INSERT IGNORE INTO _qof60_kpi07_t_depression(
  hospcode,areacode,cid,pid,age_y,group_id,typearea
)
SELECT 
								 pe.hospcode AS  HOSPCODE
								,p.check_vhid AS areacode
								,pe.cid,pe.pid								
								#,age(DATE_FORMAT(CONCAT(@b_year,'0101'),'%Y%m%d'),pe.birth,'y') as age_y
								,TIMESTAMPDIFF(YEAR,pe.BIRTH,'2016-04-01')  as age_y
								,'1' AS group_id
								,p.check_typearea AS TYPEAREA
				FROM
						t_person_db p ,t_person_anc pe
				WHERE pe.hospcode=p.HOSPCODE AND  pe.pid=p.PID  /*ใช้ hospcode ,pid เชื่อมหาข้อมูลแม่*/
						#AND substr(p.check_vhid,1,2)=@prov_c
						#AND p.nation=99 
						AND p.DISCHARGE=9 						
						#AND p.check_typearea in(1,3,4)						
ORDER BY check_hosp,check_typearea;
UPDATE _qof60_kpi07_t_depression SET group_name = 'หญิงท้อง'   WHERE group_id=1;

### STEP2###
#######################นำเข้าผู้สูงอายุ 60 ปี ขึ้นไป คนไทย 099 ในพื้นที่ของแต่ละหน่วยบริการ  มีชีวิตอยู่################
#1.ไม่ได้ตัดคนซ้ำตัดซ้ำระหว่างสถานบริการ
##2.นำเข้าข้อมูลที่ได้รับบริการในสถานบริการนั้นๆ
INSERT IGNORE INTO _qof60_kpi07_t_depression(
  hospcode,areacode,cid,pid,age_y,group_id,typearea
)
SELECT pe.check_hosp HOSPCODE
								,pe.check_vhid as areacode
								,pe.CID,pe.PID								
								,p.age_y
								,'2' group_id
								,pe.check_typearea TYPEAREA
				FROM  	t_person_db pe
					LEFT JOIN  t_person_cid p ON pe.CID=p.CID  /*จอยเพื่อนำอายุมาใช้งาน*/
				WHERE
						#substr(pe.check_vhid,1,2)=@prov_c
						#AND pe.nation=99 AND 
						pe.DISCHARGE=9 
						#AND p.age_y>=60 
						AND TIMESTAMPDIFF(YEAR,pe.BIRTH,'2016-04-01')  >= 60
						#AND pe.check_typearea in(1,3)
						
ORDER BY pe.check_hosp,pe.check_typearea;

UPDATE _qof60_kpi07_t_depression SET group_name = 'สูงอายุ'   WHERE group_id=2;

### STEP3###
###นำเข้าข้อมูลการคัดกรองsหญิงตั้งครรภ์ และ สิทธิรักษาพยาบาลที่ใช้ในขณะรักษาพยาบาล###
UPDATE  _qof60_kpi07_t_depression z ,_qof60_kpi07_tmp_specialpp t  ,service s 
	SET z.special_FirstDate=t.DATE_SERV , z.special_Hosp=t.HOSPCODE ,z.ppsplace=t.ppsplace,
						z.special_SEQ=s.SEQ, z.special_Instype=s.INSTYPE 
WHERE 
	z.hospcode=t.HOSPCODE AND z.pid = t.CID
	AND t.hospcode=s.HOSPCODE AND t.pid=s.PID AND  t.seq=s.SEQ AND t.date_serv=s.DATE_SERV 
	AND  t.PPSPECIAL IN ('1B026')
	AND group_id = '1';
###นำเข้าข้อมูลการคัดกรองผู้สูงอายุ และ สิทธิรักษาพยาบาลที่ใช้ในขณะรักษาพยาบาล###
UPDATE  _qof60_kpi07_t_depression z ,_qof60_kpi07_tmp_specialpp t  ,service s 
	SET z.special_FirstDate=t.DATE_SERV , z.special_Hosp=t.HOSPCODE ,z.ppsplace=t.ppsplace,
						z.special_SEQ=s.SEQ, z.special_Instype=s.INSTYPE
WHERE 
	z.hospcode=t.HOSPCODE AND z.pid=t.PID
	AND t.hospcode=s.HOSPCODE AND t.pid=s.PID AND  t.seq=s.SEQ AND t.date_serv=s.DATE_SERV
	AND  t.PPSPECIAL IN ('1B0282','1B0283','1B0284','1B0285')
	AND group_id = '2';

### STEP4###
###นำเข้าข้อมูลสทิธิรักษาพยาบาลจากฐานข้อมูล DBPOP###
UPDATE  _qof60_kpi07_t_depression z ,dbpop d  
	SET z.dbpop_Hmain=d.HMain , z.dbpop_Hsub=d.Hsub , z.dbpop_MainInScl=d.MainInScl
WHERE 
	z.cid=d.PID;


### STEP5###
####นำเข้าข้อมูล diag_opd รหัส Z133  ตามวันที่ที่รับบริการได้รับบริการ specialpp  ######
#1.นำเข้าขอมูล diag 
UPDATE _qof60_kpi07_t_depression z , _qof60_kpi07_tmp_diag_opd d ,service s
	SET z.diag_Hosp=d.HOSPCODE,z.diag_FirstDate=d.DATE_SERV ,z.diag_SEQ=d.SEQ,
						z.diag_Diagcode=d.DIAGCODE, z.diag_Type=d.DIAGTYPE
WHERE  
		z.hospcode=d.HOSPCODE  	AND z.pid=d.PID
		AND d.hospcode=s.HOSPCODE AND d.pid=s.PID AND  d.seq=s.SEQ AND d.date_serv=s.DATE_SERV 
		AND d.DIAGCODE = 'Z133';


#####STEP 6 #####
#สร้างตารางเก็บข้อมูล One Recorde 
DROP  TABLE IF EXISTS  _qof60_kpi07_t_depression_cid;
CREATE  TABLE IF NOT EXISTS _qof60_kpi07_t_depression_cid (
  hospcode varchar(5) DEFAULT NULL,
  areacode varchar(8) DEFAULT NULL,
  cid varchar(13) NOT NULL DEFAULT '',
  pid varchar(15) DEFAULT NULL,
	age_y int(3) DEFAULT '0',
	Group_id int(1)  DEFAULT '0',
	Group_name varchar(8)  DEFAULT NULL,
	Typearea  varchar(1) DEFAULT NULL,
	dbpop_Hmain varchar(5) DEFAULT NULL,
	dbpop_Hsub varchar(5) DEFAULT NULL,
  dbpop_MainInScl varchar(5) DEFAULT NULL,
	special_FirstDate date ,  
	special_Hosp varchar(5) DEFAULT NULL,
	special_SEQ varchar(16) DEFAULT NULL,
	special_Instype  varchar(4) DEFAULT NULL,
	ppsplace varchar(5) DEFAULT NULL,
	diag_FirstDate date ,  
	diag_Hosp varchar(5) DEFAULT NULL,
	diag_SEQ varchar(16) DEFAULT NULL,
	diag_type varchar(1) DEFAULT NULL,
	diag_Diagcode varchar(6) DEFAULT NULL,	
  	
PRIMARY KEY (cid),
	KEY (hospcode),
	KEY (cid),
	KEY (pid),
	KEY (areacode),
	KEY (typearea)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

##################################################
#1.ทำข้อมูลเป็น One Recorde 
#2. เลือกเอาเฉพาะข้อมูลที่มีวันรับบริการน้อยที่สุด  ลงในตาราง
#3. ข้อมูลการได้รับบริการจะตรงกับ สถานบริการที่ให้บริการครั้งแรก
INSERT IGNORE INTO _qof60_kpi07_t_depression_cid
(		
		SELECT  *		 	
			FROM  _qof60_kpi07_t_depression
			WHERE	  LENGTH(TRIM(cid))=13 
		ORDER BY diag_FirstDate  ASC
);

#####STEP สุดท้าย#####
# นับจำนวนข้อมูล แยกรายสถานบริการ
SELECT  
	z.hospcode,
	COUNT(IF(Group_id IN (1) AND (special_FirstDate IS NOT NULL OR diag_FirstDate IS NOT NULL),z.hospcode,NULL))  'A',
	COUNT(IF(Group_id IN (2) AND (special_FirstDate IS NOT NULL OR diag_FirstDate IS NOT NULL),z.hospcode,NULL))  'B',	
	COUNT(IF(Group_id IN (1) ,z.hospcode,NULL))  'C',
	COUNT(IF(Group_id IN (2) ,z.hospcode,NULL))  'D',
COUNT(IF(Group_id IN (1,2) AND (special_FirstDate IS NOT NULL OR diag_FirstDate IS NOT NULL),z.hospcode,NULL))  'A+B',
	COUNT(IF(Group_id IN (1,2) ,z.hospcode,NULL))  'C+D',
	((COUNT(IF(Group_id IN (1,2) AND (special_FirstDate IS NOT NULL OR diag_FirstDate IS NOT NULL) ,z.hospcode,NULL))/COUNT(IF(Group_id IN (1,2) ,z.hospcode,NULL)))*100) 'AVG'	
FROM  _qof60_kpi07_t_depression_cid  z
	#WHERE   ยังนึกไม่ออกครับ รอถามในเขต
GROUP BY z.hospcode;