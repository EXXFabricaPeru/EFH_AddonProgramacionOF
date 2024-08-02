DROP PROCEDURE "EXC_DisponibilidadRecursos";
CREATE PROCEDURE "EXC_DisponibilidadRecursos"
	(IN FECHA DATETIME,
	IN ITEMCODE NVARCHAR(50))
AS
BEGIN
	SELECT T4."StartDate", SUM(T6."CapTotal")- SUM(T1."PlannedQty") "Disponible",MAX(T1."U_EXC_HoraFin") "HoraFin"
	FROM OWOR T0
	INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
	INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
	INNER JOIN RSC6 T6 ON T1."ItemCode"=T6."ResCode" AND "WeekDay"=WEEKDAY(T4."StartDate")
	WHERE T1."ItemType"=290
	and T4."StartDate">=:FECHA AND T1."ItemCode"=:ITEMCODE
	AND T0."Status"='R'
	AND IFNULL(T1."U_EXC_Programado",'N')='Y'
	GROUP BY T4."StartDate"
	HAVING SUM(T6."CapTotal")- SUM(T1."PlannedQty")>0
	ORDER BY T4."StartDate";
	
END;