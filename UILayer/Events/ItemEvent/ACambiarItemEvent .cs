
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
    internal class ACambiarItemEvent : IObjectItemEvent
    {
        _IApplicationEvents_ItemEventEventHandler itemEventHandler;
        Form formModal, formReprogramacion;
        string FormID;
        static string UbicacionIngresada = string.Empty, NewMaquinaCode = string.Empty, NewMaquinaDesc = string.Empty, NewVelocidad = string.Empty, velocidadMaquina = string.Empty;
        static DateTime FechaReprog;
        static string HoraReprog = string.Empty;
        static string OrdSeleccionada = string.Empty;
        public static ProgramadorOrdenes Programador { get; set; }
        Dictionary<int, int> selecciones = new Dictionary<int, int>();
        string docNumAux;
        public static SAPbouiCOM.Form oFormPadre;

        public ACambiarItemEvent()
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
                        if (pVal.InnerEvent == false && pVal.ItemChanged)
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
                        //ComboSelected(ref pVal, out BubbleEvent);
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
                    case "btnCambio":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        {
                            string NewMaquinaCode = oForm.DataSources.UserDataSources.Item("Maquina").Value.ToString();
                            string NewMaquinaDesc = oForm.DataSources.UserDataSources.Item("Descrip").Value.ToString();
                            List<OrdenFabricacion> list =  Programador.OrdenesFabricacion;
                            var mc = new AProgramItemEvent();
                            mc.oForm = oFormPadre;
                            oForm.Close();

                            mc.FillMaquina(NewMaquinaCode, NewMaquinaDesc, list);

                        }
                        break;
                    case "2":
                        {
                            oForm.Close();
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
                    case "Item_0":
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

                        oForm.DataSources.UserDataSources.Item("Maquina").Value = dtSelect.GetValue("ResCode", 0).ToString();
                        oForm.DataSources.UserDataSources.Item("Descrip").Value = dtSelect.GetValue("ResName", 0).ToString();
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
    } 
       
}