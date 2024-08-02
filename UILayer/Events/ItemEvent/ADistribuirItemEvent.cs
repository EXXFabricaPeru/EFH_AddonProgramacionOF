using Itenso.TimePeriod;
using Reportes.Entidades;
using Reportes.Util;
using SAPbobsCOM;
using SAPbouiCOM;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Threading;
using System.Windows.Forms;
using static System.Windows.Forms.LinkLabel;
//using System.Drawing.Drawing2D;
//using System.Linq;
//using System.Windows.Forms;

namespace Reportes.Events.ItemEvent
{
    internal class ADistribuirItemEvent : IObjectItemEvent
    {
        _IApplicationEvents_ItemEventEventHandler itemEventHandler;
        SAPbouiCOM.Form formModal, formReprogramacion;
        string FormID;
        static string UbicacionIngresada = string.Empty, NewMaquinaCode = string.Empty, NewMaquinaDesc = string.Empty, NewVelocidad = string.Empty, velocidadMaquina = string.Empty;
        static DateTime FechaReprog;
        static string HoraReprog = string.Empty;
        static string OrdSeleccionada = string.Empty;
        public ProgramadorOrdenes Programador { get; set; }
        Dictionary<int, int> selecciones = new Dictionary<int, int>();
        string docNumAux;
        public static bool bUpdatePO = false;
        public static bool bAddLine = false;
        public static SAPbouiCOM.Form oFormPadre ;
        public ADistribuirItemEvent()
        {
            Programador = new ProgramadorOrdenes();
        }

        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(AProgramItemEvent));
        private SAPbouiCOM.Form oForm;

