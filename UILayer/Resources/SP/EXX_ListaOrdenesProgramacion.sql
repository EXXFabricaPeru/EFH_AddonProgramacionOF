--call "EXX_ListaOrdenesProgramacion" ('20240801','20241102','E',0,'*', 'I001', '')
--call "EXX_ListaOrdenesProgramacion" ('20240718','20240719','E',0,'Y', 'SP015', '') --solo programados
--call "EXX_ListaOrdenesProgramacion" ('20240718','20240719','E',0,'N', 'S010', '') -- solo no programados
--call "EXX_ListaOrdenesProgramacion" ('20240818','20240930','E',0,'*', 'E001', '') -- todos

ALTER PROCEDURE "EXX_ListaOrdenesProgramacion"
(	IN FINI DATETIME,
	IN FFIN DATETIME,
	IN ORDERL CHAR(1),
	IN ORDERENTRY INT,
	IN VISUAL CHAR(1),
	IN RECURSO NVARCHAR(50),
	IN RAZON NVARCHAR(50)
)
AS
BEGIN

	declare FiltroFecha int;
	declare FiltroOrden int;
	declare FiltroRecurso int;
	declare TipoRecurso int;
	declare FiltroRazon int;
	declare Programado int;
	
	IF(VISUAL = 'Y') THEN
		Programado :=0;
	ELSE
		Programado :=1;
	END IF;
	
	IF(RAZON <> '') THEN
		FiltroRazon := 1;
	ELSE
		FiltroRazon := 0;
	END IF;
	
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
	
	IF :TipoRecurso = 6 THEN --Extrusora

			IF :VISUAL='*' OR :VISUAL='Y' THEN
			IF :Programado = 1 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" = T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Extrusora' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
					union all
				select 'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" = T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1,-1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",
					'Extrusora' "Etapa"
					
					from OWOR T0
					INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
					INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
					INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
					LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
					LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
					WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
					AND ((:Programado = 1 AND IFNULL(T1."U_EXC_Programado",'N')='N') OR :Programado = 0) 
		    		AND	T1."ItemCode" = :RECURSO AND
					((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				)			;--ORDER BY "ProgramDate","StartTime","DelivDate","Order","StageId";
			ELSEIF :Programado = 0 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Extrusora' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				);
			END IF;
		ELSE
	
			IF :ORDERL='E' THEN
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",  0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				--T1."U_EXP_KGFOR" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Extrusora' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			ELSEIF :ORDERL='P' THEN
				select ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" = T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				--T1."U_EXP_KGFOR" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Extrusora' "Etapa"
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
			END IF;
		END IF;
		----------------------------------------------------------------------------------------------------
	ELSEIF :TipoRecurso = 8 THEN --IMPRESORA
		IF :VISUAL='*' OR :VISUAL='Y' THEN
			IF :Programado = 1 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",	
					T1."U_EXX_DANULA" "Anulado",
					'Impresora' "Etapa"
					
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND				
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
					union all
				select 'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" = T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",
					'Impresora' "Etapa"
					
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				)			;--ORDER BY "ProgramDate","StartTime","DelivDate","Order","StageId";
			ELSEIF :Programado = 0 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Impresora' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				);
				END IF;
		ELSE
	
			IF :ORDERL='E' THEN
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",  0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" = T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Impresora' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			ELSEIF :ORDERL='P' THEN
				select ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Impresora' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
			END IF;
		END IF;
		
		--------------------------------------------------------------------------------------------------
		
	ELSEIF :TipoRecurso = 9 THEN --LAMINADO
		IF :VISUAL='*' OR :VISUAL='Y' THEN
			IF :Programado = 1 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Laminado' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
					union all
				select 'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",
					'Laminado' "Etapa"
					
					from OWOR T0
					INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
					INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
					INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
					LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
					LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
					WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
					AND ((:Programado = 1 AND IFNULL(T1."U_EXC_Programado",'N')='N') OR :Programado = 0) 
		    		AND	T1."ItemCode" = :RECURSO AND
					((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				)			;--ORDER BY "ProgramDate","StartTime","DelivDate","Order","StageId";
			ELSEIF :Programado = 0 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" = T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Laminado' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				);
			END IF;
		ELSE
	
			IF :ORDERL='E' THEN
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",  0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Laminado' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			ELSEIF :ORDERL='P' THEN
				select ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Laminado' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
			END IF;
		END IF;
		
		--------------------------------------------------------------------------------------------------------
		
	ELSEIF :TipoRecurso = 4 THEN --SELLADO
		IF :VISUAL='*' OR :VISUAL='Y' THEN
			IF :Programado = 1 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",	
					T1."U_EXX_DANULA" "Anulado",
					'Sellado' "Etapa"
					
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND				
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
					union all
				select 'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",
					'Sellado' "Etapa"
					
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				)			;--ORDER BY "ProgramDate","StartTime","DelivDate","Order","StageId";
			ELSEIF :Programado = 0 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Sellado' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				);
				END IF;
		ELSE
	
			IF :ORDERL='E' THEN
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",  0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Sellado' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			ELSEIF :ORDERL='P' THEN
				select ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Sellado' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
			END IF;
		END IF;
		
		-----------------------------------------------------------------------------------------------------
		
	ELSEIF :TipoRecurso = 5 THEN --CORTE
		IF :VISUAL='*' OR :VISUAL='Y' THEN
			IF :Programado = 1 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Corte' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
					union all
				select 'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",
					'Corte' "Etapa"
					
					from OWOR T0
					INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
					INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
					INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
					LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
					LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
					WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
					AND ((:Programado = 1 AND IFNULL(T1."U_EXC_Programado",'N')='N') OR :Programado = 0) 
		    		AND	T1."ItemCode" = :RECURSO AND
					((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				)			;--ORDER BY "ProgramDate","StartTime","DelivDate","Order","StageId";
			ELSEIF :Programado = 0 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Corte' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				);
			END IF;
		ELSE
	
			IF :ORDERL='E' THEN
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",  0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Corte' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			ELSEIF :ORDERL='P' THEN
				select ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Corte' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
			END IF;
		END IF;
		
		-------------------------------------------------------------------------------------------------------
		
	ELSEIF :TipoRecurso = 7 THEN --HABILITADORA
		IF :VISUAL='*' OR :VISUAL='Y' THEN
			IF :Programado = 1 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Habilitadora' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
					union all
				select 'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",
					'Habilitadora' "Etapa"
					
					from OWOR T0
					INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
					INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
					INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
					LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
					LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
					WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
					AND ((:Programado = 1 AND IFNULL(T1."U_EXC_Programado",'N')='N') OR :Programado = 0) 
		    		AND	T1."ItemCode" = :RECURSO AND
					((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				)			;--ORDER BY "ProgramDate","StartTime","DelivDate","Order","StageId";
			ELSEIF :Programado = 0 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Habilitadora' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				);
			END IF;
		ELSE
	
			IF :ORDERL='E' THEN
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",  0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Habilitadora' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			ELSEIF :ORDERL='P' THEN
				select ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Habilitadora' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
			END IF;
		END IF;
		
		--------------------------------------------------------------------------------------------------------------
		
	ELSEIF :TipoRecurso = 3 THEN --REBOBINADO
		IF :VISUAL='*' OR :VISUAL='Y' THEN
			IF :Programado = 1 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Rebobinado' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
					union all
				select 'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",
					'Rebobinado' "Etapa"
					
					from OWOR T0
					INNER JOIN WOR1 T1 ON T0."DocEntry"=T1."DocEntry"
					INNER JOIN WOR4 T4 ON T0."DocEntry"=T4."DocEntry" and T4."StageId"=T1."StageId"
					INNER JOIN OITM TM ON T0."ItemCode"=TM."ItemCode"
					LEFT JOIN ORSC T2 ON T1."ItemCode"=T2."ResCode"
					LEFT JOIN OCRD T3 ON T0."CardCode"=T3."CardCode"
					WHERE T0."Status"='R' AND T1."ItemType"=290 --and T0."DueDate" between :FINI and :FFIN
					AND ((:Programado = 1 AND IFNULL(T1."U_EXC_Programado",'N')='N') OR :Programado = 0) 
		    		AND	T1."ItemCode" = :RECURSO AND
					((:FiltroOrden = 1 AND T0."DocEntry" = :ORDERENTRY) OR :FiltroOrden = 0) AND
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				)			;--ORDER BY "ProgramDate","StartTime","DelivDate","Order","StageId";
			ELSEIF :Programado = 0 THEN
				select ROW_NUMBER() over (order by "SelOrder") "Linenum",* from
				(
				select 'Y' "Check", 
				ROW_NUMBER() over (order by "U_EXC_FProgam","U_EXC_HoraIni") "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
					TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
					T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
					T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
					T0."Uom" "UOM",
					(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
					--T1."PlannedQty" "ReqQuant",
					--T1."U_EXP_KGFOR" "ReqQuant",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
					CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
					T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
					CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
					T1."U_EXX_DSTANDBY" "Standby",
					T1."U_EXX_DPARCIAL" "Parcial",
					T1."U_EXX_DTERMIN" "Terminado",
					T1."U_EXX_DANULA" "Anulado",	
					'Rebobinado' "Etapa"
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
					((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND
											
					((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				);
			END IF;
		ELSE
	
			IF :ORDERL='E' THEN
				select ROW_NUMBER() over (order by T0."DueDate",T0."DocEntry",T1."StageId") "Linenum",'N' "Check",  0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t2."TimeResUn"*t1."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Rebobinado' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				
				ORDER BY T0."DueDate",T0."DocEntry",T1."StageId";
			ELSEIF :ORDERL='P' THEN
				select ROW_NUMBER() over (order by T0."Priority" desc,T0."DocEntry",T1."StageId") "Linenum",'N' "Check", 0 "SelOrder",T0."DocEntry" "OrderDE",T0."DocNum" "Order",T1."ItemCode" "ResCode",T2."ResName" "Resource",
				TO_VARCHAR(TO_TIME(ADD_SECONDS (TO_TIMESTAMP ('2021-01-01 00:00:00'), t1."BaseQty"*t2."TimeResUn"*t0."PlannedQty"))) "Hours",
				T4."StartDate",T4."EndDate" "FinishDate",IFNULL(T1."U_EXC_Programado",'N') "Scheduled",'' "Overlap", T0."Priority" "Priority",T0."DueDate" "DelivDate",T3."CardCode",
				T3."CardName" "Customer",T0."ItemCode",TM."ItemName" "Product",
				T0."Uom" "UOM",
				(select sum(W0."U_EXP_CANTREQ") from WOR1 W0 
						WHERE W0."DocEntry" = T0."DocEntry" 
						AND W0."ItemCode" NOT IN (:RECURSO)
						AND W0."StageId" =  T1."StageId"
						AND W0."U_EXP_CANTREQ" NOT IN (1, -1)
						AND W0."U_EXP_CANTREQ" > 0) "ReqQuant",
				--T1."PlannedQty" "ReqQuant",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraIni"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraIni"),2) END "StartTime",
				CASE T1."U_EXC_Programado" WHEN 'N' THEN '00:00' ELSE LEFT(RIGHT('000'||TO_VARCHAR("U_EXC_HoraFin"),4),2)||':'||RIGHT('0'||TO_VARCHAR("U_EXC_HoraFin"),2) END "FinishTime",
				T1."PlannedQty",T1."VisOrder" "OLineNum",T2."TimeResUn",T1."StageId",t4."StgEntry",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE "U_EXC_FProgam" END "ProgramDate",
				CASE IFNULL(T1."U_EXC_Programado", 'N') WHEN 'N' THEN NULL ELSE T1."U_EXC_FPROGF" END  "ProgramDateEnd",
				T1."U_EXX_DSTANDBY" "Standby",
				T1."U_EXX_DPARCIAL" "Parcial",
				T1."U_EXX_DTERMIN" "Terminado",
				T1."U_EXX_DANULA" "Anulado",
				'Rebobinado' "Etapa"
				
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
				((:FiltroRazon = 1 AND T0."CardCode" = :RAZON) OR :FiltroRazon = 0) AND							
				((:FiltroFecha = 3 AND T0."DueDate" >= :FINI) OR (:FiltroFecha = 2 AND T0."DueDate" <= :FFIN) OR (:FiltroFecha = 1 AND T0."DueDate" between :FINI and :FFIN) OR (:FiltroFecha = 0))
				ORDER BY T0."Priority" desc,T0."DocEntry",T1."StageId";
			END IF;
		END IF;
	END IF;
	END;