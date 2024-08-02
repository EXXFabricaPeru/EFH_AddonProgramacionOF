DROP PROCEDURE "EXX_DisponibilidadRecursos";
CREATE PROCEDURE "EXX_DisponibilidadRecursos"
	(IN FECHA DATETIME,
	IN RESCODE NVARCHAR(50),
	IN CODE NVARCHAR(50))
AS
BEGIN

	TABLA0=
	SELECT T1."U_EXC_FProgam" "StartDate", T6."CapTotal"-T1."PlannedQty" "Disponible",T1."U_EXC_HoraFin" "HoraFin"
	FROM OWOR T0
	INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
	INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
	INNER JOIN RSC6 T6 ON T1."ItemCode"=T6."ResCode" AND "WeekDay"=WEEKDAY(T4."StartDate")
	WHERE T1."ItemType"=290
	and T1."U_EXC_FProgam">=:FECHA AND T1."ItemCode"=:RESCODE AND T1."U_EXC_Programado"='Y'
	AND T0."Status"='R'
	AND IFNULL(T1."U_EXC_Programado",'N')='Y'
	UNION ALL
	SELECT T0.U_STARTDATE "StartDate", T6."CapTotal"-T1."PlannedQty" "Disponible",T0.U_FINISHTIME "HoraFin"
	FROM "@EXX_PROGOF" T0
	INNER JOIN WOR1 T1 ON T0.U_DOCENTRY=T1."DocEntry" and T1."ItemCode"=T0.U_RESCODE and T1."StageId"=T0.U_STAGEID
	INNER JOIN RSC6 T6 ON T0.U_RESCODE=T6."ResCode" AND "WeekDay"=WEEKDAY(T0."U_STARTDATE")
	WHERE T0.U_PROGCODE=:CODE
	and T0.U_STARTDATE>=:FECHA AND T0.U_RESCODE=:RESCODE;
	
	SELECT T0."StartDate",SUM(T0."Disponible") "Disponible", MAX(T0."HoraFin") "HoraFin"
	FROM :TABLA0 T0
	GROUP BY T0."StartDate"
	HAVING SUM(T0."Disponible")>0
	ORDER BY T0."StartDate";
	
END;