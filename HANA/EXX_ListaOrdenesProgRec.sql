DROP PROCEDURE "EXX_ListaOrdenesProgRec";
CREATE PROCEDURE "EXX_ListaOrdenesProgRec"
	(IN FINI DATETIME,
	IN FFIN DATETIME,
	IN LORDER CHAR(1),
	IN RESCODE NVARCHAR(50),
	IN CODE NVARCHAR(50),
	IN NEWL INT)
AS
BEGIN
	IF :LORDER='E' THEN
		IF :NEWL=1 THEN
			INSERT INTO "@EXX_PROGOF" ("Code","Name",U_PROGCODE,U_VISORDER,U_DOCENTRY,U_STAGEID,U_RESCODE)
			select :CODE||TO_VARCHAR(ROW_NUMBER() over (order by T0."DueDate")) "Code",:CODE||TO_VARCHAR(ROW_NUMBER() over (order by T0."DueDate")) "Name",:CODE,
			ROW_NUMBER() over (order by T0."DueDate") "visorder",
			T0."DocEntry" "Order",T1."StageId",T1."ItemCode" "ResCode"
			from OWOR T0
			INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
			INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
			INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
			LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
			LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
			WHERE T0."Status"='R' AND T1."ItemType"=290 and T0."DueDate" between :FINI and :FFIN
			and T1."ItemCode" = :RESCODE
			ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
		END IF;
		select TT.U_VISORDER "Linenum",IFNULL(TT.U_CHECK,'N') "Check",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
		TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
		T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
		T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
		CASE WHEN IFNULL(U_STARTTIME,0)=0 THEN CASE T1."U_EXC_Programado" WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END ELSE '' END "StartTime",
		CASE WHEN IFNULL(U_FINISHTIME,0)=0 THEN CASE T1."U_EXC_Programado" WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END ELSE '' END "FinishTime",
		T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
		IFNULL(TO_VARCHAR(U_STARTDATE,103),CASE T1."U_EXC_Programado" WHEN 'N' THEN '' ELSE TO_VARCHAR("U_EXC_FProgam",'DD/MM/YYYY') END) "ProgramDate",
		TT."Code"
		from "@EXX_PROGOF" TT
		inner join OWOR T0 on TT.U_PROGCODE=:CODE AND T0."DocEntry"=TT.U_DOCENTRY
		INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry" AND T1."ItemCode"=TT.U_RESCODE AND T1."StageId"=TT.U_STAGEID
		INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
		INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
		LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
		LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
		WHERE T0."Status"='R' AND T1."ItemType"=290 and T0."DueDate" between :FINI and :FFIN
		and T1."ItemCode" = :RESCODE
		ORDER BY TT.U_VISORDER;
	ELSEIF :LORDER='P' THEN
		IF :NEWL=1 THEN
			INSERT INTO "@EXX_PROGOF" ("Code","Name",U_PROGCODE,U_VISORDER,U_DOCENTRY,U_STAGEID,U_RESCODE)
			select :CODE||TO_VARCHAR(ROW_NUMBER() over (order by T0."DueDate")) "Code",:CODE||TO_VARCHAR(ROW_NUMBER() over (order by T0."DueDate")) "Name",:CODE,
			ROW_NUMBER() over (order by T0."DueDate") "visorder",
			T0."DocEntry" "Order",T1."StageId",T1."ItemCode" "ResCode"
			from OWOR T0
			INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
			INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
			INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
			LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
			LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
			WHERE T0."Status"='R' AND T1."ItemType"=290 and T0."DueDate" between :FINI and :FFIN
			and T1."ItemCode" = :RESCODE
			ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
		END IF;
		select TT.U_VISORDER "Linenum",IFNULL(TT.U_CHECK,'N') "Check",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
		TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
		T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
		T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
		CASE WHEN IFNULL(U_STARTTIME,0)=0 THEN CASE T1."U_EXC_Programado" WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END ELSE '' END "StartTime",
		CASE WHEN IFNULL(U_FINISHTIME,0)=0 THEN CASE T1."U_EXC_Programado" WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END ELSE '' END "FinishTime",
		T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
		IFNULL(TO_VARCHAR(U_STARTDATE,103),CASE T1."U_EXC_Programado" WHEN 'N' THEN '' ELSE TO_VARCHAR("U_EXC_FProgam",103) END) "ProgramDate",
		TT."Code"
		from "@EXX_PROGOF" TT
		inner join OWOR T0 on TT.U_PROGCODE=:CODE AND T0."DocEntry"=TT.U_DOCENTRY
		INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry" AND T1."ItemCode"=TT.U_RESCODE AND T1."StageId"=TT.U_STAGEID
		INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
		INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
		LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
		LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
		WHERE T0."Status"='R' AND T1."ItemType"=290 and T0."DueDate" between :FINI and :FFIN
		and T1."ItemCode" = :RESCODE
		ORDER BY TT.U_VISORDER,T0."Priority",T0."DocEntry",T1."StageId";
	END IF;
END;