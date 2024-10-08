ALTER PROCEDURE "EXX_ValidarStage"
	(IN DOCENTRY INT,
	IN SEQNUM INT)
AS
BEGIN
	--SELECT COUNT(0) FROM WOR1 WHERE "DocEntry" = DOCENTRY AND "StageId" < SEQNUM AND "U_EXC_Programado"='N' AND "ItemType"=290;
	SELECT IFNULL((SELECT CASE WHEN IFNULL(I."U_EXP_TIPPROD",0)<>2 THEN COUNT(0) ELSE 
	CASE  WHEN SEQNUM<=2 THEN 0 ELSE COUNT(0) END END FROM WOR1 W1
	INNER JOIN "OWOR" W ON W."DocEntry"=W1."DocEntry"
	INNER JOIN "OITM" I ON I."ItemCode"=W."ItemCode"
	WHERE W1."DocEntry" = DOCENTRY AND W1."StageId" < SEQNUM AND W1."U_EXC_Programado"='N' AND W1."ItemType"=290
	GROUP BY I."U_EXP_TIPPROD"),0) from dummy;
END;



