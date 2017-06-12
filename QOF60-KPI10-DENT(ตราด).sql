SET @b_year:=(SELECT yearprocess FROM sys_config LIMIT 1);
SET @start_d:=concat(@b_year-1,'-04-01');
SET @end_d:=concat(@b_year,'-03-31');

SELECT
 p.HOSPCODE,s.cid, p.PID,p.SEQ,p.DATE_SERV,p.PROCEDCODE ,s.TYPEAREA, s.nation ,s.DISCHARGE
 FROM procedure_opd p
   INNER JOIN cwh_dent_icd10tm i ON p.PROCEDCODE=i.ICD10TM 
   INNER JOIN 
   ( SELECT
    se.HOSPCODE ,se.pid ,se.SEQ ,se.DATE_SERV ,c.cid, c.TYPEAREA ,c.nation ,c.DISCHARGE
   FROM service se
   INNER JOIN t_person_cid c on se.HOSPCODE = c.HOSPCODE and se.PID = c.PID 
   INNER JOIN dbpop d on d.PID = c.CID
   WHERE  DATE_FORMAT(se.date_serv,'%Y%m%d') BETWEEN @start_d AND @end_d  
  ) s ON p.hospcode=s.hospcode AND p.PID = s.PID AND p.SEQ=s.SEQ
 WHERE DATE_FORMAT(p.date_serv,'%Y%m%d')  BETWEEN  @start_d AND @end_d