        public void ItemEventAction(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                oForm = ClsMain.oApplication.Forms.Item(FormUID);
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case BoEventTypes.et_FORM_LOAD:
                            Form0Load(ref pVal);
                            break;
                    }
                }
                //else if (pVal.FormTypeEx == "65211")
                //{
                //    switch (pVal.EventType)
                //    {
                //        //case BoEventTypes.et_FORM_DEACTIVATE:
                //        //case BoEventTypes.et_CLICK:
                //        case BoEventTypes.et_FORM_MENU_HILIGHT:
                //            ItemClickedPO(ref pVal, out BubbleEvent);
                //            break;
                //    }
                //}
                else
                {
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
                            if (pVal.InnerEvent == false && pVal.ItemChanged)
                            {
                                FormValidate(ref pVal, out BubbleEvent);
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
                            MatrixLinkPressed(ref pVal, out BubbleEvent);
                            break;
                        case BoEventTypes.et_FORM_CLOSE:
                            break;
                    }
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
                if (distribuidos > pendiente)
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

        private void Form0Load(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (!pVal.BeforeAction)
            {
                //if (bUpdatePO)
                {
                    SAPbouiCOM.Form oform = ClsMain.oApplication.Forms.Item(pVal.FormUID);
                    oform.Items.Item("1").Click(SAPbouiCOM.BoCellClickType.ct_Regular);
                }
            }
        }


        private void FormLoad(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (!pVal.BeforeAction)
            {
                Matrix matrix = oForm.Items.Item("Item_14").Specific;


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
                    case "btnAdd":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        {
                            AgregarLinea(ref pVal);
                        }
                        break;
                    case "btnGrabar":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        {
                            Guardar(ref pVal);
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

        private void ItemClickedPO(ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = false;
            try
            {
                if (!pVal.BeforeAction)
                {
                    if (bAddLine)
                    {
                        SAPbouiCOM.Form POForm = ClsMain.oApplication.Forms.ActiveForm;
                        int sdv = POForm.Menu.Count;
                        for (int i = 0; i < POForm.Menu.Count; i++)
                        {
                            //ClsMain.oApplication.SetStatusBarMessage(POForm.Menu.Item(i).UID +"-"+ POForm.Menu.Item(i).String, BoMessageTime.bmt_Short, false);

                            if (POForm.Menu.Item(i).UID == "1292")
                            {
                                POForm.Menu.Item(POForm.Menu.Item(i).UID).Activate();
                                bAddLine = false;
                                break;
                            }
                            if (POForm.Menu.Item(i).SubMenus != null)
                            {
                                for (int j = 0; j < POForm.Menu.Item(i).SubMenus.Count; i++)
                                {
                                    if (POForm.Menu.Item(i).SubMenus.Item(j).UID == "1292")
                                    {
                                        POForm.Menu.Item(j).SubMenus.Item(POForm.Menu.Item(i).SubMenus.Item(j).UID).Activate();
                                        bAddLine = false;
                                        break;
                                    }
                                }
                            }
                        }

                        //ClsMain.oApplication.SendKeys("Ñ");
                        //ClsMain.oApplication.SendKeys("{DOWN}");
                        //ClsMain.oApplication.SendKeys("{DOWN}");
                        //ClsMain.oApplication.SendKeys("{DOWN}");
                        //ClsMain.oApplication.ActivateMenuItem("1292");

                    }



                    //switch (pVal.ItemUID)
                    //{
                    //    case "37":
                    //        if (pVal.ColUID == "0")
                    //        {
                    //            Thread.Sleep(100);
                    //            ClsMain.oApplication.SendKeys("{DOWN}");
                    //            ClsMain.oApplication.SendKeys("{DOWN}");
                    //            ClsMain.oApplication.SendKeys("{DOWN}");
                    //            ClsMain.oApplication.SendKeys("{DOWN}");
                    //            ClsMain.oApplication.SendKeys("{DOWN}");
                    //        }
                    //        break;
                    //}
                }
            }
            catch (Exception)
            {
                bAddLine = true;
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
                    case "Item_14":
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
                Matrix oMatrix = oForm.Items.Item("Item_14").Specific;

                //SAPbouiCOM.DataTable oDataTable = oForm.DataSources.DataTables.Item("DT_0");

                if (!oCFLEvento.Before_Action && oCFLEvento.ChooseFromListUID == "CFL_0")
                {
                    dtSelect = oCFLEvento.SelectedObjects;

                    if (dtSelect != null)
                    {
                        int selrow = oMatrix.GetNextSelectedRow(0, SAPbouiCOM.BoOrderType.ot_RowOrder);

                        //oDataTable.SetValue(pVal.ItemUID, selrow, dtSelect);
                        //oMatrix.SelectRow(pVal.Row, true,false);
                        ((SAPbouiCOM.EditText)oMatrix.Columns.Item("Col_0").Cells.Item(pVal.Row).Specific).Value = dtSelect.GetValue("ResCode", 0).ToString();

                        //oForm.DataSources.UserDataSources.Item("UD_RECCOD").Value = dtSelect.GetValue("ResCode", 0).ToString();
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
            if (oMatrix.RowCount == 0)
            {
                oDataTable.Rows.Add();
                oMatrix.LoadFromDataSource();
                oMatrix.AutoResizeColumns();
                oMatrix.DeleteRow(1);
            }
            else
            {
                oDataTable.Rows.Add();
                oMatrix.LoadFromDataSource();
                oMatrix.AutoResizeColumns();
            }

        }

        void Guardar(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatrix = oForm.Items.Item("Item_14").Specific;
            EditText oEdit = ((EditText)oForm.Items.Item("txtKg").Specific);
            double Kg = Convert.ToDouble(oEdit.Value.ToString().Trim());
            EditText oPend = ((EditText)oForm.Items.Item("txtPend").Specific);
            double Pend = Convert.ToDouble(oPend.Value.ToString().Trim());
            EditText oEtapa = ((EditText)oForm.Items.Item("txtEtapa").Specific);
            int etapa = Convert.ToInt32(oEtapa.Value.ToString().Trim());
            EditText oDocNum = ((EditText)oForm.Items.Item("txtOrden").Specific);
            string docNum = oDocNum.Value.ToString().Trim();
            string Recurso = oForm.DataSources.UserDataSources.Item("UD_2").Value;


            int DocEntry = Convert.ToInt32(oForm.DataSources.UserDataSources.Item("UD_1").Value);
            int linea = Convert.ToInt32(oForm.DataSources.UserDataSources.Item("UD_0").Value) + 2;
            for (int i = oMatrix.RowCount; i >=1 ; i--)
            {
                EditText maquina = (SAPbouiCOM.EditText)oMatrix.GetCellSpecific("Col_0", i);
                if (string.IsNullOrEmpty(maquina.Value)) { oMatrix.DeleteRow(i); }

            }


            if (oMatrix.RowCount > 0)
            {


                SAPbouiCOM.MenuItem menuItem = ClsMain.oApplication.Menus.Item("4352");
                if (menuItem.SubMenus.Count > 0)
                {
                    for (int i = 0; i < menuItem.SubMenus.Count; i++)
                    {
                        if (menuItem.SubMenus.Item(i).String.Contains("Orden"))
                        {
                            menuItem.SubMenus.Item(i).Activate();
                            break;
                        }
                    }
                }
                SAPbouiCOM.Form POForm = ClsMain.oApplication.Forms.ActiveForm;
                POForm.Mode = BoFormMode.fm_FIND_MODE;
                ((SAPbouiCOM.EditText)POForm.Items.Item("18").Specific).Value = docNum;
                ((SAPbouiCOM.Button)POForm.Items.Item("1").Specific).Item.Click(BoCellClickType.ct_Regular);
                SAPbouiCOM.Matrix oDetalle = (SAPbouiCOM.Matrix)POForm.Items.Item("37").Specific;
                int MaxLinea = oDetalle.VisualRowCount;
                int ultimaEtapa = Convert.ToInt32(((SAPbouiCOM.ComboBox)oDetalle.Columns.Item("2550000048").Cells.Item(MaxLinea).Specific).Selected.Value);

                for (int i = 1; i <= oMatrix.RowCount; i++)
                {
                    string strKG, strRec;
                    double cantidad = 0;
                    EditText maquina = (SAPbouiCOM.EditText)oMatrix.GetCellSpecific("Col_0", i);
                    strRec = maquina.Value.ToString().Trim();
                    EditText Kilogramos = (SAPbouiCOM.EditText)oMatrix.GetCellSpecific("Col_1", i);
                    strKG = Kilogramos.Value.ToString().Trim();
                    cantidad = Convert.ToDouble(strKG);
                    double hh = Convert.ToDouble(((SAPbouiCOM.EditText)oDetalle.Columns.Item("14").Cells.Item(linea).Specific).Value);
                    double nh = hh * cantidad / Kg;

                    bAddLine = true;
                    oDetalle.Columns.Item("4").Cells.Item(linea + i).Click(BoCellClickType.ct_Double);
                    ClsMain.oApplication.ActivateMenuItem("1292");

                    ((SAPbouiCOM.ComboBox)oDetalle.Columns.Item("1880000002").Cells.Item(linea + i).Specific).Select("290", BoSearchKey.psk_ByValue);
                    ((SAPbouiCOM.EditText)oDetalle.Columns.Item("4").Cells.Item(linea + i).Specific).Value = strRec;
                    ((SAPbouiCOM.EditText)oDetalle.Columns.Item("14").Cells.Item(linea + i).Specific).Value = nh.ToString();
                    ((SAPbouiCOM.EditText)oDetalle.Columns.Item("10").Cells.Item(linea + i).Specific).Value = "001";
                    ((SAPbouiCOM.EditText)oDetalle.Columns.Item("U_EXP_KGFOR").Cells.Item(linea+i).Specific).Value = cantidad.ToString();

                }

                if (Pend > 0)
                {
                    double hh = Convert.ToDouble(((SAPbouiCOM.EditText)oDetalle.Columns.Item("14").Cells.Item(linea).Specific).Value);
                    double nh = hh * Pend / Kg;
                    ((SAPbouiCOM.EditText)oDetalle.Columns.Item("14").Cells.Item(linea).Specific).Value = nh.ToString();
                    ((SAPbouiCOM.EditText)oDetalle.Columns.Item("U_EXP_KGFOR").Cells.Item(linea).Specific).Value = Pend.ToString();

                }
                else
                {
                    oDetalle.Columns.Item("4").Cells.Item(linea).Click(BoCellClickType.ct_Double);
                    ClsMain.oApplication.ActivateMenuItem("1293");
                }

                if (POForm.Mode == BoFormMode.fm_UPDATE_MODE)
                {
                    bUpdatePO = true;
                    POForm.Items.Item("1").Click();
                    bUpdatePO = false;
                }
                POForm.Close();
                oForm.Close();
                var mc = new AProgramItemEvent();
                mc.oForm = oFormPadre;
                mc.MostrarOrdenes();
            }
            else
            {
                ClsMain.MensajeError("No hay datos ingresados");
            }

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