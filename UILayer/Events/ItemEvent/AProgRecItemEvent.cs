using Reportes.Util;
using SAPbouiCOM;
using SAPbobsCOM;
using System;
using System.Collections.Generic;

namespace Reportes.Events.ItemEvent
{
    class AProgRecItemEvent : IObjectItemEvent
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(AProgRecItemEvent));
        Form oForm;
        public void ItemEventAction(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;

            try
            {
                oForm = ClsMain.oApplication.Forms.Item(FormUID);
                switch (pVal.EventType)
                {
                    case BoEventTypes.et_CHOOSE_FROM_LIST:
                        ChooseFromList(ref pVal);
                        break;
                    case BoEventTypes.et_FORM_LOAD:
                        //FormLoad(ref pVal);
                        break;
                    case BoEventTypes.et_FORM_ACTIVATE:
                        //FormActivate(ref pVal, out BubbleEvent);
                        break;
                    case BoEventTypes.et_ITEM_PRESSED:
                        ItemPressed(ref pVal, out BubbleEvent);
                        break;
                    case BoEventTypes.et_VALIDATE:
                        Validate(ref pVal);
                        break;
                }
            }
            catch (Exception ex)
            {
                logger.Error("ItemEventAction", ex);
            }
        }

        private void Validate(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (!pVal.BeforeAction)
            {
                switch (pVal.ItemUID)
                {
                    case "txtRes":
                        EditText oEdit = ((EditText)oForm.Items.Item("txtRes").Specific);
                        if (string.IsNullOrEmpty(oEdit.Value))
                        {
                            StaticText oLabel = ((StaticText)oForm.Items.Item("lblResNam").Specific);
                            oLabel.Caption = string.Empty;
                        }
                        break;
                }
            }
        }

        private void ChooseFromList(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (!pVal.BeforeAction)
            {
                switch (pVal.ItemUID)
                {
                    case "txtRes":
                        cflResCode(ref pVal);
                        break;
                }
            }
        }

        private void cflResCode(ref SAPbouiCOM.ItemEvent pVal)
        {
            DataTable dtSelect = null;
            try
            {
                IChooseFromListEvent oCFLEvento = (IChooseFromListEvent)pVal;

                if (!oCFLEvento.Before_Action && oCFLEvento.ChooseFromListUID == "cflRes")
                {
                    dtSelect = oCFLEvento.SelectedObjects;

                    if (dtSelect != null)
                    {
                        StaticText oLabel = ((StaticText)oForm.Items.Item("lblResNam").Specific);
                        oLabel.Caption = dtSelect.GetValue("ResName", 0).ToString();
                        EditText oEdit = ((EditText)oForm.Items.Item("txtRes").Specific);
                        oEdit.Value = dtSelect.GetValue("ResCode", 0).ToString();
                    }
                }
            }
            catch { }
        }

        private void ItemPressed(ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                switch (pVal.ItemUID)
                {
                    case "optFE":
                    case "optSL":
                    case "optPR":
                        if (pVal.BeforeAction && !pVal.InnerEvent)
                        {
                            BubbleEvent = ValidarOpcion(pVal.ItemUID);
                        }
                        break;
                    case "btnLimpiar":
                        if (!pVal.BeforeAction)
                        {
                            BubbleEvent = false;
                            Limpiar();
                        }
                        break;
                    case "btnPrevia":
                        if (!pVal.BeforeAction)
                        {
                            BubbleEvent = false;
                            Previsualizar();
                        }
                        break;
                    case "btnOk":
                        if (!pVal.BeforeAction)
                        {
                            BubbleEvent = false;
                            ProcesarOrdenes();
                        }
                        break;
                    case "btnMostrar":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        {
                            MostrarOrdenes();
                        }
                        break;
                    case "matOrders":
                        if (!pVal.BeforeAction && pVal.ColUID == "check" && pVal.Row > 0)
                        {
                            ActualizarCheckTemp(pVal.Row);
                            string codigo = oForm.DataSources.UserDataSources.Item("uCodigo").Value;
                            MostrarOrdenes(codigo);
                        }
                        break;
                    case "btnUP":
                        if (!pVal.BeforeAction) MoverSeleccion(ref pVal,"UP");
                        break;
                    case "btnDOWN":
                        if (!pVal.BeforeAction) MoverSeleccion(ref pVal,"DN");
                        break;
                   
                }
            }
            catch (Exception ex)
            {
                logger.Error("ItemPressed", ex);
            }
        }

        void MoverSeleccion(ref SAPbouiCOM.ItemEvent pVal, string direccion)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            DataTable oDTordenes = oForm.DataSources.DataTables.Item("dtOrders");
            int selrow = oMatOrdenes.GetNextSelectedRow();
            if (selrow > 0)
            {
                string prog0 = oDTordenes.GetValue("Scheduled", selrow - 1);
                if (prog0 == "Y")
                {
                    ClsMain.MensajeError("El recurso ya tiene hora programada, debe limpiarlo para moverlo");
                    return;
                }
                if (direccion == "UP")
                {
                    if (selrow == 1)
                    {
                        ClsMain.MensajeError("No puede subir más este recurso");
                        return;
                    }
                    string prog = oDTordenes.GetValue("Scheduled", selrow - 2);
                    if (prog == "Y")
                    {
                        ClsMain.MensajeError("El recurso anterior ya tiene hora programada, debe limpiarlo para moverlo");
                        return;
                    }
                    else
                    {
                        string code0 = oDTordenes.GetValue("Code", selrow - 1);
                        string code1 = oDTordenes.GetValue("Code", selrow - 2);
                        ActualizarOrden(code0, code1, direccion);
                        string codigo = oForm.DataSources.UserDataSources.Item("uCodigo").Value;
                        LimpiarTemp(codigo);
                        MostrarOrdenes(codigo);
                        oMatOrdenes.SelectRow(selrow - 1, true, false);
                    }
                }
                else
                {
                    if (selrow == oMatOrdenes.RowCount)
                    {
                        ClsMain.MensajeError("No puede bajar más este recurso");
                        return;
                    }
                    string prog = oDTordenes.GetValue("Scheduled", selrow);
                    if (prog == "Y")
                    {
                        ClsMain.MensajeError("El recurso siguiente ya tiene hora programada, debe limpiarlo para moverlo");
                        return;
                    }
                    else
                    {
                        string code0 = oDTordenes.GetValue("Code", selrow);
                        string code1 = oDTordenes.GetValue("Code", selrow - 1);
                        ActualizarOrden(code0, code1, direccion);
                        string codigo = oForm.DataSources.UserDataSources.Item("uCodigo").Value;
                        LimpiarTemp(codigo);
                        MostrarOrdenes(codigo);
                        oMatOrdenes.SelectRow(selrow + 1, true, false);
                    }
                }
            }
            else
            {
                ClsMain.MensajeError("Debe seleccionar un recurso");
            }
        }

        private void ActualizarOrden(string code0, string code1, string direccion)
        {
            try
            {
                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
                string query = $@"UPDATE ""@EXX_PROGOF"" SET U_VISORDER=U_VISORDER-1 where ""Code""='{code0}'";
                oRS.DoQuery(query);
                query = $@"UPDATE ""@EXX_PROGOF"" SET U_VISORDER=U_VISORDER+1 where ""Code""='{code1}'";
                oRS.DoQuery(query);
            }
            catch { }
        }

        bool ValidarOpcion(string opcion)
        {
            string order = oForm.DataSources.UserDataSources.Item("uOrden").Value;
            if (opcion == "optFE")
            {
                if (order != "E")
                {
                    ClsMain.MensajeError("Para programar por fecha de entrega debe seleccionar ese orden");
                    oForm.DataSources.UserDataSources.Item("uOrden").Value = "E";
                    MostrarOrdenes();
                    return false;
                }
            }
            else if (opcion == "optPR")
            {
                if (order != "P")
                {
                    ClsMain.MensajeError("Para programar por prioridad debe seleccionar ese orden");
                    oForm.DataSources.UserDataSources.Item("uOrden").Value = "P";
                    MostrarOrdenes();
                    return false;
                }
            }
            return true;
        }

        private void MostrarOrdenes(string codigo = "")
        {
            oForm.Freeze(true);
            try
            {
                string fechaIni, fechaFin, order, rescode;

                fechaIni = oForm.DataSources.UserDataSources.Item("uFdesde").Value;
                fechaFin = oForm.DataSources.UserDataSources.Item("uFhasta").Value;
                order = oForm.DataSources.UserDataSources.Item("uOrden").Value;
                rescode = oForm.DataSources.UserDataSources.Item("uResCode").Value;

                string query, neworder;
                if (string.IsNullOrEmpty(codigo))
                {
                    codigo = CodigoUDT();
                    oForm.DataSources.UserDataSources.Item("uCodigo").Value = codigo;
                    neworder = "1";
                }
                else
                {
                    neworder = "0";
                }

                if (ClsMain.oCompany.DbServerType == BoDataServerTypes.dst_HANADB)
                {
                    fechaIni = ((EditText)oForm.Items.Item("txtFdesde").Specific).Value;
                    fechaFin = ((EditText)oForm.Items.Item("txtFhasta").Specific).Value;
                    query = $@"call ""EXX_ListaOrdenesProgRec"" ('{fechaIni}','{fechaFin}','{order}','{rescode}','{codigo}',{neworder})";
                }
                else
                {
                    fechaIni = ((EditText)oForm.Items.Item("txtFdesde").Specific).Value;
                    fechaFin = ((EditText)oForm.Items.Item("txtFhasta").Specific).Value;
                    query = $"exec EXX_ListaOrdenesProgRec '{fechaIni}','{fechaFin}','{order}','{rescode}','{codigo}',{neworder}";
                }
                logger.Debug(query);
                oForm.DataSources.DataTables.Item("dtOrders").ExecuteQuery(query);
                oForm.DataSources.UserDataSources.Item("uSelect").Value = string.Empty;
                Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                oMatOrdenes.LoadFromDataSource();
                oMatOrdenes.AutoResizeColumns();

                if (oMatOrdenes.RowCount == 0)
                {
                    ClsMain.MensajeError("No se encontraron registros coincidentes", true);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
            oForm.Freeze(false);
        }

        void Previsualizar()
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            DataTable oDTordenes = oForm.DataSources.DataTables.Item("dtOrders");
            Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
            int procesados = 0;
            List<string> Errores = new List<string>();
            bool validar = oForm.DataSources.UserDataSources.Item("uValidar").Value == "Y";
            string fechaProg = oForm.DataSources.UserDataSources.Item("uFprog").Value;
            string codigo = oForm.DataSources.UserDataSources.Item("uCodigo").Value;
            LimpiarTemp(codigo);
            for (int j = 1; j <= oMatOrdenes.RowCount; j++)
            {
                int i = j;
                i--;
                string codeUDT = oDTordenes.GetValue("Code", i);
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(i + 1).Specific;
                if (oCheck.Checked)
                {
                    string resname = oDTordenes.GetValue("Resource", i);
                    string programado = oDTordenes.GetValue("Scheduled", i);
                    int docentry = oDTordenes.GetValue("OrderDE", i);
                    int StageId = oDTordenes.GetValue("StageId", i);
                    int StgEntry = oDTordenes.GetValue("StgEntry", i);
                    if (programado == "Y")
                    {
                        continue;
                    }
                    EditText oEditFecha = oMatOrdenes.Columns.Item("ProgDate").Cells.Item(i + 1).Specific;
                    oEditFecha.String = fechaProg;
                    procesados++;
                    string rescode = oDTordenes.GetValue("ResCode", i);
                    string query;
                    if (ClsMain.oCompany.DbServerType == BoDataServerTypes.dst_HANADB)
                    {
                        fechaProg = ((EditText)oForm.Items.Item("txtFProg").Specific).Value;
                        query = $@"call ""EXX_DisponibilidadRecursosRec"" ('{fechaProg}','{rescode}','{codigo}')";
                    }
                    else
                    {
                        query = $"exec [EXX_DisponibilidadRecursosRec] '{fechaProg}','{rescode}','{codigo}'";
                    }
                    logger.Debug(query);
                    double Hrequired = oDTordenes.GetValue("PlannedQty", i);
                    oRS.DoQuery(query);

                    if (!oRS.EoF)
                    {
                        while (!oRS.EoF)
                        {
                            double Hdisponible = oRS.Fields.Item("Disponible").Value;
                            if (Hdisponible >= Hrequired)
                            {
                                double TimeResUn = oDTordenes.GetValue("TimeResUn", i);
                                int hora = oRS.Fields.Item("HoraFin").Value;
                                int horamin = HoraMinimaInicial(docentry, StageId, codigo);
                                if (horamin == -1)
                                {
                                    if (validar)
                                    {
                                        Errores.Add($"Línea {i + 1}: Primero debe programar el recurso de la etapa anterior");
                                        break;
                                    }
                                    else
                                    {
                                        horamin = hora;
                                    }
                                }
                                if (hora < horamin) hora = horamin;
                                int linenum = oDTordenes.GetValue("OLineNum", i);
                                DateTime fechaDisp = oRS.Fields.Item("StartDate").Value;
                                EditText oEdit = oMatOrdenes.Columns.Item("StartTime").Cells.Item(i + 1).Specific;
                                string horacadena = hora.ToString().PadLeft(4, '0');
                                horacadena = horacadena.Substring(0, 2) + ":" + horacadena.Substring(2);
                                oEdit.Value = horacadena;

                                DateTime Horas = DateTime.ParseExact(horacadena, "HH:mm", null);
                                oEdit = oMatOrdenes.Columns.Item("FinishTime").Cells.Item(i + 1).Specific;
                                oEdit.Value = Horas.AddHours(ConvertirHoras(Hrequired, TimeResUn)).ToString("HH:mm");
                                break;
                            }
                            oRS.MoveNext();
                        }
                    }
                    else
                    {
                        double TimeResUn = oDTordenes.GetValue("TimeResUn", i);
                        int hora = HoraMinimaInicial(docentry, StageId, codigo);
                        if (hora == -1)
                        {
                            if (validar)
                            {
                                Errores.Add($"Línea {i + 1}: Primero debe programar el recurso de la etapa anterior");
                                continue;
                            }
                            else
                            {
                                hora = 0;
                            }
                        }
                        int linenum = oDTordenes.GetValue("OLineNum", i);
                        EditText oEdit = oMatOrdenes.Columns.Item("StartTime").Cells.Item(i + 1).Specific;
                        string horacadena = hora.ToString().PadLeft(4, '0');
                        horacadena = horacadena.Substring(0, 2) + ":" + horacadena.Substring(2);
                        oEdit.Value = horacadena;

                        DateTime Horas = DateTime.ParseExact(horacadena, "HH:mm", null);
                        oEdit = oMatOrdenes.Columns.Item("FinishTime").Cells.Item(i + 1).Specific;
                        oEdit.Value = Horas.AddHours(ConvertirHoras(Hrequired, TimeResUn)).ToString("HH:mm");
                    }
                }
                else
                {
                    EditText oEdit = oMatOrdenes.Columns.Item("StartTime").Cells.Item(i + 1).Specific;
                    oEdit.Value = string.Empty;

                    oEdit = oMatOrdenes.Columns.Item("FinishTime").Cells.Item(i + 1).Specific;
                    oEdit.Value = string.Empty;

                    oEdit = oMatOrdenes.Columns.Item("ProgDate").Cells.Item(i + 1).Specific;
                    oEdit.Value = string.Empty;
                }
                ActualizarTemp(ref oMatOrdenes, ref oDTordenes, fechaProg, codigo, i, codeUDT, oCheck.Checked);
            }
            Tools.LiberarObjeto(oRS);

            if (procesados > 0)
            {
                if (Errores.Count == 0)
                {
                    ClsMain.MensajeSuccess("Procesados todos los recursos con éxito");
                }
                else
                {
                    ClsMain.MensajeError("Se encontraron los siguientes errores: \n" + string.Join("\n", Errores));
                }
            }
            else
            {
                ClsMain.Mensaje("No se procesó ninguna orden");
            }
        }

        private string CodigoUDT()
        {
            string codigo = string.Empty;
            try
            {
                Random _random = new Random();
                codigo = ClsMain.oCompany.UserName;
                codigo += ClsMain.oCompany.GetCompanyDate().ToString("yyyyMMdd");
                codigo += ClsMain.oCompany.GetCompanyTime().Replace(":", "");
                codigo += _random.Next(1111, 9999).ToString();
            }
            catch { }
            return codigo;
        }

        void ActualizarTemp(ref Matrix oMatOrdenes, ref DataTable oDTordenes, string fechaProg, string codigo, int indice, string codeUDT, bool Check)
        {
            try
            {
                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
                string query = @"UPDATE ""@EXX_PROGOF"" SET ";
                if (Check)
                {
                    query += $"U_STARTDATE='{fechaProg}',";
                    query += $"U_STARTTIME={ObtenerValorMatrix(ref oMatOrdenes, "StartTime", indice + 1).Replace(":", "")},";
                    query += $"U_FINISHTIME={ObtenerValorMatrix(ref oMatOrdenes, "FinishTime", indice + 1).Replace(":", "")},";
                    query += $"U_CHECK='Y'";
                }
                else
                {
                    query += $"U_STARTDATE=null,";
                    query += $"U_STARTTIME=null,";
                    query += $"U_FINISHTIME=null,";
                    query += $"U_CHECK='N'";
                }
                query += $@" WHERE ""Code""='{codeUDT}'";
                oRS.DoQuery(query);
            }
            catch { }
        }

        void ActualizarCheckTemp(int row)
        {
            try
            {
                Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                DataTable oDTordenes = oForm.DataSources.DataTables.Item("dtOrders");
                string codeUDT = oDTordenes.GetValue("Code", row - 1);
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(row).Specific;
                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
                string query = @"UPDATE ""@EXX_PROGOF"" SET ";
                if (oCheck.Checked)
                {
                    query += $"U_CHECK='Y'";
                }
                else
                {
                    query += $"U_CHECK='N'";
                }
                query += $@" WHERE ""Code""='{codeUDT}'";
                oRS.DoQuery(query);
            }
            catch { }
        }

        void LimpiarTemp(string code)
        {
            try
            {
                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
                string query = @"UPDATE ""@EXX_PROGOF"" SET ";
                query += $"U_STARTDATE=null,";
                query += $"U_STARTTIME=null,";
                query += $"U_FINISHTIME=null";
                query += $" WHERE U_PROGCODE='{code}'";
                oRS.DoQuery(query);
            }
            catch { }
        }

        void InsertarTemp(ref Matrix oMatOrdenes, ref DataTable oDTordenes, string fechaProg, string codigo, int indice)
        {
            try
            {
                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
                string query = @"INSERT INTO ""@EXX_PROGOF"" (""Code"",""Name"",U_PROGCODE,U_DOCENTRY,U_STAGEID,U_CARDCODE,U_CARDNAME,U_ITEMCODE,U_ITEMNAME,U_UOM,U_WORQTY,U_RESCODE,U_RESNAME,U_REQTIME,U_STARTDATE,U_FINISHDATE,U_STARTTIME,U_FINISHTIME,U_SHIPDATE,U_PROGTIME)";
                query += " VALUES ";
                query += $"('{codigo + indice.ToString()}'";
                query += $",'{codigo + indice.ToString()}'";
                query += $",'{codigo}'";
                query += $",'{oDTordenes.GetValue("Order", indice)}'";
                query += $",{oDTordenes.GetValue("StageId", indice)}";
                query += $",'{oDTordenes.GetValue("CardCode", indice)}'";
                query += $",'{oDTordenes.GetValue("Customer", indice)}'";
                query += $",'{oDTordenes.GetValue("ItemCode", indice)}'";
                query += $",'{oDTordenes.GetValue("Product", indice)}'";
                query += $",'{oDTordenes.GetValue("UOM", indice)}'";
                query += $",'{oDTordenes.GetValue("ReqQuant", indice)}'";
                query += $",'{oDTordenes.GetValue("ResCode", indice)}'";
                query += $",'{oDTordenes.GetValue("Resource", indice)}'";
                string hora = oDTordenes.GetValue("Hours", indice);
                DateTime horaDT = DateTime.ParseExact(hora, "HH:mm:ss", null);
                query += $",{horaDT.ToString("Hmm")}";
                query += $",'{fechaProg}'";
                query += $",'{fechaProg}'";
                query += $",{ObtenerValorMatrix(ref oMatOrdenes, "StartTime", indice + 1).Replace(":", "")}";
                query += $",{ObtenerValorMatrix(ref oMatOrdenes, "FinishTime", indice + 1).Replace(":", "")}";
                query += $",'{ObtenerValorMatrix(ref oMatOrdenes, "DelivDate", indice + 1)}'";
                query += $",0)";
                oRS.DoQuery(query);
            }
            catch { }
        }

        string ObtenerValorMatrix(ref Matrix oMatOrdenes, string col, int indice)
        {
            EditText oEdit = oMatOrdenes.Columns.Item(col).Cells.Item(indice).Specific;
            return oEdit.Value;
        }

        void ProcesarOrdenes()
        {
            int rpta = ClsMain.oApplication.MessageBox("Se procesarán las órdenes, una vez realizado no se puede revertir, ¿Desea continuar?", 1, "Si", "No", "");
            if (rpta != 1) return;
            oForm.Freeze(true);
            try
            {
                int procesados = 0;
                List<string> Errores = new List<string>();
                string tipo = "1";// oForm.DataSources.UserDataSources.Item("uTProg").Value;
                switch (tipo)
                {
                    case "1":
                        ProcesarPorOrdenLista(out procesados, out Errores);
                        break;
                    case "2":
                        //ProcesarPorSeleccion(out procesados, out Errores);
                        break;
                }

                if (procesados > 0)
                {
                    if (Errores.Count == 0)
                    {
                        ClsMain.MensajeSuccess("Procesados todos los recursos con éxito");
                    }
                    else
                    {
                        ClsMain.MensajeError("Se encontraron los siguientes errores: \n" + string.Join("\n", Errores));
                    }
                    MostrarOrdenes();
                }
                else
                {
                    ClsMain.Mensaje("No se procesó ninguna orden");
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
            oForm.Freeze(false);
        }

        void ProcesarPorOrdenLista(out int procesados, out List<string> Errores)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            DataTable oDTordenes = oForm.DataSources.DataTables.Item("dtOrders");
            Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
            Errores = new List<string>();
            procesados = 0;
            for (int i = 0; i < oMatOrdenes.RowCount; i++)
            {
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(i + 1).Specific;
                if (oCheck.Checked)
                {
                    string horaProg = oDTordenes.GetValue("StartTime", i);
                    string resname = oDTordenes.GetValue("Resource", i);
                    int docentry = oDTordenes.GetValue("Order", i);
                    int StageId = oDTordenes.GetValue("StageId", i);
                    int StgEntry = oDTordenes.GetValue("StgEntry", i);
                    string fechaProg = ObtenerValorMatrix(ref oMatOrdenes, "ProgDate", i + 1).Replace(":", "");
                    //if (!string.IsNullOrEmpty(horaProg))
                    //{
                    //    ClsMain.MensajeError($@"El recurso ""{resname}"" de la orden {docentry} en la línea {i + 1} ya fue programado");
                    //    continue;
                    //}
                    procesados++;
                    int linenum = oDTordenes.GetValue("OLineNum", i);
                    double Hrequired = oDTordenes.GetValue("PlannedQty", i);
                    double TimeResUn = oDTordenes.GetValue("TimeResUn", i);
                    int hora = int.Parse(ObtenerValorMatrix(ref oMatOrdenes, "StartTime", i + 1).Replace(":", ""));
                    DateTime fechaPG = DateTime.ParseExact(fechaProg, "dd/MM/yyyy", null);
                    RegistrarFechaHora(docentry, linenum, hora, Hrequired, TimeResUn, fechaPG, StgEntry, out string error);
                }
            }
            Tools.LiberarObjeto(oRS);
        }

        void Limpiar()
        {
            DataTable oDTordenes = oForm.DataSources.DataTables.Item("dtOrders");
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            //int selrow = oMatOrdenes.GetNextSelectedRow();
            //if (selrow < 1)
            //{
            //    ClsMain.MensajeError("Debe seleccionar una orden para limpiarla");
            //    return;
            //}
            //string programado = oDTordenes.GetValue("Scheduled", selrow - 1);
            //if (programado == "N")
            //{
            //    ClsMain.MensajeError("La orden seleccionada no está programada, no es necesario limpiar");
            //    return;
            //}
            int rpta = ClsMain.oApplication.MessageBox("Se limpiará la programación de la orden seleccionada, una vez realizado no se puede revertir, ¿Desea continuar?", 1, "Si", "No", "");
            if (rpta != 1) return;

            List<string> Errores = new List<string>();

            int procesados = 0;
            for (int i = 0; i < oMatOrdenes.RowCount; i++)
            {
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(i + 1).Specific;
                if (oCheck.Checked)
                {
                    int linenum = oDTordenes.GetValue("OLineNum", i);
                    int docentry = oDTordenes.GetValue("Order", i);
                    int stageid = oDTordenes.GetValue("StageId", i);

                    LimpiarProgramacion(docentry, linenum, stageid, out string error);
                    if (!string.IsNullOrEmpty(error)) Errores.Add($"Línea {i + 1}: {error}");
                    procesados++;
                }
            }

            if (procesados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar al menos una orden a limpiar");
            }
            if (Errores.Count == 0)
            {
                ClsMain.MensajeSuccess("Limpiados todos los recursos con éxito");
            }
            else
            {
                ClsMain.MensajeError("Se encontraron los siguientes errores: \n" + string.Join("\n", Errores));
            }
            MostrarOrdenes();
        }

        void LimpiarProgramacion(int docentry, int linenum, out string error)
        {
            error = string.Empty;
            try
            {
                ProductionOrders oPOrders = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.oProductionOrders);
                if (oPOrders.GetByKey(docentry))
                {
                    oPOrders.Lines.SetCurrentLine(linenum);
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraIni").Value = "";
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraFin").Value = "";
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value = "N";
                    if (oPOrders.Update() != 0)
                    {
                        error = ClsMain.oCompany.GetLastErrorDescription();
                    }
                }
            }
            catch (Exception ex)
            {
                error = ex.Message;
                logger.Error(ex.Message, ex);
            }
        }

        void LimpiarProgramacion(int docentry, int linenum, int stageID, out string error)
        {
            error = string.Empty;
            try
            {
                ProductionOrders oPOrders = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.oProductionOrders);
                if (oPOrders.GetByKey(docentry))
                {
                    for (int i = 0; i < oPOrders.Lines.Count; i++)
                    {
                        oPOrders.Lines.SetCurrentLine(i);
                        if (oPOrders.Lines.ItemType == ProductionItemType.pit_Resource)
                        {
                            if (oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value == "Y" && oPOrders.Lines.StageID >= stageID)
                            {
                                oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraIni").Value = "";
                                oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraFin").Value = "";
                                oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value = "N";
                            }
                        }
                    }
                    if (oPOrders.Update() != 0)
                    {
                        error = ClsMain.oCompany.GetLastErrorDescription();
                    }
                }
            }
            catch (Exception ex)
            {
                error = ex.Message;
                logger.Error(ex.Message, ex);
            }
        }

        int HoraMinimaInicial(int docentry, int stageid, string code = "")
        {
            int horainicial = 0;

            try
            {
                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
                string query;
                if (ClsMain.oCompany.DbServerType == BoDataServerTypes.dst_HANADB)
                {
                    query = $@"call ""EXX_ValidarStage"" ({docentry},{stageid},'{code}')";
                }
                else
                {
                    query = $"exec EXX_ValidarStage {docentry},{stageid},'{code}'";
                }
                logger.Debug(query);
                oRS.DoQuery(query);

                if (!oRS.EoF)
                {
                    horainicial = oRS.Fields.Item(0).Value;
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }

            return horainicial;
        }

        void RegistrarHora(int docentry, int linenum, int hora, double Hrequired, double TimeResUn, out string error)
        {
            error = string.Empty;
            try
            {
                ProductionOrders oPOrders = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.oProductionOrders);
                if (oPOrders.GetByKey(docentry))
                {
                    oPOrders.Lines.SetCurrentLine(linenum);
                    string horacadena = hora.ToString().PadLeft(4, '0');
                    horacadena = horacadena.Substring(0, 2) + ":" + horacadena.Substring(2);
                    DateTime Horas = DateTime.ParseExact(horacadena, "H:mm", null);
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraIni").Value = Horas;
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraFin").Value = Horas.AddHours(ConvertirHoras(Hrequired, TimeResUn));
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value = "Y";
                    if (oPOrders.Update() != 0)
                    {
                        error = ClsMain.oCompany.GetLastErrorDescription();
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }



        void RegistrarFechaHora(int docentry, int linenum, int hora, double Hrequired, double TimeResUn, DateTime FechaOrden, int seqnum, out string error)
        {
            error = string.Empty;
            try
            {
                ProductionOrders oPOrders = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.oProductionOrders);
                if (oPOrders.GetByKey(docentry))
                {
                    oPOrders.Lines.SetCurrentLine(linenum);
                    string horacadena = hora.ToString().PadLeft(4, '0');
                    horacadena = horacadena.Substring(0, 2) + ":" + horacadena.Substring(2);
                    DateTime Horas = DateTime.ParseExact(horacadena, "H:mm", null);
                    //oPOrders.Stages.SetCurrentLine(seqnum - 1);
                    //oPOrders.Stages.StartDate = FechaOrden;
                    //if(oPOrders.StartDate.CompareTo(FechaOrden)>0)
                    //{
                    //    oPOrders.StartDate = FechaOrden;
                    //}
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraIni").Value = Horas;
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraFin").Value = Horas.AddHours(ConvertirHoras(Hrequired, TimeResUn));
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value = "Y";
                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_FProgam").Value = FechaOrden;
                    if (oPOrders.Update() != 0)
                    {
                        error = ClsMain.oCompany.GetLastErrorDescription();
                    }
                }
            }
            catch (Exception ex)
            {
                error = ex.Message;
                logger.Error(ex.Message, ex);
            }
        }

        double ConvertirHoras(double Hrequired, double TimeResUn)
        {
            double horas = 0;
            try
            {
                horas = Hrequired * TimeResUn;
                horas /= 60;
                horas /= 60;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
            return horas;
        }

        void AgregarSeleccion(int fila)
        {
            try
            {
                string tipo = "2";// oForm.DataSources.UserDataSources.Item("uTProg").Value;
                if (tipo != "2") return;
                string formselect = oForm.DataSources.UserDataSources.Item("uSelect").Value;
                List<string> seleccionados = new List<string>();
                if (!string.IsNullOrEmpty(formselect))
                {
                    seleccionados = new List<string>(formselect.Split('|'));
                }
                Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(fila).Specific;
                if (oCheck.Checked)
                {
                    if (!ValidarAnterior(fila - 1))
                    {
                        oCheck.Checked = false;
                        return;
                    }
                    seleccionados.Add(fila.ToString());
                    EditText oEdit = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(fila).Specific;
                    oEdit.Value = (seleccionados.IndexOf(fila.ToString()) + 1).ToString();
                }
                else
                {
                    int indice = seleccionados.IndexOf(fila.ToString());
                    if (indice > -1)
                    {
                        seleccionados.RemoveAt(indice);
                    }
                }
                oForm.DataSources.UserDataSources.Item("uSelect").Value = string.Join("|", seleccionados);
                if (!oCheck.Checked) ActualizarOrden(ref oMatOrdenes);
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }

        bool ValidarAnterior(int i)
        {
            try
            {
                string validar = oForm.DataSources.UserDataSources.Item("uValidar").Value;
                if (validar == "N") return true;
                DataTable oDTordenes = oForm.DataSources.DataTables.Item("dtOrders");
                int docentry = oDTordenes.GetValue("Order", i);
                int StageId = oDTordenes.GetValue("StageId", i);
                string codigo = oForm.DataSources.UserDataSources.Item("uCodigo").Value;
                int horamin = HoraMinimaInicial(docentry, StageId, codigo);
                if (horamin == -1)
                {
                    ClsMain.MensajeError("Primero debe programar el recurso de la etapa anterior", true);
                    return false;
                }
                else
                {
                    return true;
                }
            }
            catch { }
            return false;
        }

        private void ActualizarOrden(ref Matrix oMatOrdenes)
        {
            string formselect = oForm.DataSources.UserDataSources.Item("uSelect").Value;
            List<string> seleccionados = new List<string>();
            if (!string.IsNullOrEmpty(formselect))
            {
                seleccionados = new List<string>(formselect.Split('|'));
            }

            for (int i = 1; i <= oMatOrdenes.RowCount; i++)
            {
                string valor = "0";
                int indice = seleccionados.IndexOf(i.ToString());
                if (indice > -1)
                {
                    valor = (indice + 1).ToString();
                }
                EditText oEdit = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(i).Specific;
                oEdit.Value = valor;

                oEdit = oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific;
                string programado = oEdit.Value;

                if (programado == "N" && valor == "0")
                {
                    oEdit = oMatOrdenes.Columns.Item("StartTime").Cells.Item(i).Specific;
                    oEdit.Value = string.Empty;
                    oEdit = oMatOrdenes.Columns.Item("FinishTime").Cells.Item(i).Specific;
                    oEdit.Value = string.Empty;
                }
            }
            //oMatOrdenes.FlushToDataSource();
            //DataTable oDTordenes = oForm.DataSources.DataTables.Item("dtOrders");
            //for (int i = 0; i < oDTordenes.Rows.Count; i++)
            //{
            //    string valor = "0";
            //    int indice = seleccionados.IndexOf((i+1).ToString());
            //    if (indice > -1)
            //    {
            //        valor = (indice + 1).ToString();
            //    }
            //    oDTordenes.SetValue("SelOrder", i, valor);

            //    string programado = oDTordenes.GetValue("Scheduled", i);

            //    if (programado == "N" && valor == "0")
            //    {
            //        oDTordenes.SetValue("StartTime", i, string.Empty);
            //        oDTordenes.SetValue("FinishTime", i, string.Empty);
            //    }
            //}
            //oMatOrdenes.LoadFromDataSource();
        }

        /*
        private void MostrarReportes()
        {
            string ruta = ((EditText)oForm.Items.Item("txtRuta").Specific).String;
            if (ObtenerFechas(out DateTime fIni, out DateTime fFin))
            {
                if (string.IsNullOrEmpty(ruta))
                {
                    ClsMain.MensajeError("Debe seleccionar una ruta para el archivo Excel", true);
                    return;
                }
                string ModeloFin = string.Empty;
#if !DEBUG
                ComboBox oCombo = (ComboBox)oForm.Items.Item("cboModelo").Specific;
                if(string.IsNullOrEmpty(oCombo.Selected.Value))
                {
                    ClsMain.MensajeError("Debe seleccionar un modelo financiero", true);
                    return;
                }
                ModeloFin = oCombo.Selected.Value;
#else
                ModeloFin = "16";
#endif
                int rpta = ClsMain.oApplication.MessageBox("Se iniciará la generación, este proceso puede tardar varios minutos, ¿Desea continuar?", 1, "Si", "No", "");

                if (rpta != 1)
                {
                    return;
                }
                string nivel = ((ComboBox)oForm.Items.Item("cboNivel").Specific).Selected.Value;
                ActualizarDimensiones();
                EstadoFinanciero estadoFinanciero = new EstadoFinanciero(ClsMain.oCompany, System.Configuration.ConfigurationManager.AppSettings["cnString"], ref ClsMain.ListaCC1, ref ClsMain.ListaCC3);
                bool res = estadoFinanciero.EjecutarReporte(fIni, fFin, nivel, ruta, ModeloFin, out string mensaje);
                if (res)
                {
                    ClsMain.MensajeSuccess(mensaje);
                }
                else
                {
                    ClsMain.MensajeError(mensaje);
                }
            }
        }

        private void ElegirRuta()
        {
            OpenDialog openDialog = new OpenDialog("", "ReporteEEFF", "Archivo Excel (*.xlsx)|*.xlsx", DialogType.SAVE);
            openDialog.Open();
            string Directorio = openDialog.SelectedFile;

            if (!string.IsNullOrEmpty(Directorio))
            {
                ((EditText)oForm.Items.Item("txtRuta").Specific).String = Directorio;
            }
        }

        void ActualizarDimensiones()
        {
            ClsMain.ListaCC1 = new List<string>();
            ClsMain.ListaCC2 = new List<string>();
            ClsMain.ListaCC3 = new List<string>();
            ClsMain.ListaCC4 = new List<string>();
            ClsMain.ListaCC5 = new List<string>();
            for (int i = 1; i <= 5; i++)
            {
                DataTable oDt = oForm.DataSources.DataTables.Item("dtDim" + i.ToString());
                for (int j = 0; j < oDt.Rows.Count; j++)
                {
                    if (oDt.Columns.Item(0).Cells.Item(j).Value.ToString() == "N") continue;
                    string CC = oDt.Columns.Item(2).Cells.Item(j).Value.ToString();
                    switch (i)
                    {
                        case 1:
                            ClsMain.ListaCC1.Add(CC);
                            break;
                        case 2:
                            ClsMain.ListaCC2.Add(CC);
                            break;
                        case 3:
                            ClsMain.ListaCC3.Add(CC);
                            break;
                        case 4:
                            ClsMain.ListaCC4.Add(CC);
                            break;
                        case 5:
                            ClsMain.ListaCC5.Add(CC);
                            break;
                    }
                }
            }
        }

        private void RevisarCheck(string item)
        {
            CheckBox oCheck = (CheckBox)oForm.Items.Item(item).Specific;
            string boton = "btnDim" + item.Substring(item.Length - 1, 1);

            oForm.Items.Item(boton).Visible = oCheck.Checked;
        }

        private bool ObtenerFechas(out DateTime fIni, out DateTime fFin)
        {
            UserDataSource dtIni = oForm.DataSources.UserDataSources.Item("uDTini");
            UserDataSource dtFin = oForm.DataSources.UserDataSources.Item("uDTfin");

            fIni = ClsMain.oCompany.GetCompanyDate();
            fFin = ClsMain.oCompany.GetCompanyDate();
            string error = string.Empty;

            if (string.IsNullOrEmpty(dtIni.ValueEx))
            {
                error = "Debe ingresar la fecha de inicio";
                goto finalizar;
            }

            if (string.IsNullOrEmpty(dtFin.ValueEx))
            {
                error = "Debe ingresar la fecha final";
                goto finalizar;
            }

            fIni = DateTime.ParseExact(dtIni.ValueEx, "yyyyMMdd", null);
            fFin = DateTime.ParseExact(dtFin.ValueEx, "yyyyMMdd", null);

            if (fFin.Year != fIni.Year)
            {
                error = "Las fechas del reporte deben pertenecer al mismo año";
                goto finalizar;
            }

            if (fFin.CompareTo(fIni) < 0)
            {
                error = "La fecha final debe ser posterior a la fecha de inicio";
                goto finalizar;
            }

        finalizar:
            if (!string.IsNullOrEmpty(error))
            {
                ClsMain.MensajeError(error, true);
                return false;
            }

            return true;
        }

        private void ChooseFromList(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (pVal.BeforeAction)
            {
                return;
            }

            try
            {
                switch (pVal.ItemUID)
                {
                    default:
                        break;
                }
            }
            catch (Exception ex)
            {
                logger.Error("ChooseFromList", ex);
            }
        }

        private void SetComentario(DateTime Fecha)
        {
            string mes = string.Empty;
            switch (Fecha.Month)
            {
                case 1: mes = "Enero"; break;
                case 2: mes = "Febrero"; break;
                case 3: mes = "Marzo"; break;
                case 4: mes = "Abril"; break;
                case 5: mes = "Mayo"; break;
                case 6: mes = "Junio"; break;
                case 7: mes = "Julio"; break;
                case 8: mes = "Agosto"; break;
                case 9: mes = "Setiembre"; break;
                case 10: mes = "Octubre"; break;
                case 11: mes = "Noviembre"; break;
                case 12: mes = "Diciembre"; break;
            }
            string comentario = $"Ajuste Kardex {mes} {Fecha.Year.ToString()}";
            oForm.DataSources.DBDataSources.Item("@EXX_AKDX").SetValue("U_MEMO", 0, comentario);
        }

        private void FormLoad(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (pVal.BeforeAction)
            {
                return;
            }
        }

        private void FormActivate(ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            if (pVal.BeforeAction)
            {
                return;
            }

            if (ClsMain.FrmDimActivo)
            {
                BubbleEvent = false;
                DevolverFocoDim();
            }
        }

        void DevolverFocoDim()
        {
            try
            {
                ClsMain.oApplication.Forms.Item("FrmDim").Visible = false;
                ClsMain.oApplication.Forms.Item("FrmDim").Select();
                ClsMain.oApplication.Forms.Item("FrmDim").Visible = true;
                ClsMain.oApplication.Forms.Item("FrmDim").Select();

            }
            catch { }
        }
        */
    }
}