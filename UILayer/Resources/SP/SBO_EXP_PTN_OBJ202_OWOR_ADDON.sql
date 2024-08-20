ALTER PROCEDURE "SBO_EXP_PTN_OBJ202_OWOR_ADDON"
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



		UPDATE WOR1 
		SET 
		"U_EXC_Programado"='N',
		"U_EXC_FProgam" = null,
		"U_EXC_FPROGF" = null,
		"U_EXC_HoraIni" = null,
		"U_EXC_HoraFin" = null
		
		WHERE "DocEntry" = :docEntry ;  	


	IF IFNULL(:error_message, n'Ok') <> n'Ok' THEN 
        error := 202;
    END IF;
    
   
END;