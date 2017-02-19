#QOF60 ร้อยละของเด็กนักเรียน (6-14ปี) มีส่วนสูงระดับดีและรูปร่างสมส่วน (Update 24/1/60)
#QOF60 CREATE TABLE 2 Table
#_qof60_KPI09_t_nutrition_service6_14 		=รายชื่อ
#_qof60_KPI09_s_kpi_height614 		                      =รายงาน

#รายชื่อ----------------------------------------------------------------
#SET @prov_c := '20';
SET @b_year:=(SELECT yearprocess FROM sys_config LIMIT 1);
SET @start_d:=concat(@b_year-1,'0401');#Count 1 April
SET @end_d:=concat(@b_year,'0331');#Count 31 March

DROP TABLE IF EXISTS _qof60_kpi09_t_nutrition_service6_14;
CREATE TABLE IF NOT EXISTS _qof60_kpi09_t_nutrition_service6_14(
hospcode VARCHAR(5) NOT NULL,
pid VARCHAR(15) NOT NULL,
cid VARCHAR(13)DEFAULT NULL,
seq VARCHAR(16) NOT NULL,
date_serv date,
weight decimal(5,1) NOT NULL,
height  int(3) NOT NULL,
HEADCIRCUM int(3) DEFAULT NULL,
FOOD varchar(1) DEFAULT NULL,
BOTTLE varchar(1) DEFAULT NULL,
BIRTH date,
SEX varchar(1) NOT NULL,
NATION varchar(3) DEFAULT NULL,
quarter_m int(1) DEFAULT 0,
nutri1 int(1) DEFAULT 0,
nutri2 int(1) DEFAULT 0,
nutri3 int(1) DEFAULT 0,
PRIMARY KEY (hospcode,pid,quarter_m)
)  ENGINE MyISAM DEFAULT CHARACTER SET=utf8;

INSERT IGNORE INTO _qof60_kpi09_t_nutrition_service6_14 (HOSPCODE,PID,cid,SEQ,DATE_SERV,WEIGHT,HEIGHT,HEADCIRCUM,FOOD,BOTTLE
,BIRTH,SEX,NATION,quarter_m)
(

SELECT n.HOSPCODE,n.PID,p.cid,n.SEQ,n.DATE_SERV,n.WEIGHT,n.HEIGHT,n.HEADCIRCUM,FOOD,BOTTLE
,p.BIRTH,p.SEX,p.NATION, 
IF(DATE_FORMAT(n.DATE_SERV,'%m') BETWEEN 10 AND 12,2,
IF(DATE_FORMAT(n.DATE_SERV,'%m') BETWEEN 1 AND 3,2, 
IF(DATE_FORMAT(n.DATE_SERV,'%m') BETWEEN 4 AND 6,1, 
IF(DATE_FORMAT(n.DATE_SERV,'%m') BETWEEN 7 AND 9,1,0 
 )))) as quarter_m
FROM
nutrition n INNER JOIN t_person_db p ON n.HOSPCODE=p.HOSPCODE AND n.PID=p.PID
WHERE WEIGHT BETWEEN 0.1  AND 300 AND HEIGHT   BETWEEN 40 AND 250 
AND n.DATE_SERV >= p.birth AND TIMESTAMPDIFF(YEAR,p.BIRTH,n.DATE_SERV) BETWEEN 6 AND 14
AND  n.DATE_SERV BETWEEN  @start_d AND @end_d
#AND p.NATION in(99) 
ORDER BY n.HOSPCODE ASC ,n.PID ASC ,n.DATE_SERV DESC 
);

UPDATE _qof60_kpi09_t_nutrition_service6_14 SET nutri1=nutri_cal(TIMESTAMPDIFF(month,birth,date_serv),sex,1,height,weight)
,nutri2=nutri_cal(TIMESTAMPDIFF(month,birth,date_serv),sex,2,height,weight)
,nutri3=nutri_cal(TIMESTAMPDIFF(month,birth,date_serv),sex,3,height,weight);


#รายงาน-------------------------------------------------------------

