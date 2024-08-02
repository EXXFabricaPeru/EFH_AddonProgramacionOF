DROP PROCEDURE "EXX_ListaOrdenesProgramacion";
CREATE PROCEDURE "EXX_ListaOrdenesProgramacion"
(	IN FINI DATETIME,
	IN FFIN DATETIME,
	IN ORDERL CHAR(1),
	IN ORDERENTRY INT,
	IN VISUAL CHAR(1),
	IN RECURSO NVARCHAR(50)
)
AS
BEGIN

	declare FiltroFecha int;
	declare FiltroOrden int;
	declare FiltroRecurso int;
	declare TipoRecurso int;

	IF(RECURSO <> '') THEN
		FiltroRecurso := 1;
	ELSE
		FiltroRecurso := 0;
	END IF;

	IF(ORDERENTRY <> 0) THEN
		FiltroOrden := 1;
	ELSE
		FiltroOrden := 0;
	END IF;

	IF(FINI = '' AND FFIN = '') THEN
		FiltroFecha := 0 ;
	END IF;
	
	IF(FINI <> '' AND FFIN <> '') THEN
		FiltroFecha := 1;
	END IF;

	IF(FINI = '' AND FFIN <> '') THEN 
		FiltroFecha := 2 ;
	END IF;

	IF(FINI <> '' AND FFIN = '') THEN
		FiltroFecha := 3 ;
	END IF;
	
	SELECT T0."ResGrpCod" 
	INTO TipoRecurso
	FROM ORSC T0 WHERE T0."VisResCode" = :RECURSO; 
	
	
	/*IF :ORDERL='E' THEN
		
		IF :TipoRecurso = 6 THEN --Extrusora

				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_UNANC" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Ancho",
				(SELECT "U_EXP_OLLA" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Ancho",
				(SELECT "U_EXP_PESBOB" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Peso Bobina",
				(SELECT "U_EXP_MANG" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Manga",
				(SELECT "U_EXP_TPMANGA" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Tipo de Manga",
				(SELECT "U_EXP_LAMI" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Lamina",
				(SELECT "U_EXP_TRAT" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Tratada",
				(SELECT "U_EXP_MATE" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_CRIS" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Cristal",
				(SELECT "U_EXP_RECP" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Recuperado",
				(SELECT "U_EXP_FUEL" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Fuelle",
				(SELECT "U_EXP_MICR" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Microperforado",
				(SELECT "U_EXP_GOFR" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Gofrado",
				(SELECT "U_EXP_TERMC" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Termocontraible",
				(SELECT "U_EXP_COLOR" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Color",
				(SELECT "U_EXP_CLOS" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Cerrada",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
				
			ELSEIF :TipoRecurso = 8 THEN --IMPRESORA

				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT  "U_EXP_MPRIMA" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Materia Prima",
				(SELECT  "U_EXP_SIDES" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Caras",
				(SELECT  "U_EXP_BAND" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Bandas",
				(SELECT  "U_EXP_REPT" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Repeticiones",
				(SELECT  "U_EXP_MTRL" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Material",
				(SELECT  "U_EXP_NROC" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Nro Cilindro mm",
				(SELECT  "U_EXP_DESA" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Desarrollo mm",
				(SELECT  "U_EXP_TIPIM" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Tipo Imp.",
				(SELECT  "U_EXP_ESPESOR" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Espesor",
				(SELECT  "U_EXP_UNESP" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Und. Espesor",
				(SELECT  "U_EXP_SENTIDO" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Sentido Imp.",
				(SELECT  "U_EXP_NCOL" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Nro Colores",
				(SELECT  "U_EXP_COLOR1" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 1",
				(SELECT  "U_EXP_TITIN1" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Tipo Tinta 1",
				(SELECT  "U_EXP_COLOR2" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 2",
				(SELECT  "U_EXP_COLOR3" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 3",
				(SELECT  "U_EXP_COLOR4" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 4",
				(SELECT  "U_EXP_COLOR5" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 5",
				(SELECT  "U_EXP_COLOR6" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 6",
				(SELECT  "U_EXP_COLOR7" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 7",
				(SELECT  "U_EXP_COLOR8" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 8",
				(SELECT  "U_EXP_TITIN8" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Tipo Tinta 8",
				(SELECT  "U_EXP_MERMA" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Merma %",
				(SELECT  "U_EXP_OBSV" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
				
			ELSEIF :TipoRecurso = 9 THEN --LAMINADO
			 
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Material",
				(SELECT "U_EXP_UNESP" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Unidad Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Merma",
				(SELECT "U_EXP_MPRIM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Material 2",
				(SELECT "U_EXP_MTRLM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Material",
				(SELECT "U_EXP_UNESPM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Und. Espesor",
				(SELECT "U_EXP_ESPESM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Espesor",
				(SELECT "U_EXP_MERMAM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
				
			ELSEIF :TipoRecurso = 4 THEN --SELLADO
			
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_TROQUEL" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Troquel",
				(SELECT "U_EXP_ZIPPER" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Zipper",
				(SELECT "U_EXP_MUESCA" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Muesca",
				(SELECT "U_EXP_PESTANA" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Pestaña",
				(SELECT "U_EXP_CICIBO" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Cinta Cierrabolsa",
				(SELECT "U_EXP_PRCORTE" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Precorte",
				(SELECT "U_EXP_TSELLO" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "T. Sel. 1",
				(SELECT "U_EXP_TSELL2" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "T. Sel. 2",
				(SELECT "U_EXP_FUELLE" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Fuelle",
				(SELECT "U_EXP_UNFUEL" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Un. Fuelle",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Un. Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			
			ELSEIF :TipoRecurso = 5 THEN --CORTE
			
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MEDCRT" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Medida Corte",
				(SELECT "U_EXP_SENTIDO" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Sentido",
				(SELECT "U_EXP_DIAMT" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Diámetro",
				(SELECT "U_EXP_ANCHO" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Ancho Original",
				(SELECT "U_EXP_TUCO" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Tuco",
				(SELECT "U_EXP_PESKG" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Peso Kilo",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			
			ELSEIF :TipoRecurso = 7 THEN --HABILITADORA
			
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MEDCRT" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Medida Corte",
				(SELECT "U_EXP_DIAMT" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Diámetro",
				(SELECT "U_EXP_SENTIDO" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Sentido",
				(SELECT "U_EXP_ANCHO" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Ancho Original",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId"; 
			
			ELSEIF :TipoRecurso = 3 THEN --REBOBINADO
			
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MEDCRT" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Medida Corte",
				(SELECT "U_EXP_DIAMT" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Diámetro",
				(SELECT "U_EXP_SENTIDO" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Sentido",
				(SELECT "U_EXP_ANCHO" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Ancho Original",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
		
		END IF;

	ELSEIF :ORDERL='P' THEN
	
		IF :TipoRecurso = 6 THEN --Extrusora
		
				SELECT ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_UNANC" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Ancho",
				(SELECT "U_EXP_OLLA" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Ancho",
				(SELECT "U_EXP_PESBOB" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Peso Bobina",
				(SELECT "U_EXP_MANG" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Manga",
				(SELECT "U_EXP_TPMANGA" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Tipo de Manga",
				(SELECT "U_EXP_LAMI" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Lamina",
				(SELECT "U_EXP_TRAT" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Tratada",
				(SELECT "U_EXP_MATE" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_CRIS" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Cristal",
				(SELECT "U_EXP_RECP" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Recuperado",
				(SELECT "U_EXP_FUEL" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Fuelle",
				(SELECT "U_EXP_MICR" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Microperforado",
				(SELECT "U_EXP_GOFR" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Gofrado",
				(SELECT "U_EXP_TERMC" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Termocontraible",
				(SELECT "U_EXP_COLOR" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Color",
				(SELECT "U_EXP_CLOS" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Cerrada",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FREXTR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290-- and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
				
			ELSEIF :TipoRecurso = 8 THEN --IMPRESORA

				SELECT ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT  "U_EXP_MPRIMA" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Materia Prima",
				(SELECT  "U_EXP_SIDES" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Caras",
				(SELECT  "U_EXP_BAND" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Bandas",
				(SELECT  "U_EXP_REPT" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Repeticiones",
				(SELECT  "U_EXP_MTRL" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Material",
				(SELECT  "U_EXP_NROC" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Nro Cilindro mm",
				(SELECT  "U_EXP_DESA" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Desarrollo mm",
				(SELECT  "U_EXP_TIPIM" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Tipo Imp.",
				(SELECT  "U_EXP_ESPESOR" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Espesor",
				(SELECT  "U_EXP_UNESP" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Und. Espesor",
				(SELECT  "U_EXP_SENTIDO" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Sentido Imp.",
				(SELECT  "U_EXP_NCOL" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Nro Colores",
				(SELECT  "U_EXP_COLOR1" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 1",
				(SELECT  "U_EXP_TITIN1" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Tipo Tinta 1",
				(SELECT  "U_EXP_COLOR2" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 2",
				(SELECT  "U_EXP_COLOR3" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 3",
				(SELECT  "U_EXP_COLOR4" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 4",
				(SELECT  "U_EXP_COLOR5" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 5",
				(SELECT  "U_EXP_COLOR6" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 6",
				(SELECT  "U_EXP_COLOR7" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 7",
				(SELECT  "U_EXP_COLOR8" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Color 8",
				(SELECT  "U_EXP_TITIN8" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Tipo Tinta 8",
				(SELECT  "U_EXP_MERMA" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Merma %",
				(SELECT  "U_EXP_OBSV" FROM "@EXP_FRIMPR" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290-- and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
				 
			ELSEIF :TipoRecurso = 9 THEN --LAMINADO
 
				SELECT ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Material",
				(SELECT "U_EXP_UNESP" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Unidad Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Merma",
				(SELECT "U_EXP_MPRIM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Material 2",
				(SELECT "U_EXP_MTRLM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Material",
				(SELECT "U_EXP_UNESPM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Und. Espesor",
				(SELECT "U_EXP_ESPESM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Espesor",
				(SELECT "U_EXP_MERMAM2" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "M2: Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_LAMINA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO)  "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290-- and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
				 
			ELSEIF :TipoRecurso = 4 THEN --SELLADO
			
				SELECT ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_TROQUEL" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Troquel",
				(SELECT "U_EXP_ZIPPER" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Zipper",
				(SELECT "U_EXP_MUESCA" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Muesca",
				(SELECT "U_EXP_PESTANA" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Pestaña",
				(SELECT "U_EXP_CICIBO" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Cinta Cierrabolsa",
				(SELECT "U_EXP_PRCORTE" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Precorte",
				(SELECT "U_EXP_TSELLO" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "T. Sel. 1",
				(SELECT "U_EXP_TSELL2" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "T. Sel. 2",
				(SELECT "U_EXP_FUELLE" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Fuelle",
				(SELECT "U_EXP_UNFUEL" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Un. Fuelle",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Un. Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_FRSELA" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290-- and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
				 
			ELSEIF :TipoRecurso = 5 THEN --CORTE
			 
				SELECT ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MEDCRT" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Medida Corte",
				(SELECT "U_EXP_SENTIDO" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Sentido",
				(SELECT "U_EXP_DIAMT" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Diámetro",
				(SELECT "U_EXP_ANCHO" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Ancho Original",
				(SELECT "U_EXP_TUCO" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Tuco",
				(SELECT "U_EXP_PESKG" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Peso Kilo",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_FRCORT" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290-- and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
				 
			ELSEIF :TipoRecurso = 7 THEN --HABILITADORA
			
				SELECT ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MEDCRT" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Medida Corte",
				(SELECT "U_EXP_DIAMT" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Diámetro",
				(SELECT "U_EXP_SENTIDO" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Sentido",
				(SELECT "U_EXP_ANCHO" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Ancho Original",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_FRHABI" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290-- and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
				 
			ELSEIF :TipoRecurso = 3 THEN --REBOBINADO
			
				SELECT ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				(SELECT "U_EXP_VELMAQ" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Vel. Maquina",
				(SELECT "U_EXP_TPOPRE" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Preparacion",
				(SELECT "U_EXP_MEDCRT" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Medida Corte",
				(SELECT "U_EXP_DIAMT" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Diámetro",
				(SELECT "U_EXP_SENTIDO" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Sentido",
				(SELECT "U_EXP_ANCHO" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Ancho Original",
				(SELECT "U_EXP_MPRIMA" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Materia Prima",
				(SELECT "U_EXP_MTRL" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Material",
				(SELECT "U_EXP_UNESP" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Und. Espesor",
				(SELECT "U_EXP_ESPESOR" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Espesor",
				(SELECT "U_EXP_MERMA" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Merma",
				(SELECT "U_EXP_OBSV" FROM "@EXP_FRREBO" WHERE "Code" like T0."ItemCode"||'%' and "U_EXP_RECMAQ" = :RECURSO) "Observación"
				from OWOR T0
				INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
				INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
				INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
				LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
				LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
				WHERE T0."Status"='R' AND T1."ItemType"=290-- and T0."DueDate" between :FINI and :FFIN
				--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
				and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
				((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
				((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";

		END IF;
			
	END IF;
	*/

	IF :VISUAL='*' OR :VISUAL='Y' THEN
		select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
		(
		select 'Y' "Check",ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
			TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
			T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
			T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
			T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
			CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
			CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
			T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
			CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
			CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd"
			from OWOR T0
			INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
			INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
			INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
			LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
			LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
			WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
			AND IFNULL(T1."U_EXC_Programado",'N')='Y'
    		AND	T1."ItemCode" = :RECURSO AND
			((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
			((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
			union all
		select 'N' "Check",0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
			TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
			T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
			T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
			T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
			CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
			CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
			T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
			CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
			CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd"
			from OWOR T0
			INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
			INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
			INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
			LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
			LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
			WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
			AND IFNULL(T1."U_EXC_Programado",'N')='N'
    		AND	T1."ItemCode" = :RECURSO AND
			((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
			((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
		)			;--ORDER BY "ProgramDate","StartTime","DelivDate","Order","StageId";
	ELSE

		IF :ORDERL='E' THEN
			select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
			TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
			T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
			T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
			T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
			CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
			CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
			T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
			CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
			CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd"
			from OWOR T0
			INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
			INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
			INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
			LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
			LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
			WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
			--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
			and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
			((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
			((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
			((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
			
			ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
		ELSEIF :ORDERL='P' THEN
			select ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check",0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
			TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
			T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
			T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
			T0."Uom" "UOM",T0."PlannedQty" "ReqQuant",
			CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
			CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
			T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
			CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
			CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd"
			from OWOR T0
			INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
			INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
			INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
			LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
			LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
			WHERE T0."Status"='R' AND T1."ItemType"=290-- and T0."DueDate" between :FINI and :FFIN
			--and (:ORDERENTRY=0 or T0."DocEntry"=:ORDERENTRY)
			and (:VISUAL='*' or IFNULL(T1."U_EXC_Programado",'N')=:VISUAL) AND
			((:FiltroRecurso = 1 AND T1."ItemCode" = :RECURSO) OR :FiltroRecurso = 0) AND
			((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND							
			((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
			ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
		END IF;
	END IF;
END;