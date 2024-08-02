
using CrystalDecisions.CrystalReports.Engine;
using CrystalDecisions.Shared;
using Itenso.TimePeriod;
using Reportes.Entidades;
using Reportes.Util;
using SAPbobsCOM;
using SAPbouiCOM;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
//using System.Drawing.Drawing2D;
//using System.Linq;
//using System.Windows.Forms;

namespace Reportes.Events.ItemEvent
{
    internal class AImprimirItemEvent : IObjectItemEvent
    {
        _IApplicationEvents_ItemEventEventHandler itemEventHandler;
        Form formModal, formReprogramacion;
        string FormID;
        static string UbicacionIngresada = string.Empty, NewMaquinaCode = string.Empty, NewMaquinaDesc = string.Empty, NewVelocidad = string.Empty, velocidadMaquina = string.Empty;
        static DateTime FechaReprog;
        static string HoraReprog = string.Empty;
        static string OrdSeleccionada = string.Empty;
        public ProgramadorOrdenes Programador { get; set; }
        Dictionary<int, int> selecciones = new Dictionary<int, int>();
        string docNumAux;

        public AImprimirItemEvent()
        {
            Programador = new ProgramadorOrdenes();
        }

        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(AProgramItemEvent));
        private Form oForm;

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
                        FormLoad(ref pVal);
                        break;
                    case BoEventTypes.et_FORM_ACTIVATE:
                        //FormActivate(ref pVal, out BubbleEvent);
                        break;
                    case BoEventTypes.et_VALIDATE:
                        if(pVal.InnerEvent == false && pVal.ItemChanged)
                        {
                            //FormValidate(ref pVal, out BubbleEvent);
                        }
                        break;
                    case BoEventTypes.et_ITEM_PRESSED:
                        ItemPressed(ref pVal, out BubbleEvent);
                        break;
                    case BoEventTypes.et_CLICK:
                        ItemClicked(ref pVal, out BubbleEvent);
                        break;
                    case BoEventTypes.et_DOUBLE_CLICK:
                        BubbleEvent = false;
                        break;
                    case BoEventTypes.et_COMBO_SELECT:
                        ComboSelected(ref pVal, out BubbleEvent);
                        break;
                    case BoEventTypes.et_MATRIX_LINK_PRESSED:
                        //MatrixLinkPressed(ref pVal, out BubbleEvent);
                        break;
                    case BoEventTypes.et_FORM_CLOSE:
                        break;
                }
            }
            catch (Exception ex)
            {
                logger.Error("ItemEventAction", ex);
            }
        }

        private void FormValidate(ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            Matrix matrix = oForm.Items.Item("Item_14").Specific;
            double pendiente = 0;
            double distribuidos = 0;
            SAPbouiCOM.EditText EditValue;
            EditText oEdit = ((EditText)oForm.Items.Item("txtKg").Specific);
            double Kg = Convert.ToDouble(oEdit.Value.ToString().Trim());
            pendiente = Kg;
            for (int i = 1; i <= matrix.RowCount; i++)
            {
                string strValue;
                double cantidad = 0;
                EditValue = (SAPbouiCOM.EditText)matrix.GetCellSpecific("Col_1", i);
                strValue = EditValue.Value.ToString().Trim();
                cantidad = Convert.ToDouble(strValue);
                distribuidos += cantidad;
                if(distribuidos>pendiente)
                {

                    ClsMain.MensajeError("La cantidad ingresada supera al total de Kg asignados");
                    EditValue.Value = "0";
                    distribuidos -= cantidad;
                }
            }
            pendiente = Kg - distribuidos;

            oForm.Items.Item("txtDistr").Specific.Value = distribuidos;
            oForm.Items.Item("txtPend").Specific.Value = pendiente;

            //Column oColumn = matrix.Columns.Item("SelOrder");
            //oColumn.TitleObject.Sortable = true;

        }
        private void FormLoad(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (!pVal.BeforeAction)
            {
                //Matrix matrix = oForm.Items.Item("Item_14").Specific;
                
                
                //Column oColumn = matrix.Columns.Item("SelOrder");
                //oColumn.TitleObject.Sortable = true;
            }
        }

        private void MatrixLinkPressed(ref SAPbouiCOM.ItemEvent pVal, out bool bubbleEvent)
        {
            bubbleEvent = true;

            Matrix matrix = oForm.Items.Item("Item_14").Specific;

            if (pVal.BeforeAction && pVal.ColUID == "maquina")
            {
                try
                {
                    oForm.Freeze(true);
                    docNumAux = matrix.GetCellSpecific("maquina", pVal.Row).Value;
                    string docEntry = matrix.GetCellSpecific("Col_0", pVal.Row).Value;

                    matrix.GetCellSpecific("Order", pVal.Row).Value = docEntry;
                }
                catch (Exception)
                {
                    throw;
                }
                finally { oForm.Freeze(false); }

            }

            if (!pVal.BeforeAction && pVal.ColUID == "maquina")
            {
                matrix.GetCellSpecific("maquina", pVal.Row).Value = docNumAux;
            }
        }

        private void ComboSelected(ref SAPbouiCOM.ItemEvent pVal, out bool bubbleEvent)
        {
            bubbleEvent = true;

            try
            {
                switch (pVal.ItemUID)
                {
                    //case "cboOrden":
                    //case "cboVisual":

                    //    if (!pVal.BeforeAction)
                    //        MostrarOrdenes();

                    //    break;
                }
            }
            catch (Exception)
            {
                throw;
            }
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
                   
                    case "btnOk":
                        if (!pVal.BeforeAction)
                        {
                            BubbleEvent = false;
                        }
                        break;                  
                    case "btnPre":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        {
                            Visualizar(ref pVal);
                        }
                        break;
                }
            }
            catch (Exception ex)
            {
                logger.Error("ItemPressed", ex);
                ClsMain.MensajeError(ex.Message);
            }
        }

  
        private void ItemClicked(ref SAPbouiCOM.ItemEvent pVal, out bool bubbleEvent)
        {
            bubbleEvent = true;
            try
            {
                switch (pVal.ItemUID)
                {
                    //case "matOrders":

                    //    if (pVal.BeforeAction && pVal.ColUID == "check" && pVal.Row > 0)
                    //    {
                    //        //bubbleEvent = ValidarEtapas(pVal.Row);
                    //    }

                    //    if (!pVal.BeforeAction && pVal.ColUID == "check" && pVal.Row > 0)
                    //    {
                    //        //AccionClickEnCheck(pVal.Row);
                    //    }

                    //    break;
                }

            }
            catch (Exception)
            {

            }
        }

        private void ChooseFromList(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (!pVal.BeforeAction)
            {
                switch (pVal.ItemUID)
                {
                    case "txtOrden":
                        cflOrderEntry(ref pVal);
                        break;

                    //RECURSO
                    case "txtMaquina":
                        cflRecurso(ref pVal);
                        break;
                }
            }
        }

        private void cflRecurso(ref SAPbouiCOM.ItemEvent pVal)
        {
            SAPbouiCOM.DataTable dtSelect = null;
            try
            {
                IChooseFromListEvent oCFLEvento = (IChooseFromListEvent)pVal;

                if (!oCFLEvento.Before_Action && oCFLEvento.ChooseFromListUID == "CFL_0")
                {
                    dtSelect = oCFLEvento.SelectedObjects;

                    if (dtSelect != null)
                    {

                        oForm.DataSources.UserDataSources.Item("UfMaquina").Value = dtSelect.GetValue("ResCode", 0).ToString();
                        //oForm.DataSources.UserDataSources.Item("UD_RECNO").Value = dtSelect.GetValue("ResName", 0).ToString();
                    }
                }
            }
            catch (Exception ex) { }
        }

        private void cflOrderEntry(ref SAPbouiCOM.ItemEvent pVal)
        {
            SAPbouiCOM.DataTable dtSelect = null;
            try
            {
                IChooseFromListEvent oCFLEvento = (IChooseFromListEvent)pVal;

                if (!oCFLEvento.Before_Action && oCFLEvento.ChooseFromListUID == "cflOrden")
                {
                    dtSelect = oCFLEvento.SelectedObjects;

                    if (dtSelect != null)
                    {
                        EditText oEdit = ((EditText)oForm.Items.Item("txtOrden").Specific);
                        oEdit.Value = dtSelect.GetValue("DocEntry", 0).ToString();
                        oForm.DataSources.UserDataSources.Item("uFOrden").Value = oEdit.Value;
                    }
                }
            }
            catch { }
        }
       
        void AgregarLinea(ref SAPbouiCOM.ItemEvent pVal)
        {
            SAPbouiCOM.DataTable oDataTable = null;
            Matrix oMatrix = oForm.Items.Item("Item_14").Specific;
            oDataTable = oForm.DataSources.DataTables.Item("DT_0");
            oMatrix.FlushToDataSource();

            //if (oMatrix.RowCount == 0) oDataTable.Rows.Clear();
            oDataTable.Rows.Add();
            oMatrix.LoadFromDataSource();
            oMatrix.AutoResizeColumns();

        }

        void Visualizar(ref SAPbouiCOM.ItemEvent pVal)
        {

            //EditText oEdit = ((EditText)oForm.Items.Item("txtKg").Specific);
            //double Kg = Convert.ToDouble(oEdit.Value.ToString().Trim());
            //EditText oPend= ((EditText)oForm.Items.Item("txtPend").Specific);
            //double Pend = Convert.ToDouble(oPend.Value.ToString().Trim());
            DateTime Desde = Convert.ToDateTime(oForm.DataSources.UserDataSources.Item("UfDesde").Value);
            DateTime Hasta = Convert.ToDateTime(oForm.DataSources.UserDataSources.Item("UfHasta").Value);
            string maquina = oForm.DataSources.UserDataSources.Item("UfMaquina").Value;

            SAPbouiCOM.ComboBox oCombo = default(SAPbouiCOM.ComboBox);
            oCombo = (SAPbouiCOM.ComboBox)oForm.Items.Item("txtEtapa").Specific;

            string etapa = oCombo.Selected.Value;

            string HoraD = oForm.DataSources.UserDataSources.Item("UfHoraD").Value;
            string HoraH = oForm.DataSources.UserDataSources.Item("UfHoraH").Value;
            string check = "";
            string ruta = "";
            string nombre = "";
            try
            {
                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
                string query;
                if (ClsMain.oCompany.DbServerType == BoDataServerTypes.dst_HANADB)
                {
                    query = $@"SELECT T0.""U_EXP_CHECK"", T0.""U_EXP_RUTA"" , T0.""U_EXP_REPORTE"" FROM ORST T0 WHERE T0.""AbsEntry"" =" +etapa;
                }
                else
                {
                    query = $@"SELECT T0.""U_EXP_CHECK"", T0.""U_EXP_RUTA"", T0.""U_EXP_REPORTE""  FROM ORST T0 WHERE T0.""AbsEntry"" =" + etapa;
                }
                logger.Debug(query);
                oRS.DoQuery(query);

                if (!oRS.EoF)
                {
                    check = oRS.Fields.Item(0).Value;
                    ruta = oRS.Fields.Item(1).Value;
                    nombre = oRS.Fields.Item(2).Value;
                }
            }
            catch (Exception ex) { }

            try
            {
                string pathPDF = "";
                DateTime Fecha = DateTime.Now;
                ReportDocument crRpt = new ReportDocument();
                string rutareporte = ruta + "\\" + nombre;
                crRpt.Load(rutareporte);
                using (crRpt)
                {
                    //crRpt.SetDatabaseLogon("sapsql", "Sap*21smc");
                    crRpt.SetDatabaseLogon("SYSTEM", "181311Erick*1");

                    if (ClsMain.oCompany.DbServerType == BoDataServerTypes.dst_HANADB)
                    {
                        crRpt.SetParameterValue("FINI", Desde);
                        crRpt.SetParameterValue("FFIN", Hasta);

                        crRpt.SetParameterValue("HORAI", HoraD);
                        crRpt.SetParameterValue("HORAF", HoraH);
                        crRpt.SetParameterValue("ETAPA", etapa);
                        crRpt.SetParameterValue("RECURSO", maquina);


                    }
                    else
                    {
                        crRpt.SetParameterValue("@FINI", Desde);
                        crRpt.SetParameterValue("@FFIN", Hasta);

                        crRpt.SetParameterValue("@HORAI", HoraD);
                        crRpt.SetParameterValue("@HORAF", HoraH);
                        crRpt.SetParameterValue("@ETAPA", etapa);
                        crRpt.SetParameterValue("@RECURSO", maquina);

                    }

                    var ss = DateTime.Now;

                    var nameFile = nombre + "_" + Fecha.ToString("yyyyMMddHHmmss") + ".pdf";


                    pathPDF = ruta + "\\Reportes\\" + nameFile;
                    crRpt.ExportToDisk(ExportFormatType.PortableDocFormat, pathPDF);
                    crRpt.Close();
                }

                System.Diagnostics.Process proc = new System.Diagnostics.Process();
                proc.StartInfo.FileName = pathPDF;
                proc.Start();
                proc.Close();

            }
            catch (Exception ex) { }


        }
        private void Cerrar()
        {
            ClsMain.oApplication.ItemEvent -= itemEventHandler;
        }

    

        private void ProcesarMatrix()
        {
            SAPbouiCOM.DataTable oDTorders = oForm.DataSources.DataTables.Item("dtOrders");


            if (oDTorders.Rows.Count == 0)
            {
                ClsMain.MensajeError("No se encontraron ordenes de fabricación que cumplan los filtros requeridos", true);
                return;
            }

            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;

            //OCULTAMOS LA COLUMNA DE DOCENTRY
            oMatOrdenes.Columns.Item("Col_2").Visible = false;

            LimpiarMatrix(ref oMatOrdenes);
            if (oDTorders.Columns.Count > 28)
            {
                for (int i = 28; i < oDTorders.Columns.Count; i++)
                {
                    string coldt = oDTorders.Columns.Item(i).Name;
                    Column oNewCol = oMatOrdenes.Columns.Add(NombreCol(coldt), BoFormItemTypes.it_EDIT);
                    oNewCol.DataBind.Bind("dtOrders", coldt);
                    oNewCol.TitleObject.Caption = coldt;
                    oNewCol.Editable = false;
                    if (oDTorders.Columns.Item(i).Type == BoFieldsType.ft_Float || oDTorders.Columns.Item(i).Type == BoFieldsType.ft_Sum)
                    {
                        oNewCol.RightJustified = true;
                    }
                }
            }

            oMatOrdenes.LoadFromDataSource();
            oMatOrdenes.AutoResizeColumns();
        }

        void LimpiarMatrix(ref Matrix oMatOrdenes)
        {
            int rowcount = oMatOrdenes.RowCount;
            for (int j = 1; j <= rowcount; j++)
            {
                oMatOrdenes.DeleteRow(1);
            }
            int colcount = oMatOrdenes.Columns.Count;
            for (int i = 23; i < colcount; i++)
            {
                oMatOrdenes.Columns.Remove(23);
            }
        }

        string NombreCol(string colname)
        {
            string ncol = colname.Replace(" ", "").ToLower();
            if (ncol.Length > 10) ncol = ncol.Substring(0, 10);
            return ncol;
        }

    }
}