#				CREATE TABLE IF NOT EXISTS _qof60_kpi09_s_kpi_height614(
#				#id varchar(32) NOT NULL,
#				hospcode varchar(5) NOT NULL,
#				areacode varchar(8) NOT NULL,
#				flag_sent varchar(1) NOT NULL,
#				date_com varchar(14) NOT NULL,
#				b_year varchar(4) NOT NULL,
#				targetq1 int(9) DEFAULT 0,
#				targetq2 int(9) DEFAULT 0,
#				resultq1 int(9) DEFAULT 0,
#				resultq2 int(9) DEFAULT 0,
#				a2q1 int(9) DEFAULT 0,
#				a2q2 int(9) DEFAULT 0,
#				a3q1 int(9) DEFAULT 0,
#				a3q2 int(9) DEFAULT 0,
#				a4q1 int(9) DEFAULT 0,
#				a4q2 int(9) DEFAULT 0,
#				b3q1 int(9) DEFAULT 0,
#				b3q2 int(9) DEFAULT 0,
#				a5q1 int(9) DEFAULT 0,
#				a5q2 int(9) DEFAULT 0,
#				b4q1 int(9) DEFAULT 0,
#				b4q2 int(9) DEFAULT 0,
#				a6q1 int(9) DEFAULT 0,
#				a6q2 int(9) DEFAULT 0,

#				PRIMARY KEY (hospcode,areacode,b_year),
#				 KEY (hospcode),
#				 KEY (areacode),
#				 KEY (b_year)
#				) ENGINE=MyISAM DEFAULT CHARSET=utf8;

#				DELETE FROM _qof60_kpi09_s_kpi_height614 WHERE  b_year=(@b_year+543);
#				INSERT IGNORE INTO _qof60_kpi09_s_kpi_height614
#				(
#				SELECT
#					h.hoscode hospcode,concat(h.provcode,h.distcode,h.subdistcode,SUBSTR(CONCAT('00',h.mu),-2)) as areacode
#					 ,@send,DATE_FORMAT(now(),'%Y%m%d%H%i') as d_com,@b_year+543 as b_year
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3) , CONCAT(n.HOSPCODE,'-',n.PID),NULL)) B1Q1
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) B1Q2
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3) AND nutri2 in(3,4,5) AND nutri3 in(3), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) A1Q1
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9) AND nutri2 in(3,4,5) AND nutri3 in(3), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) A1Q2

#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3)  AND nutri3 in(1), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) A2Q1
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9) AND nutri3 in(1), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) A2Q2

#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3)  AND nutri3 in(5,6), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) A3Q1
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9) AND nutri3 in(5,6), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) A3Q2

#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3)  AND nutri2 in(1), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) A4Q1
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9) AND nutri2 in(1), CONCAT(n.HOSPCODE,'-',n.PID),NULL)) A4Q2

#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3) AND sex in(1) AND TIMESTAMPDIFF(year,birth,date_serv) in(12)  ,  CONCAT(n.HOSPCODE,'-',n.PID),NULL)) B3Q1
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9) AND sex in(1) AND TIMESTAMPDIFF(year,birth,date_serv) in(12),  CONCAT(n.HOSPCODE,'-',n.PID),NULL)) B3Q2
#				,SUM(if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3) AND sex in(1) AND TIMESTAMPDIFF(year,birth,date_serv) in(12),height,0 )) A5Q1
#				,SUM(if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9) AND sex in(1) AND TIMESTAMPDIFF(year,birth,date_serv) in(12),height,0 )) A5Q2

#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3) AND sex in(2) AND TIMESTAMPDIFF(year,birth,date_serv) in(12) ,  CONCAT(n.HOSPCODE,'-',n.PID),NULL)) B4Q1
#				,COUNT(DISTINCT if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9) AND sex in(2) AND TIMESTAMPDIFF(year,birth,date_serv) in(12),  CONCAT(n.HOSPCODE,'-',n.PID),NULL)) B4Q2
#				,SUM(if(DATE_FORMAT(n.date_serv,'%m') IN(10,11,12,1,2,3) AND sex in(2) AND TIMESTAMPDIFF(year,birth,date_serv) in(12),height,0 )) A6Q1
#				,SUM(if(DATE_FORMAT(n.date_serv,'%m') IN(4,5,6,7,8,9) AND sex in(2) AND TIMESTAMPDIFF(year,birth,date_serv) in(12),height,0 )) A6Q2

#				FROM
#				_qof60_kpi09_t_nutrition_service6_14 n inner join chospital h on n.hospcode=h.hoscode
#				WHERE 
#				#h.provcode in(@prov_c)   AND 
#				TIMESTAMPDIFF(YEAR,n.birth,n.DATE_SERV) BETWEEN 6 AND 14
#				GROUP BY n.hospcode
#				);
