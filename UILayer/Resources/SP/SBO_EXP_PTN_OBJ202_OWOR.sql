ALTER PROCEDURE "SBO_EXP_PTN_OBJ202_OWOR"
(
	IN docEntry integer
	, IN transaction_type nchar(1)
	, OUT error integer
	, OUT error_message nvarchar(200)
)
LANGUAGE SQLSCRIPT AS

NumeroSAP int;
NumDocumentoBase int;
Estado varchar(1); 
Cliente varchar(30); 
Almacen varchar(30);
DocumentoBase varchar(1);
FechaEntrega date;
Articulo varchar(30);
ARTICULO2 nvarchar(60);
CANTIDAD decimal (19,6);
DOCENTRYOV int;
SN nvarchar(60);
DOCNUMOT INT;
FechaEntregaLinea date;
Formula nvarchar(30);




BEGIN
		
		SELECT "DocNum", "Status", "CardCode", "Warehouse", "OriginType", "OriginNum", "DueDate", "ItemCode"
		INTO NumeroSAP, Estado, Cliente, Almacen, DocumentoBase, NumDocumentoBase, FechaEntrega, Articulo
		FROM OWOR 
		WHERE "DocEntry" = :docEntry;

		
		----------------------VALIDAR QUE TENGA INDICADOR----------------------
		
		IF IFNULL(:DocumentoBase,'') <> '' THEN
			IF :DocumentoBase = 'S' THEN
				UPDATE RDR1 SET "U_EXP_OTPROD" = :NumeroSAP
				WHERE "DocEntry"||"LineNum" = 
				(SELECT T1."DocEntry"||T1."LineNum" 
				FROM ORDR T0  INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry" 
				WHERE T0."DocNum" = :NumDocumentoBase 
				AND   T0."CardCode" = :Cliente 
				AND T1."ItemCode" = :Articulo 
				AND  to_date(T1."ShipDate") = to_date(:FechaEntrega));
			END IF;
		END IF;
		--------------------------------------------

--AGREGAR OT EN PEDIDO VENTA
SELECT "ItemCode","PlannedQty","OriginAbs","CardCode","DocNum","DueDate" into ARTICULO2,CANTIDAD,DOCENTRYOV,SN,DOCNUMOT,FechaEntregaLinea FROM OWOR WHERE "DocEntry" = :docEntry;

SELECT "U_EXP_FORM" into Formula FROM "OITM" WHERE "ItemCode" = :ARTICULO2;



UPDATE T1
SET T1."U_EXP_OTPROD"= :DOCNUMOT
FROM RDR1 T1 WHERE
"ItemCode"= :ARTICULO2 and "InvQty"=:CANTIDAD and "DocEntry"= :DOCENTRYOV and "ShipDate"= :FechaEntregaLinea;

UPDATE T2
SET U_EXP_FORM = :Formula
FROM "OWOR" T2 WHERE "DocEntry" = :docEntry;

--
--AGREGAR COLUMNA CANTIDAD REQUERIDA ANTERIOR

UPDATE T3
SET U_EXP_CANTREQ = "PlannedQty"
FROM "WOR1" T3 WHERE "DocEntry" = :docEntry;


--AGREGAR COLUMNA ALMACEN ANTERIOR
UPDATE T3
SET U_EXP_ALMANT = "wareHouse"
FROM "WOR1" T3 WHERE "DocEntry" = :docEntry;

--AGREGAR CAMPO METROS ESTIMADOS
UPDATE T4
SET "U_EXX_MTEST" = IFNULL(T5."U_EXP_METEST",0),   
    "U_EXX_UNDOV" = T5."unitMsr",
    "U_EXX_CNTOV" = T5."Quantity",
    "U_EXP_QTYKG" = T5."InvQty"
FROM "OWOR" T4 LEFT JOIN "RDR1" T5 ON T4."OriginAbs" = T5."DocEntry" AND T4."ItemCode" = T5."ItemCode" AND T4."DocNum" = T5."U_EXP_OTPROD"  
WHERE T4."DocEntry" = :docEntry;

------DESARROLLO-----

/*
--ACTUALIZAR STANDBY
UPDATE T2
SET T2."U_EXX_DSTANDBY"='Y'
from WOR1 T1
JOIN WOR1 T2 ON T1."StageId" = T2."StageId"  AND  T1."DocEntry"=T2."DocEntry" 
 WHERE T1."U_EXX_DSTANDBY"='Y' AND T1."DocEntry" = :docEntry;
 
 --ACTUALIZAR PARCIAL
UPDATE T2
SET T2."U_EXX_DPARCIAL"='Y'
from WOR1 T1
JOIN WOR1 T2 ON T1."StageId" = T2."StageId"  AND  T1."DocEntry"=T2."DocEntry" 
 WHERE T1."U_EXX_DPARCIAL"='Y' AND T1."DocEntry" = :docEntry;
 
  --ACTUALIZAR TERMINADO
UPDATE T2
SET T2."U_EXX_DTERMIN"='Y'
from WOR1 T1
JOIN WOR1 T2 ON T1."StageId" = T2."StageId"  AND  T1."DocEntry"=T2."DocEntry" 
 WHERE T1."U_EXX_DTERMIN"='Y' AND T1."DocEntry" = :docEntry;
 
 
*/
-----DESARROLLO---



	IF IFNULL(:error_message, n'Ok') <> n'Ok' THEN 
        error := 202;
    END IF;
    
   
END;