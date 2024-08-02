USE [SBO_BASE_LETRAS]
GO
/****** Object:  StoredProcedure [dbo].[EXX_DisponibilidadRecursos]    Script Date: 12/07/2021 07:42:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXX_DisponibilidadRecursos]
	@FECHA DATETIME,
	@RESCODE NVARCHAR(50),
	@CODE NVARCHAR(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT TABLA0.StartDate,SUM(TABLA0.Disponible) 'Disponible', MAX(TABLA0.HoraFin) 'HoraFin' FROM
	(SELECT T1.U_EXC_FProgam 'StartDate', T6.CapTotal-T1.PlannedQty 'Disponible',T1.U_EXC_HoraFin 'HoraFin'
	FROM OWOR T0
	INNER JOIN WOR1 T1 ON T0.DocEntry=T1.DocEntry
	INNER JOIN WOR4 T4 ON T0.DocEntry=T4.DocEntry and T4.StageId=T1.StageId
	INNER JOIN RSC6 T6 ON T1.ItemCode=T6.ResCode AND WeekDay=DATEPART(WEEKDAY,T4.StartDate)
	WHERE T1.ItemType=290
	and T1.U_EXC_FProgam>=@FECHA AND T1.ItemCode=@RESCODE AND T1.U_EXC_Programado='Y'
	AND T0.Status='R'
	AND ISNULL(T1.U_EXC_Programado,'N')='Y'
	UNION ALL
	SELECT T0.U_STARTDATE 'StartDate', T6.CapTotal-T1.PlannedQty 'Disponible',T0.U_FINISHTIME 'HoraFin' FROM
	[@EXX_PROGOF] T0
	INNER JOIN WOR1 T1 ON T0.U_DOCENTRY=T1.DocEntry and T1.ItemCode=T0.U_RESCODE and T1.StageId=T0.U_STAGEID
	INNER JOIN RSC6 T6 ON T0.U_RESCODE=T6.ResCode AND WeekDay=DATEPART(WEEKDAY,T0.U_STARTDATE) 
	WHERE T0.U_PROGCODE=@CODE
	and T0.U_STARTDATE>=@FECHA AND T0.U_RESCODE=@RESCODE) AS TABLA0
	GROUP BY TABLA0.StartDate
	HAVING SUM(TABLA0.Disponible)>0
	ORDER BY TABLA0.StartDate
	
END

GO
/****** Object:  StoredProcedure [dbo].[EXX_DisponibilidadRecursosRec]    Script Date: 12/07/2021 07:42:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXX_DisponibilidadRecursosRec]
	@FECHA DATETIME,
	@RESCODE NVARCHAR(50),
	@CODE NVARCHAR(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT TABLA0.StartDate,SUM(TABLA0.Disponible) 'Disponible', MAX(TABLA0.HoraFin) 'HoraFin' FROM
	(SELECT T1.U_EXC_FProgam 'StartDate', T6.CapTotal-T1.PlannedQty 'Disponible',T1.U_EXC_HoraFin 'HoraFin'
	FROM OWOR T0
	INNER JOIN WOR1 T1 ON T0.DocEntry=T1.DocEntry
	INNER JOIN WOR4 T4 ON T0.DocEntry=T4.DocEntry and T4.StageId=T1.StageId
	INNER JOIN RSC6 T6 ON T1.ItemCode=T6.ResCode AND WeekDay=DATEPART(WEEKDAY,T4.StartDate)
	WHERE T1.ItemType=290
	and T1.U_EXC_FProgam>=@FECHA AND T1.ItemCode=@RESCODE AND T1.U_EXC_Programado='Y'
	AND T0.Status='R'
	AND ISNULL(T1.U_EXC_Programado,'N')='Y'
	UNION ALL
	SELECT T0.U_STARTDATE 'StartDate', T6.CapTotal-T1.PlannedQty 'Disponible',T0.U_FINISHTIME 'HoraFin' FROM
	[@EXX_PROGOF] T0
	INNER JOIN WOR1 T1 ON T0.U_DOCENTRY=T1.DocEntry and T1.ItemCode=T0.U_RESCODE and T1.StageId=T0.U_STAGEID
	INNER JOIN RSC6 T6 ON T0.U_RESCODE=T6.ResCode AND WeekDay=DATEPART(WEEKDAY,T0.U_STARTDATE) 
	WHERE T0.U_PROGCODE=@CODE
	and T0.U_STARTDATE>=@FECHA AND T0.U_RESCODE=@RESCODE) AS TABLA0
	GROUP BY TABLA0.StartDate
	HAVING SUM(TABLA0.Disponible)>0
	ORDER BY TABLA0.StartDate
	
END

GO
/****** Object:  StoredProcedure [dbo].[EXX_GetOrdenesPendientes]    Script Date: 12/07/2021 07:42:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXX_GetOrdenesPendientes]
	-- Add the parameters for the stored procedure here
	@fechaini datetime,
	@fechafin datetime,
	@tipofecha char(1),
	@tieneprog char(1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select 'N' 'Selecc', T0.DocNum,T0.CardCode,T0.CardName,T3.Street,T0.DocDate,T0.TaxDate,'WhsCode' 'WhsCode',T0.U_EXX_FPrograma,T0.U_EXX_HPrograma,T0.U_EXX_NombChofer,t2.SlpName
	from ORDR t0
	--inner join rdr1 t1 on t0.DocEntry=t1.DocEntry
	left join OSLP t2 on t0.SlpCode=t2.SlpCode
	left join CRD1 t3 on t0.ShipToCode=t3.Address and t3.CardCode=t0.CardCode
	where t0.DocStatus='O' and ((@tipofecha='P' and t0.DocDate between @fechaini and @fechafin) or (@tipofecha='E' and t0.TaxDate between @fechaini and @fechafin))
	
END

GO
/****** Object:  StoredProcedure [dbo].[EXX_ListaOrdenesProgramacion]    Script Date: 12/07/2021 07:42:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXX_ListaOrdenesProgramacion]
	@FINI DATETIME,
	@FFIN DATETIME,
	@ORDER CHAR(1),
	@ORDERENTRY INT,
	@VISUAL CHAR(1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @ORDER='E'
	BEGIN
		select ROW_NUMBER() over (order by T0.DueDate) 'Linenum','N' 'Check',0 'SelOrder',T0.DocEntry 'Order',T1.ItemCode 'ResCode',T2.ResName 'Resource', CAST(cast(dateadd(ms,t1.BaseQty*t2.TimeResUn*t0.PlannedQty*1000, '00:00:00') AS TIME(3)) AS NVARCHAR(8)) 'Hours',
		T4.StartDate,T4.EndDate 'FinishDate',ISNULL(T1.U_EXC_Programado,'N') 'Scheduled','' 'Overlap', T0.Priority 'Priority',T0.DueDate 'DelivDate',T3.CardCode,T3.CardName 'Customer',T0.ItemCode,TM.ItemName 'Product',
		T0.Uom 'UOM',T0.PlannedQty 'ReqQuant',
		CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'+CONVERT(NVARCHAR(10),U_EXC_HoraIni),4),2)+':'+RIGHT('0'+CONVERT(NVARCHAR(10),U_EXC_HoraIni),2) END 'StartTime',
		CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'+CONVERT(NVARCHAR(10),U_EXC_HoraFin),4),2)+':'+RIGHT('0'+CONVERT(NVARCHAR(10),U_EXC_HoraFin),2) END 'FinishTime',
		T1.PlannedQty,T1.VisOrder 'OLineNum',T2.TimeResUn,T1.StageId,t4.StgEntry,
		CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE CONVERT(NVARCHAR(10),U_EXC_FProgam,103) END 'ProgramDate'
		from OWOR T0
		INNER JOIN WOR1 T1 ON T0.DocEntry=T1.DocEntry
		INNER JOIN WOR4 T4 ON T0.DocEntry=T4.DocEntry and T4.StageId=T1.StageId
		INNER JOIN OITM TM ON T0.ItemCode=TM.ItemCode
		LEFT JOIN ORSC T2 ON T1.ItemCode=T2.ResCode
		LEFT JOIN OCRD T3 ON T0.CardCode=T3.CardCode
		WHERE T0.Status='R' AND T1.ItemType=290 and T0.DueDate between @FINI and @FFIN
		and (@ORDERENTRY=0 or T0.DocEntry=@ORDERENTRY)
		and (@VISUAL='*' or isnull(T1.U_EXC_Programado,'N')=@VISUAL)
		ORDER BY T0.DueDate,T0.DocEntry,T1.StageId
	END
	ELSE IF @ORDER='P'
	BEGIN
		select ROW_NUMBER() over (order by T0.Priority) 'Linenum','N' 'Check',0 'SelOrder',T0.DocEntry 'Order',T1.ItemCode 'ResCode',T2.ResName 'Resource', CAST(cast(dateadd(ms,t1.BaseQty*t2.TimeResUn*t0.PlannedQty*1000, '00:00:00') AS TIME(3)) AS NVARCHAR(8)) 'Hours',
		T4.StartDate,T4.EndDate 'FinishDate',ISNULL(T1.U_EXC_Programado,'N') 'Scheduled','' 'Overlap', T0.Priority 'Priority',T0.DueDate 'DelivDate',T3.CardCode,T3.CardName 'Customer',T0.ItemCode,TM.ItemName 'Product',
		T0.Uom 'UOM',T0.PlannedQty 'ReqQuant',
		CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'+CONVERT(NVARCHAR(10),U_EXC_HoraIni),4),2)+':'+RIGHT('0'+CONVERT(NVARCHAR(10),U_EXC_HoraIni),2) END 'StartTime',
		CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'+CONVERT(NVARCHAR(10),U_EXC_HoraFin),4),2)+':'+RIGHT('0'+CONVERT(NVARCHAR(10),U_EXC_HoraFin),2) END 'FinishTime',
		T1.PlannedQty,T1.VisOrder 'OLineNum',T2.TimeResUn,T1.StageId,t4.StgEntry,
		CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE CONVERT(NVARCHAR(10),U_EXC_FProgam,103) END 'ProgramDate'
		from OWOR T0
		INNER JOIN WOR1 T1 ON T0.DocEntry=T1.DocEntry
		INNER JOIN WOR4 T4 ON T0.DocEntry=T4.DocEntry and T4.StageId=T1.StageId
		INNER JOIN OITM TM ON T0.ItemCode=TM.ItemCode
		LEFT JOIN ORSC T2 ON T1.ItemCode=T2.ResCode
		LEFT JOIN OCRD T3 ON T0.CardCode=T3.CardCode
		WHERE T0.Status='R' AND T1.ItemType=290 and T0.DueDate between @FINI and @FFIN
		and (@ORDERENTRY=0 or T0.DocEntry=@ORDERENTRY)
		and (@VISUAL='*' or isnull(T1.U_EXC_Programado,'N')=@VISUAL)
		ORDER BY T0.Priority desc,T0.DocEntry,T1.StageId
	END
END

GO
/****** Object:  StoredProcedure [dbo].[EXX_ListaOrdenesProgRec]    Script Date: 12/07/2021 07:42:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXX_ListaOrdenesProgRec]
	@FINI DATETIME,
	@FFIN DATETIME,
	@ORDER CHAR(1),
	@RESCODE NVARCHAR(50),
	@CODE NVARCHAR(50),
	@NEW INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @ORDER='E'
	BEGIN
		IF @NEW=1
		BEGIN
			INSERT INTO [@EXX_PROGOF] ([Code],[Name],[U_PROGCODE],[U_VISORDER],[U_DOCENTRY],[U_STAGEID],[U_RESCODE])
			select @CODE+CONVERT(NVARCHAR(5),ROW_NUMBER() over (order by T0.DueDate)) 'Code',@CODE+CONVERT(NVARCHAR(5),ROW_NUMBER() over (order by T0.DueDate)) 'Name',@CODE,
			ROW_NUMBER() over (order by T0.DueDate) 'visorder',
			T0.DocEntry 'Order',T1.StageId,T1.ItemCode 'ResCode'
			from OWOR T0
			INNER JOIN WOR1 T1 ON T0.DocEntry=T1.DocEntry
			INNER JOIN WOR4 T4 ON T0.DocEntry=T4.DocEntry and T4.StageId=T1.StageId
			INNER JOIN OITM TM ON T0.ItemCode=TM.ItemCode
			LEFT JOIN ORSC T2 ON T1.ItemCode=T2.ResCode
			LEFT JOIN OCRD T3 ON T0.CardCode=T3.CardCode
			WHERE T0.Status='R' AND T1.ItemType=290 and T0.DueDate between @FINI and @FFIN
			and T1.ItemCode = @RESCODE
			ORDER BY T0.DueDate,T0.DocEntry,T1.StageId
		END
		select TT.[U_VISORDER] 'Linenum',isnull(TT.U_CHECK,'N') 'Check',T0.DocEntry 'Order',T1.ItemCode 'ResCode',T2.ResName 'Resource', CAST(cast(dateadd(ms,t1.BaseQty*t2.TimeResUn*t0.PlannedQty*1000, '00:00:00') AS TIME(3)) AS NVARCHAR(8)) 'Hours',
		T4.StartDate,T4.EndDate 'FinishDate',ISNULL(T1.U_EXC_Programado,'N') 'Scheduled','' 'Overlap', T0.Priority 'Priority',T0.DueDate 'DelivDate',T3.CardCode,T3.CardName 'Customer',T0.ItemCode,TM.ItemName 'Product',
		T0.Uom 'UOM',T0.PlannedQty 'ReqQuant',
		CASE WHEN ISNULL(U_STARTTIME,0)=0 THEN CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'+CONVERT(NVARCHAR(10),U_EXC_HoraIni),4),2)+':'+RIGHT('0'+CONVERT(NVARCHAR(10),U_EXC_HoraIni),2) END ELSE '' END 'StartTime',
		CASE WHEN ISNULL(U_FINISHTIME,0)=0 THEN CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'+CONVERT(NVARCHAR(10),U_EXC_HoraFin),4),2)+':'+RIGHT('0'+CONVERT(NVARCHAR(10),U_EXC_HoraFin),2) END ELSE '' END 'FinishTime',
		T1.PlannedQty,T1.VisOrder 'OLineNum',T2.TimeResUn,T1.StageId,t4.StgEntry,
		ISNULL(CONVERT(NVARCHAR(10),U_STARTDATE,103),CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE CONVERT(NVARCHAR(10),U_EXC_FProgam,103) END) 'ProgramDate',
		TT.Code
		from [@EXX_PROGOF] TT
		inner join OWOR T0 on TT.[U_PROGCODE]=@CODE AND T0.DocEntry=TT.[U_DOCENTRY]
		INNER JOIN WOR1 T1 ON T0.DocEntry=T1.DocEntry AND T1.ItemCode=TT.[U_RESCODE] AND T1.StageId=TT.[U_STAGEID]
		INNER JOIN WOR4 T4 ON T0.DocEntry=T4.DocEntry and T4.StageId=T1.StageId
		INNER JOIN OITM TM ON T0.ItemCode=TM.ItemCode
		LEFT JOIN ORSC T2 ON T1.ItemCode=T2.ResCode
		LEFT JOIN OCRD T3 ON T0.CardCode=T3.CardCode
		WHERE T0.Status='R' AND T1.ItemType=290 and T0.DueDate between @FINI and @FFIN
		and T1.ItemCode = @RESCODE
		ORDER BY TT.[U_VISORDER]
	END
	ELSE IF @ORDER='P'
	BEGIN
		IF @NEW=1
		BEGIN
			INSERT INTO [@EXX_PROGOF] ([Code],[Name],[U_PROGCODE],[U_VISORDER],[U_DOCENTRY],[U_STAGEID],[U_RESCODE])
			select @CODE+CONVERT(NVARCHAR(5),ROW_NUMBER() over (order by T0.DueDate)) 'Code',@CODE+CONVERT(NVARCHAR(5),ROW_NUMBER() over (order by T0.DueDate)) 'Name',@CODE,
			ROW_NUMBER() over (order by T0.DueDate) 'visorder',
			T0.DocEntry 'Order',T1.StageId,T1.ItemCode 'ResCode'
			from OWOR T0
			INNER JOIN WOR1 T1 ON T0.DocEntry=T1.DocEntry
			INNER JOIN WOR4 T4 ON T0.DocEntry=T4.DocEntry and T4.StageId=T1.StageId
			INNER JOIN OITM TM ON T0.ItemCode=TM.ItemCode
			LEFT JOIN ORSC T2 ON T1.ItemCode=T2.ResCode
			LEFT JOIN OCRD T3 ON T0.CardCode=T3.CardCode
			WHERE T0.Status='R' AND T1.ItemType=290 and T0.DueDate between @FINI and @FFIN
			and T1.ItemCode = @RESCODE
			ORDER BY T0.DueDate,T0.DocEntry,T1.StageId
		END
		select TT.[U_VISORDER] 'Linenum',isnull(TT.U_CHECK,'N') 'Check',T0.DocEntry 'Order',T1.ItemCode 'ResCode',T2.ResName 'Resource', CAST(cast(dateadd(ms,t1.BaseQty*t2.TimeResUn*t0.PlannedQty*1000, '00:00:00') AS TIME(3)) AS NVARCHAR(8)) 'Hours',
		T4.StartDate,T4.EndDate 'FinishDate',ISNULL(T1.U_EXC_Programado,'N') 'Scheduled','' 'Overlap', T0.Priority 'Priority',T0.DueDate 'DelivDate',T3.CardCode,T3.CardName 'Customer',T0.ItemCode,TM.ItemName 'Product',
		T0.Uom 'UOM',T0.PlannedQty 'ReqQuant',
		CASE WHEN ISNULL(U_STARTTIME,0)=0 THEN CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'+CONVERT(NVARCHAR(10),U_EXC_HoraIni),4),2)+':'+RIGHT('0'+CONVERT(NVARCHAR(10),U_EXC_HoraIni),2) END ELSE '' END 'StartTime',
		CASE WHEN ISNULL(U_FINISHTIME,0)=0 THEN CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE LEFT(RIGHT('000'+CONVERT(NVARCHAR(10),U_EXC_HoraFin),4),2)+':'+RIGHT('0'+CONVERT(NVARCHAR(10),U_EXC_HoraFin),2) END ELSE '' END 'FinishTime',
		T1.PlannedQty,T1.VisOrder 'OLineNum',T2.TimeResUn,T1.StageId,t4.StgEntry,
		ISNULL(CONVERT(NVARCHAR(10),U_STARTDATE,103),CASE T1.U_EXC_Programado WHEN 'N' THEN '' ELSE CONVERT(NVARCHAR(10),U_EXC_FProgam,103) END) 'ProgramDate',
		TT.Code
		from [@EXX_PROGOF] TT
		inner join OWOR T0 on TT.[U_PROGCODE]=@CODE AND T0.DocEntry=TT.[U_DOCENTRY]
		INNER JOIN WOR1 T1 ON T0.DocEntry=T1.DocEntry AND T1.ItemCode=TT.[U_RESCODE] AND T1.StageId=TT.[U_STAGEID]
		INNER JOIN WOR4 T4 ON T0.DocEntry=T4.DocEntry and T4.StageId=T1.StageId
		INNER JOIN OITM TM ON T0.ItemCode=TM.ItemCode
		LEFT JOIN ORSC T2 ON T1.ItemCode=T2.ResCode
		LEFT JOIN OCRD T3 ON T0.CardCode=T3.CardCode
		WHERE T0.Status='R' AND T1.ItemType=290 and T0.DueDate between @FINI and @FFIN
		and T1.ItemCode = @RESCODE
		ORDER BY T0.Priority,T0.DocEntry,T1.StageId
	END
END

GO
/****** Object:  StoredProcedure [dbo].[EXX_ValidarStage]    Script Date: 12/07/2021 07:42:14 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXX_ValidarStage]
	@DOCENTRY INT,
	@SEQNUM INT,
	@CODE NVARCHAR(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @SEQNUM=1
	BEGIN
		SELECT 0
	END
	ELSE
	BEGIN
		DECLARE @SEQANT INT
		DECLARE @RECURSOS INT
		DECLARE @RECURSOSPROG INT
		DECLARE @RECURSOSPROG2 INT
		SELECT @SEQANT=max(StageId) FROM WOR4 WHERE DocEntry=@DOCENTRY and SeqNum<@SeqNum
		SELECT @RECURSOS=COUNT(0) FROM WOR1 WHERE DocEntry=@DOCENTRY AND StageId=@SEQANT AND ItemType=290
		IF @RECURSOS>0
		BEGIN
			SELECT @RECURSOSPROG=COUNT(0) FROM WOR1 WHERE DocEntry=@DOCENTRY AND StageId=@SEQANT AND U_EXC_Programado='Y'
			SELECT @RECURSOSPROG2=COUNT(0) FROM [@EXX_PROGOF] T0 WHERE T0.U_PROGCODE=@CODE AND T0.U_DOCENTRY=@DOCENTRY AND T0.U_STAGEID=@SEQANT
			IF @RECURSOSPROG=0 AND @RECURSOSPROG2=0
			BEGIN
				SELECT -1
			END
			ELSE
			BEGIN
				IF @RECURSOSPROG>0
				BEGIN
					SELECT MAX(U_EXC_HoraFin) FROM WOR1 WHERE DocEntry=@DOCENTRY AND StageId=@SEQANT AND U_EXC_Programado='Y'
				END
				ELSE
				BEGIN
					SELECT MAX(T0.U_FINISHTIME) FROM [@EXX_PROGOF] T0 WHERE T0.U_PROGCODE=@CODE AND T0.U_DOCENTRY=@DOCENTRY AND T0.U_STAGEID=@SEQANT
				END
			END
		END
		ELSE
		BEGIN
			SELECT 0
		END
	END
END

GO
