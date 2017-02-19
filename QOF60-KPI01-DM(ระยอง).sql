SET @b_year:=(SELECT yearprocess FROM sys_config LIMIT 1); 
SET @start_d:=concat(@b_year-1,'-04-01'); 
SET @end_d:=concat(@b_year,'-03-31'); 
SET @start_a:='1941-04-01'; 
SET @end_a:='1981-03-31'; 

SELECT DM_Screen.*
/*HOSPCODE
,COUNT(cid) B1 
,COUNT(if(bslevel>0 ,CONCAT(bslevel) ,NULL)) A1 
,COUNT(if(bslevel>=100 ,CONCAT(bslevel) ,NULL)) B2 
,COUNT(type_dx) A2 
*/

FROM (SELECT B1.hospcode,B1.cid,min(A1.date_serv) First_screen,A1.bslevel,A2.type_dx

		FROM (SELECT  check_hosp HOSPCODE ,check_vhid as areacode ,CID,PID 
			FROM  t_person_db 
			where BIRTH BETWEEN @start_a and @end_a 
				and NATION='099'
				and cid is not null and left(cid,1)<>'0' and LENGTH(TRIM(cid))=13
				and cid not in(SELECT cid FROM t_dmht WHERE type_dx in(2,3) and left(date_dx,10) < @start_d) 
		) B1 

LEFT JOIN 
(SELECT hospcode,pid,date_serv,bstest, bslevel 
 FROM ncdscreen 
 WHERE DATE_SERV BETWEEN @start_d and @end_d 
  and (BSTEST in(1,2,3,4) and BSLEVEL > 0) 
 GROUP BY CONCAT(hospcode,pid) 
) A1 ON B1.HOSPCODE=A1.HOSPCODE and B1.PID=A1.PID 

LEFT JOIN 
(SELECT HOSPCODE,PID,cid,type_dx,date_dx 
 FROM t_dmht 
 WHERE type_dx in(2,3) and left(date_dx,10) BETWEEN @start_d and @end_d 
) A2 ON A1.HOSPCODE=A2.HOSPCODE and A1.PID=A2.PID and A1.BSLEVEL >= 100 

GROUP BY B1.cid

)DM_Screen


;