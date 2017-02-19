# QOF60 คัดกรองมะเร็งปาดมดลูกในสตรี 30 - 60 ปี 

#SET @prov_c := '23'; 
SET @b_year:= '2017' ;
SET @start_d:=concat(@b_year-1,'-04-01');
SET @end_d:=concat(@b_year,'-03-31');
SET @start_a:='2012-04-01';
SET @end_a:='2017-03-31';
SELECT  p.check_hosp,p.check_vhid 
, p.cid ,o.DATE_SERV ,o.DIAGCODE 
 
FROM t_person_db p LEFT JOIN 
(( 

SELECT z.cid,z.DIAGCODE,z.DATE_SERV,'DIAGNOSIS_OPD',z.HOSPCODE
FROM 
(
SELECT o.hospcode,o.pid,o.seq,o.date_serv,o.diagcode,p.cid
FROM diagnosis_opd o  INNER JOIN person p ON o.hospcode=p.hospcode AND o.pid=p.pid
WHERE o.DATE_SERV  BETWEEN @start_a AND  @end_a
AND SUBSTR(o.DIAGCODE,1,4) IN('Z014','Z124')
GROUP BY o.HOSPCODE,o.PID,o.SEQ ) z

WHERE z.DATE_SERV BETWEEN @start_a AND  @end_a  AND LENGTH(z.cid)=13
GROUP BY z.CID ) 
union
(SELECT cid,PPSPECIAL,DATE_SERV,'SPECIALPP',PPSPLACE
FROM tmp_specialpp s 
WHERE s.DATE_SERV BETWEEN @start_a AND  @end_a
AND SUBSTR(s.ppspecial,1,5) IN('1B004') AND LENGTH(cid)=13
GROUP BY CID )
) o 

ON o.CID=p.CID 
WHERE p.BIRTH BETWEEN '1956-04-01' AND '1981-03-31' AND p.sex IN(2) AND p.DISCHARGE IN(9) #AND p.nation IN(99)
#  AND p.check_typearea in(1,3)  
#AND substr(p.check_vhid,1,2)=@prov_c
GROUP BY p.check_hosp,p.check_vhid