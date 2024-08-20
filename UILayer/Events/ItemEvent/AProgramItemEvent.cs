using CrystalDecisions.CrystalReports.Engine;
using Itenso.TimePeriod;
using Reportes.Entidades;
using Reportes.Util;
using SAPbobsCOM;
using SAPbouiCOM;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
//using System.Drawing.Drawing2D;
using System.Linq;
using static log4net.Appender.RollingFileAppender;
//using System.Windows.Forms;

namespace Reportes.Events.ItemEvent
{
    internal class AProgramItemEvent : IObjectItemEvent
    {
        _IApplicationEvents_ItemEventEventHandler itemEventHandler;
        Form formModal, formReprogramacion, formCambiar;
        string FormID;
        static string UbicacionIngresada = string.Empty, NewMaquinaCode = string.Empty, NewMaquinaDesc = string.Empty, NewVelocidad = string.Empty, velocidadMaquina = string.Empty;
        static DateTime FechaReprog;
        static string HoraReprog = string.Empty;
        static string OrdSeleccionada = string.Empty;
        public ProgramadorOrdenes Programador { get; set; }
        Dictionary<int, int> selecciones = new Dictionary<int, int>();
        string docNumAux;
        bool valid = true;
        public AProgramItemEvent()
        {
            Programador = new ProgramadorOrdenes();
        }

        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(AProgramItemEvent));
        public Form oForm;

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
            catch (Exception ex)
            {
                logger.Error("ItemEventAction", ex);
            }
        }

        private void ValidateChecks(ref SAPbouiCOM.ItemEvent pVal)
        {
            try
            {
                oForm.Freeze(true);

                Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                var y = Programador.OrdenesFabricacion;

                foreach (var item in Programador.OrdenesFabricacion)
                {
                    if (!item.Programado)
                    {
                        Programador.OrdenesFabricacion.Where(x => x.IndiceEnMatrix == item.IndiceEnMatrix).FirstOrDefault().OrdenMarcacion = 0;
                    }


                }



                for (int i = 1; i <= oMatOrdenes.RowCount; i++)
                {
                    string programadoSel = oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value;
                    CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(i).Specific;
                    EditText order = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(i).Specific;
                    if (oCheck.Checked && programadoSel == "N")
                    {
                        order.Value = "0";
                        Programador.OrdenesFabricacion.Where(x => x.IndiceEnMatrix == i).FirstOrDefault().Seleccionado = true;
                    }

                }
                int cont = 1;
                for (int i = 1; i <= oMatOrdenes.RowCount; i++)
                {
                    string programadoSel = oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value;
                    CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(i).Specific;
                    string order = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(i).Specific.Value;
                    if (oCheck.Checked && programadoSel == "N" && order == "0")
                    //AccionClickEnCheck2(i);
                    {
                        try
                        {

                            //Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                            //CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(fila).Specific;

                            int orden = Convert.ToInt32(oMatOrdenes.Columns.Item("Col_2").Cells.Item(i).Specific.Value);
                            string recurso = oMatOrdenes.Columns.Item("Col_1").Cells.Item(i).Specific.Value;
                            int etapa = Convert.ToInt32(oMatOrdenes.Columns.Item("StageId").Cells.Item(i).Specific.Value);
                            //string programadoSel = oMatOrdenes.Columns.Item("Scheduled").Cells.Item(fila).Specific.Value;

                            Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().Seleccionado = oCheck.Checked;

                            //int ordenSeleccion = oCheck.Checked ? Programador.OrdenesFabricacion.Where(x => x.Seleccionado).ToList().Count : 0;

                            int programados = Programador.OrdenesFabricacion.Count(x => x.Programado);
                            int list = Programador.OrdenesFabricacion.Where(x => x.Seleccionado && x.Programado == false).ToList().Count;
                            int ordenSeleccion = oCheck.Checked ? cont + programados : 0;

                            Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().OrdenMarcacion = ordenSeleccion;

                            //actualización
                            if (oCheck.Checked)
                            {
                                if (programadoSel == "N")
                                    oMatOrdenes.Columns.Item("SelOrder").Cells.Item(i).Specific.Value = ordenSeleccion.ToString();
                                oMatOrdenes.SelectRow(i, true, true);

                            }
                            else
                            {
                                if (!Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().ProgramadoEnSAP)
                                {
                                    Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().Programado = false;
                                    oMatOrdenes.Columns.Item("ProgDate").Cells.Item(i).Specific.Value = string.Empty;
                                    oMatOrdenes.Columns.Item("Col_0").Cells.Item(i).Specific.Value = string.Empty;
                                    oMatOrdenes.Columns.Item("StartTime").Cells.Item(i).Specific.Value = "00:00";
                                    oMatOrdenes.Columns.Item("FinishTime").Cells.Item(i).Specific.Value = "00:00";
                                }

                                int ordenDesmarcado = Convert.ToInt32(oMatOrdenes.Columns.Item("SelOrder").Cells.Item(i).Specific.Value);
                                ActualizarOrden(ref oMatOrdenes, ordenDesmarcado);

                                if (programadoSel == "N")
                                    oMatOrdenes.Columns.Item("SelOrder").Cells.Item(i).Specific.Value = ordenSeleccion.ToString();

                                oMatOrdenes.SelectRow(i, false, true);
                            }

                        }
                        catch (Exception ex)
                        {
                            logger.Error(ex.Message, ex);
                        }
                        finally
                        {
                            cont++;
                            //oForm.Freeze(false);
                        }

                    }


                }
            }
            catch (Exception ex2)
            {
                logger.Error(ex2.Message, ex2);
            }
            finally
            {
                oForm.Freeze(false);

            }
           

        }

        private void FormLoad(ref SAPbouiCOM.ItemEvent pVal)
        {
            if (!pVal.BeforeAction)
            {
                Matrix matrix = oForm.Items.Item("matOrders").Specific;
                Column oColumn = matrix.Columns.Item("SelOrder");
                oColumn.TitleObject.Sortable = true;
            }
        }

        private void MatrixLinkPressed(ref SAPbouiCOM.ItemEvent pVal, out bool bubbleEvent)
        {
            bubbleEvent = true;

            Matrix matrix = oForm.Items.Item("matOrders").Specific;

            if (pVal.BeforeAction && pVal.ColUID == "Order")
            {
                try
                {
                    oForm.Freeze(true);
                    docNumAux = matrix.GetCellSpecific("Order", pVal.Row).Value;
                    string docEntry = matrix.GetCellSpecific("Col_2", pVal.Row).Value;

                    matrix.GetCellSpecific("Order", pVal.Row).Value = docEntry;
                }
                catch (Exception)
                {
                    throw;
                }
                finally { oForm.Freeze(false); }

            }

            if (!pVal.BeforeAction && pVal.ColUID == "Order")
            {
                matrix.GetCellSpecific("Order", pVal.Row).Value = docNumAux;
            }
        }

        private void ComboSelected(ref SAPbouiCOM.ItemEvent pVal, out bool bubbleEvent)
        {
            bubbleEvent = true;

            try
            {
                switch (pVal.ItemUID)
                {
                    case "cboOrden":
                    case "cboVisual":

                        if (!pVal.BeforeAction)
                            MostrarOrdenes();

                        break;
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
                            PrevisualizarPorSeleccion();
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
                        { MostrarOrdenes(); }
                        break;
                    case "btnMover":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { MoverSeleccion(ref pVal); }
                        break;
                    case "btnOrdn":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { OrdenarSeleccion(); }
                        break;
                    case "btnReprog":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { Reprogramar(ref pVal); }
                        break;
                    case "btnProg":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { ProgramarSeleccion(ref pVal); }//Programar
                        break;
                    case "btnStand":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { StandbySeleccion(ref pVal); }//Standby
                        break;
                    case "btnAnul":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { AnularSeleccion(ref pVal); }//Anul
                        break;
                    case "btnMaq":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { CambiarMaquinaSeleccion(ref pVal); }//CambiarMaquina
                        break;
                    case "btnAsig":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { AsignarMaquinaSeleccion(ref pVal); }//AsignarMaquina
                        break;
                    case "btnTemp":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { CambiarTiempoSeleccion(ref pVal); }//Tiempo
                        break;
                    case "btnParc":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { ParcialSeleccion(ref pVal); }//Parcial
                        break;
                    case "btnTerm":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { TerminarSeleccion(ref pVal); }//Terminado
                        break;
                    case "btnPrint":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        {
                            MostrarImpresion(ref pVal);
                            //MoverSeleccion(ref pVal);
                        }//Impresion
                        break;
                    case "btnMaqxKg":
                        if (!pVal.BeforeAction && !pVal.InnerEvent)
                        { DistribuirSeleccion(ref pVal); }//Distribuir
                        break;

                }
            }
            catch (Exception ex)
            {
                logger.Error("ItemPressed", ex);
                ClsMain.MensajeError(ex.Message);
            }
        }

        private void OrdenarSeleccion()
        {
            try
            {
                oForm.Freeze(true);
                Matrix matrix = oForm.Items.Item("matOrders").Specific;
                Column oColumn = matrix.Columns.Item("SelOrder");
                oColumn.TitleObject.Sortable = true;
                oColumn.TitleObject.Sort(BoGridSortType.gst_Ascending);

                matrix.AutoResizeColumns();
                oColumn.Width = 80;

                ReordenarIndicesDeMatrix();
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }


        private void ReordenarIndicesDeMatrix()
        {
            if (Programador.OrdenesFabricacion != null)
            {
                Programador.OrdenesFabricacion.ForEach(c => c.IndiceEnMatrix = c.OrdenMarcacion); //QUIERE DECIR QUE AHORA EL ORDEN DE MARCACIÓN ES EL MISMO QUE EL ORDEN DE MATRIX
            }
        }

        private void ItemClicked(ref SAPbouiCOM.ItemEvent pVal, out bool bubbleEvent)
        {
            bubbleEvent = true;
            try
            {
                switch (pVal.ItemUID)
                {
                    case "matOrders":

                        if (pVal.BeforeAction && pVal.ColUID == "check" && pVal.Row > 0)
                        {
                            bubbleEvent = ValidarEtapas(pVal.Row);
                        }

                        if (!pVal.BeforeAction && pVal.ColUID == "check" && pVal.Row > 0)
                        {
                            AccionClickEnCheck2(pVal.Row);
                        }

                        if (!pVal.BeforeAction && valid)
                        {
                            //ValidateChecks(ref pVal);
                        }

                        break;
                }

            }
            catch (Exception)
            {

            }
        }

        private bool ValidarEtapas(int row)
        {
            string validar = oForm.DataSources.UserDataSources.Item("uValidar").Value;

            if (validar == "Y")
            {
                Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(row).Specific;

                if (!oCheck.Checked) //SOLO VALIDAMOS ANTES DE SELECCIONAR, PARA LA DESELECCIÓN NO SE VALIDA
                {
                    int orden = Convert.ToInt32(oMatOrdenes.Columns.Item("Col_2").Cells.Item(row).Specific.Value);
                    int etapa = Convert.ToInt32(oMatOrdenes.Columns.Item("StageId").Cells.Item(row).Specific.Value);

                    if (!Programador.FiltroPorRecurso) //SE VALIDA SOBRE LO QUE MUESTRA LA MATRIX
                    {
                        if (Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa < etapa && !x.Seleccionado && !x.ProgramadoEnSAP).ToList().Count > 0)
                        {
                            ClsMain.oApplication.StatusBar.SetText("Debe programar todos los recursos de las etapas anteriores de la orden: " + orden, BoMessageTime.bmt_Short, BoStatusBarMessageType.smt_Error);
                            return false;
                        }
                    }
                    else //SE VALIDA SOBRE LA BD, PARA SABER SI HAY ALGUN RECURSO SIN PROGRAMAR ANTERIOR
                    {
                        return ValidarEtapasFiltroRecurso(orden, etapa);
                    }
                }
            }

            return true;
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
                    case "Item_5":
                        cflRecurso(ref pVal);
                        break;
                    case "Item_13":
                        cflSocio(ref pVal);
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
                        oForm.DataSources.UserDataSources.Item("UD_RECCOD").Value = dtSelect.GetValue("ResCode", 0).ToString();
                        oForm.DataSources.UserDataSources.Item("UD_RECNO").Value = dtSelect.GetValue("ResName", 0).ToString();
                    }
                }
            }
            catch (Exception ex) { }
        }

        private void cflSocio(ref SAPbouiCOM.ItemEvent pVal)
        {
            SAPbouiCOM.DataTable dtSelect = null;
            try
            {
                IChooseFromListEvent oCFLEvento = (IChooseFromListEvent)pVal;

                if (!oCFLEvento.Before_Action && oCFLEvento.ChooseFromListUID == "CFL_1")
                {
                    dtSelect = oCFLEvento.SelectedObjects;

                    if (dtSelect != null)
                    {
                        oForm.DataSources.UserDataSources.Item("UD_RAZSOC").Value = dtSelect.GetValue("CardCode", 0).ToString();
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
        void DistribuirSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarOrdenSeleccion(ref oMatOrdenes, out int seleccionados, out string orden, out string etapa, out string maquina, out string kg);
            if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar recursos que esté marcado con check");
                return;
            }
            if (seleccionados > 1)
            {
                ClsMain.MensajeError("Debe seleccionar sólo un recurso");
                return;
            }
            UbicacionIngresada = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            int DocEntry = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada)).Select(x => x.NroOrdenFabricacion).FirstOrDefault();
            int linea = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada)).Select(x => x.LineaOF).FirstOrDefault();
            string ResCode = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada)).Select(x => x.Recurso).FirstOrDefault();

            MostrarVentanaDistribuir(oForm, orden, etapa, maquina, kg, DocEntry, linea, ResCode);


        }


        void MoverSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados);
            if (seleccionados > 1)
            {
                ClsMain.MensajeError("Debe seleccionar sólo un recurso");
                return;
            }
            else if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar un recurso que esté marcado con check");
                return;
            }
            UbicacionIngresada = string.Empty;
            MostrarVentanaCambioUbicacion();
            if (!string.IsNullOrEmpty(UbicacionIngresada))
            {
                CambiarUbicacionIngresada(ref oMatOrdenes);
            }
            else
            {
                ClsMain.MensajeWarning("No ingresó una ubicación");
            }
        }

        void ProgramarSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados, false, true);
            if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar recursos que esté marcado con check y NO programados");
                return;
            }
            else if (seleccionados == -1)
            {
                ClsMain.MensajeError("Solo debe seleccionar recursos NO programados");
                return;
            }
            UbicacionIngresada = string.Empty;
            MostrarVentanaProgramar();
            if (!string.IsNullOrEmpty(UbicacionIngresada))
            {
                HoraReprog = "";
                ProgramarSeleccionado(ref oMatOrdenes);
            }
            else
            {
                ClsMain.MensajeWarning("No ingresó una ubicación");
            }
        }
        void CambiarMaquinaSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados,true);
            if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar recursos que esté marcado con check y previamente programados");
                return;
            }
            NewMaquinaCode = "";
            MostrarVentanaCambiarMaquina(oForm);

            //if (!string.IsNullOrEmpty(NewMaquinaCode))
            //{
            //    CambiarMaquinaSeleccionado(ref oMatOrdenes);
            //}
            //else
            //{
            //    ClsMain.MensajeWarning("No ingresó cambio de maquina");
            //}
        }

        void AsignarMaquinaSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados,false,true);
            if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar un recurso que esté marcado con check y no programados");
                return;
            }
            NewMaquinaCode = "";
            MostrarVentanaCambiarMaquina(oForm);

            //if (!string.IsNullOrEmpty(NewMaquinaCode))
            //{
            //    CambiarMaquinaSeleccionado(ref oMatOrdenes);
            //}
            //else
            //{
            //    ClsMain.MensajeWarning("No ingresó cambio de maquina");
            //}
        }

        void CambiarTiempoSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados);
            if (seleccionados > 1)
            {
                ClsMain.MensajeError("Debe seleccionar sólo un recurso");
                return;
            }
            else if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar un recurso que esté marcado con check");
                return;
            }
            NewVelocidad = "";
            UbicacionIngresada = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            velocidadMaquina = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada)).Select(x => x.Velocidad).FirstOrDefault();
            MostrarVentanaActualizarTiempo();
            if (!string.IsNullOrEmpty(NewVelocidad))
            {
                CambiarVelocidadSeleccionado(ref oMatOrdenes);
            }
            else
            {
                ClsMain.MensajeWarning("No ingresó nueva velocidad");
            }
        }
        void AnularSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados);
            if (seleccionados > 1)
            {
                ClsMain.MensajeError("Debe seleccionar sólo un recurso");
                return;
            }
            else if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar un recurso que esté marcado con check");
                return;
            }
            UbicacionIngresada = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            OrdSeleccionada = oMatOrdenes.Columns.Item("Order").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            if (MostrarVentanaAnulacion())
            {
                AnularSeleccionado(ref oMatOrdenes);
            }
        }
        void StandbySeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados, true); //se quito el true al final
            if (seleccionados == -1)
            {
                ClsMain.MensajeError("Solo debe seleccionar recursos previamente programados");
                return;
            }
            else if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar un recurso que esté marcado con check");
                return;
            }
            OrdSeleccionada = oMatOrdenes.Columns.Item("Order").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            UbicacionIngresada = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            if (MostrarVentanaStandBy())
            {
                StandBySeleccionado(ref oMatOrdenes);
            }
        }
        void TerminarSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados);
            if (seleccionados > 1)
            {
                ClsMain.MensajeError("Debe seleccionar sólo un recurso");
                return;
            }
            else if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar un recurso que esté marcado con check");
                return;
            }
            UbicacionIngresada = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            OrdSeleccionada = oMatOrdenes.Columns.Item("Order").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            if (MostrarVentanaTerminar())
            {
                TerminarSeleccionado(ref oMatOrdenes);
            }
        }
        void ParcialSeleccion(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados, true);
            if (seleccionados == -1)
            {
                ClsMain.MensajeError("Solo debe seleccionar recursos previamente programados");
                return;
            }
            UbicacionIngresada = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            OrdSeleccionada = oMatOrdenes.Columns.Item("Order").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;
            if (MostrarVentanaParcial())
            {
                ParcialSeleccionado(ref oMatOrdenes);
            }
        }

        void Reprogramar(ref SAPbouiCOM.ItemEvent pVal)
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados, true);
            if (seleccionados == 0)
            {
                ClsMain.MensajeError("Debe seleccionar recursos que esté marcado con check y previamente programados");
                return;
            }
            else if (seleccionados == -1)
            {
                ClsMain.MensajeError("Solo debe seleccionar recursos previamente programados");
                return;
            }
            UbicacionIngresada = string.Empty;
            FechaReprog = DateTime.ParseExact(oForm.Items.Item("txtFProg").Specific.Value, "yyyyMMdd", null);
            HoraReprog = oForm.Items.Item("Item_11").Specific.String;
            MostrarVentanaReprogramar();
            if (!string.IsNullOrEmpty(UbicacionIngresada) && !string.IsNullOrEmpty(FechaReprog.ToString()) && !string.IsNullOrEmpty(HoraReprog))
            {
                ReprogramarSeleccion(ref oMatOrdenes);
            }
            else
            {
                ClsMain.MensajeWarning("No ingresó datos completos para reprogramar");
            }
        }

        void BuscarSelecciones(ref Matrix oMatOrdenes, out int seleccionados, bool isProgramado = false, bool isNotProgramado = false)
        {
            selecciones = new Dictionary<int, int>();
            seleccionados = 0;
            for (int i = 1; i <= oMatOrdenes.RowCount; i++)
            {
                if (oMatOrdenes.Columns.Item("check").Cells.Item(i).Specific.Checked)
                {

                    if (!isProgramado || !isNotProgramado
                        || (isProgramado && oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value.Equals("Y"))
                        || (isNotProgramado && oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value.Equals("N")))
                    {
                        EditText oEditLinea = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(i).Specific;
                        selecciones.Add(i, int.Parse(oEditLinea.String));

                        if (isProgramado && oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value.Equals("Y")
                             && !oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value.Equals("N") && oMatOrdenes.IsRowSelected(i)) // programados
                        {
                            seleccionados++;
                        }
                        else if (isNotProgramado && oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value.Equals("N")
                             && !oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value.Equals("Y") && oMatOrdenes.IsRowSelected(i))
                        { seleccionados++; }
                        else if (!isProgramado && !isNotProgramado && oMatOrdenes.IsRowSelected(i))
                        { seleccionados++; }
                    }
                    else
                    {
                        seleccionados = -1;
                        return;
                    }
                }

            }
        }
        void BuscarOrdenSeleccion(ref Matrix oMatOrdenes, out int seleccionados, out string orden, out string etapa, out string maquina, out string kg, bool isProgramado = false, bool isNotProgramado = false)
        {
            selecciones = new Dictionary<int, int>();
            seleccionados = 0;
            orden = "";
            maquina = "";
            etapa = "";
            kg = "";
            for (int i = 1; i <= oMatOrdenes.RowCount; i++)
            {
                if (oMatOrdenes.Columns.Item("check").Cells.Item(i).Specific.Checked)
                {
                    if (!isProgramado || !isNotProgramado
                        || (isProgramado && oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value.Equals("Y"))
                        || (isNotProgramado && oMatOrdenes.Columns.Item("Scheduled").Cells.Item(i).Specific.Value.Equals("N")))
                    {
                        EditText oEditLinea = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(i).Specific;
                        selecciones.Add(i, int.Parse(oEditLinea.String));
                        if (oMatOrdenes.IsRowSelected(i))
                        {
                            orden = oMatOrdenes.Columns.Item("Order").Cells.Item(i).Specific.Value;
                            etapa = oMatOrdenes.Columns.Item("StageId").Cells.Item(i).Specific.Value;
                            maquina = oMatOrdenes.Columns.Item("Resource").Cells.Item(i).Specific.Value;
                            kg = oMatOrdenes.Columns.Item("ReqQuant").Cells.Item(i).Specific.Value;
                            seleccionados++;
                        }
                    }
                    else
                    {
                        seleccionados = -1;
                        return;
                    }
                }
            }
        }
        private void CambiarUbicacionIngresada(ref Matrix oMatOrdenes)
        {
            oForm.Freeze(true);
            try
            {
                if (int.TryParse(UbicacionIngresada, out int ubicacionNueva))
                {
                    if (ubicacionNueva > selecciones.Count)
                    {
                        ClsMain.MensajeError("La ubicación ingresada debe ser menor o igual a la cantidad de registros marcados");
                    }
                    else
                    {
                        int lineaseleccionada = oMatOrdenes.GetNextSelectedRow();
                        int actual = selecciones[lineaseleccionada];
                        bool isLast = ubicacionNueva == selecciones.Count;
                        int menor = 0;
                        if (actual == ubicacionNueva)
                        {
                            ClsMain.MensajeError("La ubicación ingresada debe ser diferente a la actual");
                            return;
                        }
                        if (actual < ubicacionNueva) menor = actual;
                        else menor = ubicacionNueva;


                        var RefRegister = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == menor + (isLast ? -1 : 0)).FirstOrDefault();
                        if (RefRegister == null)
                        {
                            RefRegister = new OrdenFabricacion();

                            RefRegister.FechaInicio = ((EditText)oForm.Items.Item("txtFProg").Specific).Value;
                            RefRegister.FechaFin = ((EditText)oForm.Items.Item("txtFProg").Specific).Value;
                            RefRegister.HoraInicio = ((EditText)oForm.Items.Item("Item_11").Specific).Value;
                            RefRegister.HoraFin = ((EditText)oForm.Items.Item("Item_11").Specific).Value;

                            string timeString = RefRegister.HoraInicio;
                            string timeFormatted = timeString.Insert(2, ":");
                            RefRegister.HoraInicio = timeFormatted;
                            timeString = RefRegister.HoraFin;
                            timeFormatted = timeString.Insert(2, ":");
                            RefRegister.HoraFin = timeFormatted;

                        }

                        if (FechaReprog == DateTime.MinValue) FechaReprog = DateTime.ParseExact((isLast ? RefRegister.FechaFin : RefRegister.FechaInicio), "yyyyMMdd", null);
                        if (string.IsNullOrEmpty(HoraReprog)) HoraReprog = (isLast ? RefRegister.HoraFin : RefRegister.HoraInicio);


                        var sorted = selecciones.OrderBy(x => x.Value);

                        Dictionary<int, int> nuevaseleccion = new Dictionary<int, int>();

                        bool disminuir = false;
                        nuevaseleccion.Add(lineaseleccionada, ubicacionNueva);
                        if (ubicacionNueva < actual)
                        {
                            disminuir = true;
                            foreach (KeyValuePair<int, int> seleccionado in sorted)
                            {
                                if (seleccionado.Value < ubicacionNueva) continue;
                                if (seleccionado.Value == actual)
                                {
                                    var myKey = sorted.FirstOrDefault(x => x.Value == ubicacionNueva).Key;
                                    nuevaseleccion.Add(myKey, seleccionado.Value);

                                }
                                if (seleccionado.Value < actual && seleccionado.Value != ubicacionNueva)
                                {
                                    nuevaseleccion.Add(seleccionado.Key, seleccionado.Value);
                                }
                                else if (seleccionado.Value != actual && seleccionado.Value != ubicacionNueva)
                                {
                                    nuevaseleccion.Add(seleccionado.Key, seleccionado.Value);
                                }
                            }
                        }
                        else
                        {
                            foreach (KeyValuePair<int, int> seleccionado in sorted)
                            {
                                if (seleccionado.Value < actual) continue;

                                if (seleccionado.Value == actual)
                                {
                                    var myKey = sorted.FirstOrDefault(x => x.Value == ubicacionNueva).Key;
                                    nuevaseleccion.Add(myKey, seleccionado.Value);

                                }
                                if (seleccionado.Value > actual && seleccionado.Value != ubicacionNueva)
                                {
                                    nuevaseleccion.Add(seleccionado.Key, seleccionado.Value);
                                }
                                else if (seleccionado.Value != actual && seleccionado.Value != ubicacionNueva)
                                {
                                    //continue;
                                    nuevaseleccion.Add(seleccionado.Key, seleccionado.Value);
                                }
                            }
                        }
                        valid = false;
                        sorted = nuevaseleccion.OrderBy(x => x.Value);
                        QuitarCheck(ref oMatOrdenes, nuevaseleccion);
                        System.Threading.Thread.Sleep(500);
                        foreach (KeyValuePair<int, int> seleccionado in sorted)
                        {
                            CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(seleccionado.Key).Specific;
                            oCheck.Checked = true;
                            ComboBox oCombo = oMatOrdenes.Columns.Item("Scheduled").Cells.Item(seleccionado.Key).Specific;
                            oCombo.Select("N", BoSearchKey.psk_ByValue);
                            if (disminuir && seleccionado.Value < ubicacionNueva) continue;
                            if (!disminuir && seleccionado.Value > ubicacionNueva) continue;

                            Programador.OrdenesFabricacion.Where(x => x.IndiceEnMatrix == seleccionado.Key).FirstOrDefault().DtFechaInicio = DateTime.MinValue;
                            Programador.OrdenesFabricacion.Where(x => x.IndiceEnMatrix == seleccionado.Key).FirstOrDefault().DtFechaFin = DateTime.MinValue;
                            Programador.OrdenesFabricacion.Where(x => x.IndiceEnMatrix == seleccionado.Key).FirstOrDefault().HoraFin = "";
                            Programador.OrdenesFabricacion.Where(x => x.IndiceEnMatrix == seleccionado.Key).FirstOrDefault().HoraInicio = "";

                            oMatOrdenes.Columns.Item("ProgDate").Cells.Item(seleccionado.Key).Specific.Value = string.Empty;
                            oMatOrdenes.Columns.Item("Col_0").Cells.Item(seleccionado.Key).Specific.Value = string.Empty;
                            oMatOrdenes.Columns.Item("StartTime").Cells.Item(seleccionado.Key).Specific.Value = "00:00";
                            oMatOrdenes.Columns.Item("FinishTime").Cells.Item(seleccionado.Key).Specific.Value = "00:00";
                            AccionClickEnCheck(seleccionado.Key);
                        }
                        valid = true;
                        UbicacionIngresada = menor.ToString();
                        Reprogramador(ref oMatOrdenes);

                        //PrevisualizarPorSeleccion();
                    }
                }
                else
                {
                    ClsMain.MensajeError("La ubicación ingresada debe ser numérica");
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
            finally
            {
                oForm.Freeze(false);
            }
        }

        private void QuitarCheck(ref Matrix oMatOrdenes, Dictionary<int, int> nuevaseleccion)
        {
            foreach (KeyValuePair<int, int> seleccionado in nuevaseleccion)
            {
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(seleccionado.Key).Specific;
                oCheck.Checked = false;
            }
        }

        private void MostrarVentanaCambioUbicacion()
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionCambioUbicacion);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            ClsMain.oApplication.MessageBox("Cambio de ubicación", 1, "Aceptar", "Cancelar");
        }
        private bool MostrarVentanaAnulacion()
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionAnulacion);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            return 1 == ClsMain.oApplication.MessageBox("Anulación", 1, "Aceptar", "Cancelar");
        }
        private bool MostrarVentanaTerminar()
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionTerminar);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            return 1 == ClsMain.oApplication.MessageBox("Terminado", 1, "Aceptar", "Cancelar");
        }
        private bool MostrarVentanaParcial()
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionParcial);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            return 1 == ClsMain.oApplication.MessageBox("Parcial", 1, "Aceptar", "Cancelar");
        }
        private bool MostrarVentanaStandBy()
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionStandBy);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            return ClsMain.oApplication.MessageBox("StandBy", 1, "Aceptar", "Cancelar") == 1;
        }

        private void MostrarVentanaReprogramar()
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionReprogramar);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            ClsMain.oApplication.MessageBox("Reprogramacion", 1, "Aceptar", "Cancelar");
        }

        private void MostrarVentanaImprimir()//TODO
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionReprogramar);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            ClsMain.oApplication.MessageBox("Impresión", 1, "Previsualizar", "Cancelar");
        }
        private void MostrarVentanaActualizarTiempo()//TODO
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionCambioTiempo);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            ClsMain.oApplication.MessageBox("ActualizarTiempo", 1, "Actualizar", "Cancelar");
        }
        private void MostrarVentanaCambiarMaquina(Form oForm)//TODO
        {
            InicializarModalCambioMaquina(oForm);
            //itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionCambioMaquina);
            //ClsMain.oApplication.ItemEvent += itemEventHandler;
            //ClsMain.oApplication.MessageBox("CambiarMaquina", 1, "Cambiar", "Cancelar");
        }
        private void MostrarVentanaProgramar()//TODO
        {
            itemEventHandler = new _IApplicationEvents_ItemEventEventHandler(DoActionProgramar);
            ClsMain.oApplication.ItemEvent += itemEventHandler;
            ClsMain.oApplication.MessageBox("Programar", 1, "Programar", "Cancelar");
        }

        private void MostrarImpresion(ref SAPbouiCOM.ItemEvent pVal)
        {
            try
            {
                SAPbouiCOM.Form oForm = default(SAPbouiCOM.Form);
                try
                {
                    oForm = ClsMain.oApplication.Forms.Item("frmImpresion");
                    ClsMain.oApplication.MessageBox("El formulario ya se encuentra abierto.");
                }
                catch //(Exception ex)
                {
                    SAPbouiCOM.FormCreationParams fcp = default(SAPbouiCOM.FormCreationParams);
                    fcp = ClsMain.oApplication.CreateObject(SAPbouiCOM.BoCreatableObjectType.cot_FormCreationParams);
                    fcp.BorderStyle = SAPbouiCOM.BoFormBorderStyle.fbs_Sizable;
                    fcp.FormType = "frmImpres";
                    fcp.UniqueID = "frmImpres_2";
                    string FormName = "\\Forms\\frmImpresion.srf";

                    fcp.XmlData = ClsMain.LoadFromXML(ref FormName);
                    oForm = ClsMain.oApplication.Forms.AddEx(fcp);
                }

                oForm.Top = 50;
                oForm.Left = 345;
                oForm.Visible = true;

                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);

                //se agrego campo para seleccionar sucursal
                SAPbouiCOM.ComboBox oCombo = default(SAPbouiCOM.ComboBox);
                oCombo = (SAPbouiCOM.ComboBox)oForm.Items.Item("txtEtapa").Specific;

                string Query = $@"SELECT T0.""AbsEntry"", T0.""Desc"" FROM ORST T0";
                oRS.DoQuery(Query);
                if (oCombo.ValidValues.Count > 0)
                {
                    for (int e = 0; e <= oCombo.ValidValues.Count; e++)
                    {
                        oCombo.ValidValues.Remove(e, SAPbouiCOM.BoSearchKey.psk_Index);
                    }
                }
                if (oRS.RecordCount > 0)
                {
                    while (oRS.EoF == false)
                    {
                        oCombo.ValidValues.Add(oRS.Fields.Item(0).Value.ToString().Trim(), oRS.Fields.Item(1).Value.ToString().Trim());
                        oRS.MoveNext();
                    }
                }

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        private void MostrarVentanaDistribuir(Form oFormPadre, string Orden, string Etapa, string Maquina, string KG, int DocEntry, int linea, string Recurso)
        {
            try
            {
                SAPbouiCOM.Form oForm = default(SAPbouiCOM.Form);
                try
                {
                    oForm = ClsMain.oApplication.Forms.Item("frmKilosMaq");
                    ClsMain.oApplication.MessageBox("El formulario ya se encuentra abierto.");
                }
                catch //(Exception ex)
                {
                    SAPbouiCOM.FormCreationParams fcp = default(SAPbouiCOM.FormCreationParams);
                    fcp = ClsMain.oApplication.CreateObject(SAPbouiCOM.BoCreatableObjectType.cot_FormCreationParams);
                    fcp.BorderStyle = SAPbouiCOM.BoFormBorderStyle.fbs_Sizable;
                    fcp.FormType = "frmKilosMaq";
                    fcp.UniqueID = "frmKilosMaq_2";
                    string FormName = "\\Forms\\frmMaqxKg.srf";

                    fcp.XmlData = ClsMain.LoadFromXML(ref FormName);
                    oForm = ClsMain.oApplication.Forms.AddEx(fcp);
                }

                oForm.Top = 50;
                oForm.Left = 345;
                oForm.Visible = true;

                oForm.Items.Item("txtOrden").Specific.Value = Orden;
                oForm.Items.Item("txtEtapa").Specific.Value = Etapa;
                oForm.Items.Item("txtMaqAct").Specific.Value = Maquina;
                oForm.Items.Item("txtKg").Specific.Value = KG;
                oForm.Items.Item("txtDistr").Specific.Value = "0.00";
                oForm.Items.Item("txtPend").Specific.Value = KG;
                SAPbouiCOM.DataTable oDataTable = null;
                oForm.DataSources.UserDataSources.Item("UD_1").Value = DocEntry.ToString();
                oForm.DataSources.UserDataSources.Item("UD_0").Value = linea.ToString();
                oForm.DataSources.UserDataSources.Item("UD_2").Value = Recurso;

                //if (oForm.DataSources.DataTables.Count.Equals(0))
                //{
                //    oForm.DataSources.DataTables.Add("DT_0");
                //}
                //else
                //{
                //    oForm.DataSources.DataTables.Item("DT_0").Clear();
                //}
                SAPbouiCOM.Matrix oMatrix = oForm.Items.Item("Item_14").Specific;
                oDataTable = oForm.DataSources.DataTables.Item("DT_0");
                //oDataTable.Columns.Add("maquina", SAPbouiCOM.BoFieldsType.ft_AlphaNumeric, 254);
                //oDataTable.Columns.Add("kilogramos", SAPbouiCOM.BoFieldsType.ft_Float, 254);

                //SAPbouiCOM.Column oColumn;

                //oColumn = oMatrix.Columns.Item("Col_0");
                //oColumn.DataBind.Bind("DT_0", "maquina");
                //oColumn = oMatrix.Columns.Item("Col_1");
                //oColumn.DataBind.Bind("DT_0", "kilogramos");
                oMatrix.FlushToDataSource();
                oDataTable.Rows.Clear();
                oDataTable.Rows.Add();
                oMatrix.LoadFromDataSource();
                oMatrix.AutoResizeColumns();
                oForm.Refresh();
                ADistribuirItemEvent.oFormPadre = oFormPadre;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }


        private void InicializarModalCambioUbicacion()
        {
            try
            {
                for (int i = 0; i < ClsMain.oApplication.Forms.Count; i++)
                {
                    Form frm = ClsMain.oApplication.Forms.Item(i);
                    if (frm.Modal && frm.TypeEx == "0")
                    {
                        StaticText st = (StaticText)frm.Items.Item("7").Specific;
                        if (st.Caption == "Cambio de ubicación")
                        {
                            formModal = frm;
                            FormID = frm.UniqueID;
                        }
                    }
                }
                formModal.Title = "Cambio de ubicación";
                formModal.ClientWidth = 180;
                formModal.ClientHeight = 110;
                formModal.Left = (ClsMain.oApplication.Desktop.Width - formModal.Width) / 2;
                formModal.Top = (ClsMain.oApplication.Desktop.Height - formModal.Height) / 2 - 100;
                formModal.Items.Item("11").Visible = false;
                formModal.Items.Item("7").Visible = false;

                IItem item;
                StaticText lbl;

                item = formModal.Items.Add("lblmsj0", SAPbouiCOM.BoFormItemTypes.it_STATIC);
                item.Left = 9;
                item.Top = 20;
                item.Width = 150;
                lbl = (StaticText)item.Specific;
                lbl.Caption = "Ingrese el número de posición";

                item = formModal.Items.Add("txtPos", SAPbouiCOM.BoFormItemTypes.it_EDIT);
                item.Left = 9;
                item.Top = 40;
                item.Width = 150;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }

        private void InicializarModalYesNo(string caption, string mensaje)
        {
            try
            {
                for (int i = 0; i < ClsMain.oApplication.Forms.Count; i++)
                {
                    Form frm = ClsMain.oApplication.Forms.Item(i);
                    if (frm.Modal && frm.TypeEx == "0")
                    {
                        StaticText st = (StaticText)frm.Items.Item("7").Specific;
                        if (st.Caption == caption)
                        {
                            formModal = frm;
                            FormID = frm.UniqueID;
                        }
                    }
                }
                formModal.Title = caption;
                formModal.ClientWidth = 280;
                formModal.ClientHeight = 110;
                formModal.Left = (ClsMain.oApplication.Desktop.Width - formModal.Width) / 2;
                formModal.Top = (ClsMain.oApplication.Desktop.Height - formModal.Height) / 2 - 100;
                formModal.Items.Item("11").Visible = false;
                formModal.Items.Item("7").Visible = false;

                IItem item;
                StaticText lbl;

                item = formModal.Items.Add("lblmsj0", SAPbouiCOM.BoFormItemTypes.it_STATIC);
                item.Left = 9;
                item.Top = 20;
                item.Width = 250;
                lbl = (StaticText)item.Specific;
                lbl.Caption = mensaje;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }


        private void InicializarModalCambioTiempo()
        {
            try
            {
                for (int i = 0; i < ClsMain.oApplication.Forms.Count; i++)
                {
                    SAPbouiCOM.Form frm = ClsMain.oApplication.Forms.Item(i);
                    if (frm.Modal && frm.TypeEx == "0")
                    {
                        StaticText st = (StaticText)frm.Items.Item("7").Specific;
                        if (st.Caption == "ActualizarTiempo")
                        {
                            formModal = frm;
                            FormID = frm.UniqueID;
                        }
                    }
                }
                formModal.Title = "Actualizacion Tiempo";
                formModal.ClientWidth = 180;
                formModal.ClientHeight = 110;
                formModal.Left = (ClsMain.oApplication.Desktop.Width - formModal.Width) / 2;
                formModal.Top = (ClsMain.oApplication.Desktop.Height - formModal.Height) / 2 - 100;
                formModal.Items.Item("11").Visible = false;
                formModal.Items.Item("7").Visible = false;

                IItem oItm;
                StaticText lbl;
                EditText oTxt;
                oItm = formModal.Items.Add("lblmsj0", SAPbouiCOM.BoFormItemTypes.it_STATIC);
                oItm.Left = 9;
                oItm.Top = 20;
                oItm.Width = 150;
                lbl = (StaticText)oItm.Specific;
                lbl.Caption = "Nueva Velocidad";

                formModal.DataSources.UserDataSources.Add("UD_VEL", BoDataType.dt_SHORT_NUMBER, 6);
                oItm = formModal.Items.Add("txtPos", SAPbouiCOM.BoFormItemTypes.it_EDIT);
                oItm.Left = 9;
                oItm.Top = 40;
                oItm.Width = 150;
                oTxt = (EditText)oItm.Specific;
                oTxt.DataBind.SetBound(true, "", "UD_VEL");
                formModal.DataSources.UserDataSources.Item("UD_VEL").Value = velocidadMaquina;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
        private void InicializarModalCambioMaquina(Form oFormPadre)
        {
            try
            {


                SAPbouiCOM.Form oForm = default(SAPbouiCOM.Form);
                try
                {
                    oForm = ClsMain.oApplication.Forms.Item("frmCambiar");
                    ClsMain.oApplication.MessageBox("El formulario ya se encuentra abierto.");
                }
                catch //(Exception ex)
                {
                    SAPbouiCOM.FormCreationParams fcp = default(SAPbouiCOM.FormCreationParams);
                    fcp = ClsMain.oApplication.CreateObject(SAPbouiCOM.BoCreatableObjectType.cot_FormCreationParams);
                    fcp.BorderStyle = SAPbouiCOM.BoFormBorderStyle.fbs_Sizable;
                    fcp.FormType = "frmCambiar";
                    fcp.UniqueID = "frmCambiar_2";
                    string FormName = "\\Forms\\frmCambio.srf";
                    fcp.XmlData = ClsMain.LoadFromXML(ref FormName);
                    oForm = ClsMain.oApplication.Forms.AddEx(fcp);

                }
                ACambiarItemEvent.oFormPadre = oFormPadre;
                ACambiarItemEvent.Programador.OrdenesFabricacion = Programador.OrdenesFabricacion;
                oForm.Top = 50;
                oForm.Left = 345;
                oForm.Visible = true;

                //NewMaquinaCode = oFormPadre.DataSources.UserDataSources.Item("UD_14").Value.ToString();
                //NewMaquinaDesc = oFormPadre.DataSources.UserDataSources.Item("UD_15").Value.ToString();



                //                for (int i = 0; i < ClsMain.oApplication.Forms.Count; i++)
                //                {
                //                    Form frm = ClsMain.oApplication.Forms.Item(i);
                //                    if (frm.Modal && frm.TypeEx == "0")
                //                    {
                //                        StaticText st = (StaticText)frm.Items.Item("7").Specific;
                //                        if (st.Caption == "CambiarMaquina")
                //                        {
                //                            formModal = frm;
                //                            FormID = frm.UniqueID;
                //                        }
                //                    }
                //                }
                //                formModal.Title = "Cambio de Maquina";
                //                formModal.ClientWidth = 250;
                //                formModal.ClientHeight = 110;
                //                formModal.Left = (ClsMain.oApplication.Desktop.Width - formModal.Width) / 2;
                //                formModal.Top = (ClsMain.oApplication.Desktop.Height - formModal.Height) / 2 - 100;
                //                formModal.Items.Item("11").Visible = false;
                //                formModal.Items.Item("7").Visible = false;

                //                IItem item;
                //                StaticText lbl;
                //                EditText edt;


                //                SAPbouiCOM.ChooseFromListCollection oCFLs;
                //                SAPbouiCOM.ChooseFromListCreationParams oCFLCreationParams;
                //                SAPbouiCOM.ChooseFromList oCFL;

                //                oCFLs = formModal.ChooseFromLists;

                //                oCFLCreationParams = ClsMain.oApplication.CreateObject(SAPbouiCOM.BoCreatableObjectType.cot_ChooseFromListCreationParams);
                //                oCFLCreationParams.MultiSelection = false;
                //                oCFLCreationParams.ObjectType = "2";
                //                oCFLCreationParams.UniqueID = "CFL_0";
                //                oCFL = oCFLs.Add(oCFLCreationParams);

                //                item = formModal.Items.Add("lblmsj0", SAPbouiCOM.BoFormItemTypes.it_STATIC);
                //                item.Left = 9;
                //                item.Top = 20;
                //                item.Width = 150;
                //                lbl = (StaticText)item.Specific;
                //                lbl.Caption = "Seleccionar Maquina";
                ///**/


                //                item = formModal.Items.Add("txtPos", SAPbouiCOM.BoFormItemTypes.it_EDIT);
                //                item.Left = 9;
                //                item.Top = 40;
                //                item.Width = 50;
                //                edt = item.Specific;
                //                edt.ChooseFromListAlias = "ResCode";
                //                edt.ChooseFromListUID = "CFL_0";

                //                item = formModal.Items.Add("txtDet", SAPbouiCOM.BoFormItemTypes.it_EDIT);
                //                //item.Enabled = false;
                //                item.Left = 55;
                //                item.Top = 40;
                //                item.Width = 100;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }

        private void InicializarModalProgramar()
        {
            try
            {
                for (int i = 0; i < ClsMain.oApplication.Forms.Count; i++)
                {
                    Form frm = ClsMain.oApplication.Forms.Item(i);
                    if (frm.Modal && frm.TypeEx == "0")
                    {
                        StaticText st = (StaticText)frm.Items.Item("7").Specific;
                        if (st.Caption == "Programar")
                        {
                            formModal = frm;
                            FormID = frm.UniqueID;
                        }
                    }
                }
                formModal.Title = "Programación";
                formModal.ClientWidth = 180;
                formModal.ClientHeight = 110;
                formModal.Left = (ClsMain.oApplication.Desktop.Width - formModal.Width) / 2;
                formModal.Top = (ClsMain.oApplication.Desktop.Height - formModal.Height) / 2 - 100;
                formModal.Items.Item("11").Visible = false;
                formModal.Items.Item("7").Visible = false;

                IItem item;
                StaticText lbl;

                item = formModal.Items.Add("lblmsj0", SAPbouiCOM.BoFormItemTypes.it_STATIC);
                item.Left = 9;
                item.Top = 20;
                item.Width = 150;
                lbl = (StaticText)item.Specific;
                lbl.Caption = "# de Linea";

                item = formModal.Items.Add("txtPos", SAPbouiCOM.BoFormItemTypes.it_EDIT);
                item.Left = 9;
                item.Top = 40;
                item.Width = 150;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
        private void InicializarModalReprogramacion()
        {
            try
            {
                for (int i = 0; i < ClsMain.oApplication.Forms.Count; i++)
                {
                    Form frm = ClsMain.oApplication.Forms.Item(i);
                    if (frm.Modal && frm.TypeEx == "0")
                    {
                        StaticText st = (StaticText)frm.Items.Item("7").Specific;
                        if (st.Caption == "Reprogramacion")
                        {
                            formReprogramacion = frm;
                            FormID = frm.UniqueID;
                        }
                    }
                }
                formReprogramacion.Title = "Reprogramacion";
                formReprogramacion.ClientWidth = 190;
                formReprogramacion.ClientHeight = 120;
                formReprogramacion.Left = (ClsMain.oApplication.Desktop.Width - formReprogramacion.Width) / 2;
                formReprogramacion.Top = (ClsMain.oApplication.Desktop.Height - formReprogramacion.Height) / 2 - 100;
                formReprogramacion.Items.Item("11").Visible = false;
                formReprogramacion.Items.Item("7").Visible = false;

                IItem oItm;
                StaticText oLbl;
                EditText oTxt;

                oItm = formReprogramacion.Items.Add("lblLinea", SAPbouiCOM.BoFormItemTypes.it_STATIC);
                oItm.Left = 9;
                oItm.Top = 12;
                oItm.Width = 60;
                oLbl = (StaticText)oItm.Specific;
                oLbl.Caption = "# de Linea";

                formReprogramacion.DataSources.UserDataSources.Add("UD_POSRP", BoDataType.dt_SHORT_NUMBER, 3);
                oItm = formReprogramacion.Items.Add("txtPos", SAPbouiCOM.BoFormItemTypes.it_EDIT);
                oItm.Left = oLbl.Item.Left + oLbl.Item.Width + 8;
                oItm.Top = oLbl.Item.Top;
                oItm.Width = 100;
                oTxt = (EditText)oItm.Specific;
                oTxt.DataBind.SetBound(true, "", "UD_POSRP");

                oItm = formReprogramacion.Items.Add("lblFecha", SAPbouiCOM.BoFormItemTypes.it_STATIC);
                oItm.Left = oLbl.Item.Left;
                oItm.Top = oLbl.Item.Top + oLbl.Item.Height + 8;
                oItm.Width = oLbl.Item.Width;
                oLbl = (StaticText)oItm.Specific;
                oLbl.Caption = "Fecha Inicio";

                formReprogramacion.DataSources.UserDataSources.Add("UD_FECRP", BoDataType.dt_DATE);
                oItm = formReprogramacion.Items.Add("txtFecha", SAPbouiCOM.BoFormItemTypes.it_EDIT);
                oItm.Left = oTxt.Item.Left;
                oItm.Top = oLbl.Item.Top;
                oItm.Width = oTxt.Item.Width;
                oTxt = (EditText)oItm.Specific;
                oTxt.DataBind.SetBound(true, "", "UD_FECRP");
                formReprogramacion.DataSources.UserDataSources.Item("UD_FECRP").Value = FechaReprog.ToString("yyyyMMdd");

                oItm = formReprogramacion.Items.Add("lblHora", SAPbouiCOM.BoFormItemTypes.it_STATIC);
                oItm.Left = oLbl.Item.Left;
                oItm.Top = oLbl.Item.Top + oLbl.Item.Height + 8;
                oItm.Width = oLbl.Item.Width;
                oLbl = (StaticText)oItm.Specific;
                oLbl.Caption = "Hora Inicio";

                formReprogramacion.DataSources.UserDataSources.Add("UD_HORRP", BoDataType.dt_SHORT_TEXT, 5);//CORREGIR
                oItm = formReprogramacion.Items.Add("txtHora", SAPbouiCOM.BoFormItemTypes.it_EDIT);
                oItm.Left = oTxt.Item.Left;
                oItm.Top = oLbl.Item.Top;
                oItm.Width = oTxt.Item.Width;
                oTxt = (EditText)oItm.Specific;
                oTxt.DataBind.SetBound(true, "", "UD_HORRP");
                formReprogramacion.DataSources.UserDataSources.Item("UD_HORRP").Value = HoraReprog;//CORREGIR

                oItm = formReprogramacion.Items.Item("1").Specific.Caption = "Reprogramar";
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }

        private void DoActionCambioUbicacion(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
                            if (!pVal.BeforeAction)
                            {
                                InicializarModalCambioUbicacion();
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_ITEM_PRESSED:
                            switch (pVal.ItemUID)
                            {
                                case "1":
                                    if (pVal.BeforeAction && FormUID == FormID)
                                    {
                                        UbicacionIngresada = ((EditText)formModal.Items.Item("txtPos").Specific).String;
                                    }
                                    break;
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
                            if (!pVal.BeforeAction && FormUID == FormID)
                            {
                                Cerrar();
                            }
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
        private void DoActionCambioTiempo(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
                            if (!pVal.BeforeAction)
                            {
                                InicializarModalCambioTiempo();

                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_ITEM_PRESSED:
                            switch (pVal.ItemUID)
                            {
                                case "1":
                                    if (pVal.BeforeAction && FormUID == FormID)
                                    {
                                        NewVelocidad = ((EditText)formModal.Items.Item("txtPos").Specific).String;
                                    }
                                    break;
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
                            if (!pVal.BeforeAction && FormUID == FormID)
                            {
                                Cerrar();
                            }
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
        //private void DoActionCambioMaquina(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        //{
        //    BubbleEvent = true;
        //    try
        //    {
        //        if (pVal.FormTypeEx == "0")
        //        {
        //            switch (pVal.EventType)
        //            {
        //                case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
        //                    if (!pVal.BeforeAction)
        //                    {
        //                        InicializarModalCambioMaquina();
        //                    }
        //                    break;
        //                case SAPbouiCOM.BoEventTypes.et_ITEM_PRESSED:
        //                    switch (pVal.ItemUID)
        //                    {
        //                        case "btnCambiar":
        //                            if (pVal.BeforeAction && FormUID == FormID)
        //                            {
        //                                NewMaquinaCode = formModal.DataSources.UserDataSources.Item("Maquina").Value.ToString();
        //                                NewMaquinaDesc = NewMaquinaCode = formModal.DataSources.UserDataSources.Item("Descripcion").Value.ToString();
        //                            }
        //                            break;
        //                    }
        //                    break;
        //                case SAPbouiCOM.BoEventTypes.et_CHOOSE_FROM_LIST:
        //                    if (!pVal.BeforeAction)
        //                    {
        //                        switch (pVal.ItemUID)
        //                        {
        //                            case "txtOrden":
        //                                cflOrderEntry(ref pVal);
        //                                break;

        //                            //RECURSO
        //                            case "Item_0":
        //                                cflRecurso(ref pVal);
        //                                break;
        //                        }
        //                    }
        //                    break;
        //                case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
        //                    if (!pVal.BeforeAction && FormUID == FormID)
        //                    {
        //                        Cerrar();
        //                    }
        //                    break;
        //            }
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        logger.Error(ex.Message, ex);
        //    }
        //}

        private void DoActionProgramar(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
                            if (!pVal.BeforeAction)
                            {
                                InicializarModalProgramar();
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_ITEM_PRESSED:
                            switch (pVal.ItemUID)
                            {
                                case "1":
                                    if (pVal.BeforeAction && FormUID == FormID)
                                    {
                                        UbicacionIngresada = ((EditText)formModal.Items.Item("txtPos").Specific).String;
                                    }
                                    break;
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
                            if (!pVal.BeforeAction && FormUID == FormID)
                            {
                                Cerrar();
                            }
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }

        private void DoActionAnulacion(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
                            if (!pVal.BeforeAction)
                            {
                                InicializarModalYesNo("Anulación", "¿Desea anular la orden de fabricación - " + OrdSeleccionada + "?");
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
                            if (!pVal.BeforeAction && FormUID == FormID)
                            {
                                Cerrar();
                            }
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
        private void DoActionStandBy(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
                            if (!pVal.BeforeAction)
                            {
                                InicializarModalYesNo("StandBy", "¿Desea enviar a StandBy?");
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
                            if (!pVal.BeforeAction && FormUID == FormID)
                            {
                                Cerrar();
                            }
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
        private void DoActionParcial(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
                            if (!pVal.BeforeAction)
                            {
                                InicializarModalYesNo("Parcial", "¿Desea detener parcialmente el proceso OF-" + OrdSeleccionada + "?");
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
                            if (!pVal.BeforeAction && FormUID == FormID)
                            {
                                Cerrar();
                            }
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
        private void DoActionTerminar(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
                            if (!pVal.BeforeAction)
                            {
                                InicializarModalYesNo("Terminado", "¿Desea terminar la orden de fabricación - " + OrdSeleccionada + "?");
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
                            if (!pVal.BeforeAction && FormUID == FormID)
                            {
                                Cerrar();
                            }
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
        private void DoActionReprogramar(string FormUID, ref SAPbouiCOM.ItemEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                if (pVal.FormTypeEx == "0")
                {
                    switch (pVal.EventType)
                    {
                        case SAPbouiCOM.BoEventTypes.et_FORM_LOAD:
                            if (!pVal.BeforeAction)
                            {
                                InicializarModalReprogramacion();
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_ITEM_PRESSED:
                            switch (pVal.ItemUID)
                            {
                                case "1":
                                    if (pVal.BeforeAction && FormUID == FormID)
                                    {
                                        UbicacionIngresada = ((EditText)formReprogramacion.Items.Item("txtPos").Specific).String;
                                        HoraReprog = ((EditText)formReprogramacion.Items.Item("txtHora").Specific).String;
                                        FechaReprog = DateTime.ParseExact(((EditText)formReprogramacion.Items.Item("txtFecha").Specific).String, "dd/MM/yyyy", null);
                                    }
                                    break;
                            }
                            break;
                        case SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD:
                            if (!pVal.BeforeAction && FormUID == FormID)
                            {
                                Cerrar();
                            }
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }

        private void Cerrar()
        {
            ClsMain.oApplication.ItemEvent -= itemEventHandler;
        }

        private bool ValidarOpcion(string opcion)
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

        public void FillMaquina(string maqCode, string maqDescrp, List<OrdenFabricacion> list)
        {
            Programador.OrdenesFabricacion = list;
            NewMaquinaCode = maqCode;
            NewMaquinaDesc = maqDescrp;
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            BuscarSelecciones(ref oMatOrdenes, out int seleccionados);
            UbicacionIngresada = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(oMatOrdenes.GetNextSelectedRow()).Specific.Value;

            if (!string.IsNullOrEmpty(NewMaquinaCode))
            {
                CambiarMaquinaSeleccionado(ref oMatOrdenes);
            }
            else
            {
                ClsMain.MensajeWarning("No ingresó cambio de maquina");
            }
        }

        public void MostrarOrdenes()
        {
            oForm.Freeze(true);
            try
            {
                string fechaIni, fechaFin, order, orderentry, visual, recurso, razonsocial;

                fechaIni = oForm.DataSources.UserDataSources.Item("uFdesde").Value;
                fechaFin = oForm.DataSources.UserDataSources.Item("uFhasta").Value;
                order = oForm.DataSources.UserDataSources.Item("uOrden").Value;
                orderentry = oForm.DataSources.UserDataSources.Item("uFOrden").Value;
                visual = oForm.DataSources.UserDataSources.Item("uVisual").Value;
                recurso = oForm.DataSources.UserDataSources.Item("UD_RECCOD").Value;
                razonsocial = oForm.DataSources.UserDataSources.Item("UD_RAZSOC").Value;

                if (string.IsNullOrEmpty(orderentry))
                {
                    orderentry = "0";
                }
                switch (visual)
                {
                    case "ALL":
                        visual = "*";
                        break;
                    case "PRG":
                        visual = "Y";
                        break;
                    case "NPR":
                        visual = "N";
                        break;
                }

                if (!ValidarParametros(fechaIni, fechaFin, recurso))
                {
                    return;
                }
                fechaIni = ((EditText)oForm.Items.Item("txtFdesde").Specific).Value;
                fechaFin = ((EditText)oForm.Items.Item("txtFhasta").Specific).Value;
                string query = Queries.ListaOrdenesProgramacion(ClsMain.oCompany.DbServerType, fechaIni, fechaFin, order, orderentry, visual, recurso, razonsocial);
                logger.Debug(query);
                oForm.DataSources.DataTables.Item("dtOrders").ExecuteQuery(query);
                //oForm.DataSources.DataTables.Item("dtGridOrder").ExecuteQuery(query);
                oForm.DataSources.UserDataSources.Item("uSelect").Value = string.Empty;

                ProcesarMatrix();

                Programador.FiltroPorRecurso = !string.IsNullOrEmpty(recurso); //SERVIRÁ PARA HACER LAS VALIDACIONES CONTRA LA BD CUANDO HA FILTRADO POR RECURSO
                Programador.CargarOrdenes(query);  //CARGAMOS EN MEMORIA LAS ORDENES LISTADAS
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }

        bool ValidarParametros(string fechaIni, string fechaFin, string recurso)
        {
            if (string.IsNullOrEmpty(fechaIni))
            {
                ClsMain.MensajeError("Debe ingresar la fecha inicial", true);
                return false;
            }
            if (string.IsNullOrEmpty(fechaFin))
            {
                ClsMain.MensajeError("Debe ingresar la fecha final", true);
                return false;
            }
            if (string.IsNullOrEmpty(recurso))
            {
                ClsMain.MensajeError("Debe ingresar el recurso a programar", true);
                return false;
            }
            return true;
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
            if (oDTorders.Columns.Count > 29)
            {
                for (int i = 29; i < oDTorders.Columns.Count; i++)
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
            for (int i = 24; i < colcount; i++)
            {
                oMatOrdenes.Columns.Remove(24);
            }
        }

        string NombreCol(string colname)
        {
            string ncol = colname.Replace(" ", "").ToLower();
            if (ncol.Length > 10) ncol = ncol.Substring(0, 10);
            return ncol;
        }



        private void PrevisualizarPorSeleccion()
        {
            try
            {
                Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                string sFechaProgr = oForm.Items.Item("txtFProg").Specific.Value;
                string horaInicio = oForm.Items.Item("Item_11").Specific.String;

                if (!string.IsNullOrEmpty(sFechaProgr) && !string.IsNullOrEmpty(horaInicio))
                {
                    DateTime fechaInicioProg = DateTime.ParseExact(sFechaProgr, "yyyyMMdd", null);
                    oForm.Freeze(true);

                    if (Programador.OrdenesFabricacion.Where(x => x.Seleccionado).ToList().Count > 0)
                    {
                        ClsMain.oApplication.StatusBar.SetText("Programando ordenes, espere por favor...", BoMessageTime.bmt_Medium, BoStatusBarMessageType.smt_Warning);
                        Programador.ProgramarOrdenes(fechaInicioProg, horaInicio);

                        List<OrdenFabricacion> seleccionados = Programador.OrdenesFabricacion.Where(x => x.Seleccionado).ToList();

                        foreach (OrdenFabricacion of in seleccionados)
                        {
                            oMatOrdenes.Columns.Item("ProgDate").Cells.Item(of.IndiceEnMatrix).Specific.Value = of.DtFechaInicio.ToString("yyyyMMdd");
                            oMatOrdenes.Columns.Item("StartTime").Cells.Item(of.IndiceEnMatrix).Specific.Value = of.DtFechaInicio.ToString("HH:mm");
                            oMatOrdenes.Columns.Item("Col_0").Cells.Item(of.IndiceEnMatrix).Specific.Value = of.DtFechaFin.ToString("yyyyMMdd");
                            oMatOrdenes.Columns.Item("FinishTime").Cells.Item(of.IndiceEnMatrix).Specific.Value = of.DtFechaFin.ToString("HH:mm");
                        }

                        oMatOrdenes.AutoResizeColumns();
                        ClsMain.oApplication.StatusBar.SetText("Ordenes planificadas exitosamente", BoMessageTime.bmt_Short, BoStatusBarMessageType.smt_Success);
                    }
                    else
                    {
                        throw new Exception("Debe seleccionar al menos una recurso para programar");
                    }
                }
                else
                {
                    throw new Exception("Debe ingresar una fecha y hora de inicio de programación");
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }

        private void ReprogramarSeleccion(ref Matrix oMatOrdenes)
        {
            try
            {
                oForm.Freeze(true);
                if (Programador.OrdenesFabricacion.Where(x => x.Seleccionado).ToList().Count > 0)
                {
                    ClsMain.oApplication.StatusBar.SetText("Reprogramando ordenes, espere por favor...", BoMessageTime.bmt_Medium, BoStatusBarMessageType.smt_Warning);
                    ProgramarSeleccionado(ref oMatOrdenes);
                    //Reprogramador(ref oMatOrdenes);
                    ClsMain.oApplication.StatusBar.SetText("Ordenes reprogramadas exitosamente", BoMessageTime.bmt_Short, BoStatusBarMessageType.smt_Success);
                }
                else
                {
                    throw new Exception("Debe seleccionar al menos una recurso para programar");
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }

        private void Reprogramador(ref Matrix oMatOrdenes)
        {
            Programador.ProgramarOrdenes(FechaReprog, HoraReprog, int.Parse(UbicacionIngresada));

            List<OrdenFabricacion> seleccionados = Programador.OrdenesFabricacion.Where(x => x.Seleccionado).ToList();

            foreach (OrdenFabricacion of in seleccionados)
            {
                oMatOrdenes.Columns.Item("ProgDate").Cells.Item(of.IndiceEnMatrix).Specific.Value = of.DtFechaInicio.ToString("yyyyMMdd");
                oMatOrdenes.Columns.Item("StartTime").Cells.Item(of.IndiceEnMatrix).Specific.Value = of.DtFechaInicio.ToString("HH:mm");
                oMatOrdenes.Columns.Item("Col_0").Cells.Item(of.IndiceEnMatrix).Specific.Value = of.DtFechaFin.ToString("yyyyMMdd");
                oMatOrdenes.Columns.Item("FinishTime").Cells.Item(of.IndiceEnMatrix).Specific.Value = of.DtFechaFin.ToString("HH:mm");
            }

            oMatOrdenes.AutoResizeColumns();

        }
        private void ProgramarSeleccionado(ref Matrix oMatOrdenes)
        {
            oForm.Freeze(true);
            try
            {
                if (int.TryParse(UbicacionIngresada, out int ubicacionNueva))
                {
                    if (ubicacionNueva > selecciones.Count)
                    {
                        ClsMain.MensajeError("La ubicación ingresada debe ser menor o igual a la cantidad de registros marcados");
                    }
                    else
                    {
                        int lineaseleccionada = oMatOrdenes.GetNextSelectedRow();
                        int actual = selecciones[lineaseleccionada];
                        var sorted = selecciones.OrderBy(x => x.Value);
                        Dictionary<int, int> nuevaseleccion = new Dictionary<int, int>();

                        bool disminuir = false;
                        bool isLast = ubicacionNueva == selecciones.Count;

                        var RefRegister = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada) + (isLast ? -1 : 0)).FirstOrDefault();
                        if(RefRegister == null)
                        {
                            RefRegister = new OrdenFabricacion();

                            RefRegister.FechaInicio= ((EditText)oForm.Items.Item("txtFProg").Specific).Value;
                            RefRegister.FechaFin = ((EditText)oForm.Items.Item("txtFProg").Specific).Value;
                            RefRegister.HoraInicio = ((EditText)oForm.Items.Item("Item_11").Specific).Value;
                            RefRegister.HoraFin = ((EditText)oForm.Items.Item("Item_11").Specific).Value;

                            string timeString = RefRegister.HoraInicio;
                            string timeFormatted = timeString.Insert(2, ":");
                            RefRegister.HoraInicio = timeFormatted;
                            timeString = RefRegister.HoraFin;
                            timeFormatted = timeString.Insert(2, ":");
                            RefRegister.HoraFin = timeFormatted;

                        }

                        if (FechaReprog == DateTime.MinValue) FechaReprog = DateTime.ParseExact((isLast ? RefRegister.FechaFin : RefRegister.FechaInicio), "yyyyMMdd", null);
                        if (string.IsNullOrEmpty(HoraReprog)) HoraReprog = (isLast ? RefRegister.HoraFin : RefRegister.HoraInicio);
                        nuevaseleccion.Add(lineaseleccionada, ubicacionNueva);
                        if (ubicacionNueva < actual)
                        {
                            disminuir = true;
                            foreach (KeyValuePair<int, int> seleccionado in sorted)
                            {
                                if (seleccionado.Value < ubicacionNueva) continue;
                                if (seleccionado.Value < actual)
                                {
                                    nuevaseleccion.Add(seleccionado.Key, seleccionado.Value + 1);
                                }
                                else if (seleccionado.Value != actual)
                                {
                                    nuevaseleccion.Add(seleccionado.Key, seleccionado.Value);
                                }
                            }
                        }
                        else
                        {
                            foreach (KeyValuePair<int, int> seleccionado in sorted)
                            {
                                if (seleccionado.Value > actual)
                                {
                                    nuevaseleccion.Add(seleccionado.Key, seleccionado.Value - 1);
                                }
                                else if (seleccionado.Value != actual)
                                {
                                    //continue;
                                    nuevaseleccion.Add(seleccionado.Key, seleccionado.Value);
                                }
                            }
                        }
                        valid = false;
                        sorted = nuevaseleccion.OrderBy(x => x.Value);
                        QuitarCheck(ref oMatOrdenes, nuevaseleccion);
                        System.Threading.Thread.Sleep(500);
                        foreach (KeyValuePair<int, int> seleccionado in sorted)
                        {

                            CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(seleccionado.Key).Specific;
                            oCheck.Checked = true;
                            ComboBox oCombo = oMatOrdenes.Columns.Item("Scheduled").Cells.Item(seleccionado.Key).Specific;
                            string Pro = oMatOrdenes.Columns.Item("Scheduled").Cells.Item(seleccionado.Key).Specific.value;

                            oCombo.Select("Y", BoSearchKey.psk_ByValue);

                            if (disminuir && seleccionado.Value < ubicacionNueva) continue;
                            if (!disminuir && seleccionado.Value > ubicacionNueva) continue;
                            AccionClickEnCheck(seleccionado.Key);

                            //cambio lushianna si estuvo funcionando pero ahora los valors se alteran
                            oCombo.Select(Pro, BoSearchKey.psk_ByValue);

                        }
                        valid = true;
                        Reprogramador(ref oMatOrdenes);
                    }
                }
                else
                {
                    ClsMain.MensajeError("La ubicación ingresada debe ser numérica");
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
            finally
            {
                oForm.Freeze(false);
            }
        }

        private void StandBySeleccionado(ref Matrix oMatOrdenes)//TODO
        {
            oForm.Freeze(true);
            try
            {
                DesasignarRegistro(ref oMatOrdenes, standBy: true);

            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }
        private void CambiarMaquinaSeleccionado(ref Matrix oMatOrdenes)//TODO
        {
            oForm.Freeze(true);

            try
            {
                for (int selected = oMatOrdenes.RowCount; selected >= 1; selected--)
                {
                    if (oMatOrdenes.IsRowSelected(selected))
                    {

                  
                        if (oMatOrdenes.Columns.Item("Scheduled").Cells.Item(selected).Specific.Value == "Y")
                        {

                            UbicacionIngresada = oMatOrdenes.Columns.Item("SelOrder").Cells.Item(selected).Specific.Value;

                            int.TryParse(UbicacionIngresada, out int ubicacionNueva);
                            if (ubicacionNueva > selecciones.Count)
                            {
                                ClsMain.MensajeError("La ubicación ingresada debe ser menor o igual a la cantidad de registros marcados");
                            }
                            else
                            {
                                valid = false;

                                int lineaseleccionada = Convert.ToInt32(selected);
                                int actual = selecciones[lineaseleccionada];
                                var sorted = selecciones.OrderBy(x => x.Value);
                                Dictionary<int, int> nuevaseleccion = new Dictionary<int, int>();
                                bool disminuir = false;
                                //bool isLast = ubicacionNueva == selecciones.Count;
                                //bool isFirst = ubicacionNueva == 1;
                                var RefRegister = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada)).FirstOrDefault();
                                FechaReprog = DateTime.ParseExact(RefRegister.FechaInicio, "yyyyMMdd", null);
                                HoraReprog = RefRegister.HoraInicio;

                                oMatOrdenes.Columns.Item("check").Cells.Item(lineaseleccionada).Specific.Checked = false;
                                oMatOrdenes.Columns.Item("Scheduled").Cells.Item(lineaseleccionada).Specific.Select("N", BoSearchKey.psk_ByValue);
                                oMatOrdenes.Columns.Item("ProgDate").Cells.Item(lineaseleccionada).Specific.Value = string.Empty;
                                oMatOrdenes.Columns.Item("Col_0").Cells.Item(lineaseleccionada).Specific.Value = string.Empty;
                                oMatOrdenes.Columns.Item("StartTime").Cells.Item(lineaseleccionada).Specific.Value = "00:00";
                                oMatOrdenes.Columns.Item("FinishTime").Cells.Item(lineaseleccionada).Specific.Value = "00:00";
                                oMatOrdenes.Columns.Item("Col_1").Cells.Item(selected).Specific.Value = NewMaquinaCode;
                                oMatOrdenes.Columns.Item("Resource").Cells.Item(selected).Specific.Value = NewMaquinaDesc;
                                //AccionClickEnCheck(lineaseleccionada);
                                Programador.ClearProgramadorVal(lineaseleccionada);
                                Programador.ChangeProgramadorVal(selected, NewMaquinaCode);

                                foreach (KeyValuePair<int, int> seleccionado in sorted)
                                {
                                    if (seleccionado.Value > actual)
                                    {
                                        nuevaseleccion.Add(seleccionado.Key, seleccionado.Value - 1);
                                    }

                                }
                                //}
                                valid = true;
                                Reprogramador(ref oMatOrdenes);
                            }
                        }
                        else
                        {
                            Programador.ClearProgramadorVal(selected);
                            Programador.ChangeProgramadorVal(selected, NewMaquinaCode);
                        }
                    }
                }
                MostrarOrdenes();
                //int lineaseleccionada = oMatOrdenes.GetNextSelectedRow();




            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }

        private void CambiarVelocidadSeleccionado(ref Matrix oMatOrdenes)//TODO
        {
            oForm.Freeze(true);

            try
            {
                int lineaseleccionada = oMatOrdenes.GetNextSelectedRow();
                var CalculoTiempo = CalculateTime();
                oMatOrdenes.Columns.Item("Hours").Cells.Item(lineaseleccionada).Specific.Value = CalculoTiempo.Item2;
                Programador.ChangeProgramadorVal(lineaseleccionada, newTime: CalculoTiempo.Item2, cantPlaneada: CalculoTiempo.Item1);
                if (oMatOrdenes.Columns.Item("Scheduled").Cells.Item(lineaseleccionada).Specific.Value == "Y")
                {
                    var RefRegister = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada)).FirstOrDefault();
                    FechaReprog = DateTime.ParseExact(RefRegister.FechaInicio, "yyyyMMdd", null);
                    HoraReprog = RefRegister.HoraInicio;
                    Reprogramador(ref oMatOrdenes);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }

        private Tuple<double, string> CalculateTime()
        {
            try
            {
                string cantdHoras = "00:00:00";
                double cantRequerida = 0;

                string cantidadHActual = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada)).Select(x => x.CantidadHoras).FirstOrDefault();
                var cantidadHoras = TimeSpan.ParseExact(cantidadHActual, "hh\\:mm\\:ss", null).TotalSeconds;
                var newCantidadHoras = double.Parse(velocidadMaquina) * cantidadHoras / double.Parse(NewVelocidad);

                cantRequerida = Math.Round(newCantidadHoras / double.Parse(velocidadMaquina), 2);
                cantdHoras = TimeSpan.FromSeconds(newCantidadHoras).ToString(@"hh\:mm\:ss");

                return Tuple.Create(cantRequerida, cantdHoras);
            }
            catch (Exception)
            {

                throw;
            }

        }
        private void DesasignarRegistro(ref Matrix oMatOrdenes, bool standBy = false, bool parcial = false, bool terminado = false, bool otro = false)
        {
            int.TryParse(UbicacionIngresada, out int ubicacionNueva);
            if (ubicacionNueva > selecciones.Count)
            {
                ClsMain.MensajeError("La ubicación ingresada debe ser menor o igual a la cantidad de registros marcados");
            }
            else
            {
                int lineaseleccionada = oMatOrdenes.GetNextSelectedRow();
                int actual = selecciones[lineaseleccionada];
                var sorted = selecciones.OrderBy(x => x.Value);
                Dictionary<int, int> nuevaseleccion = new Dictionary<int, int>();
                bool disminuir = false;
                //bool isLast = ubicacionNueva == selecciones.Count;
                //bool isFirst = ubicacionNueva == 1;
                var RefRegister = Programador.OrdenesFabricacion.Where(x => x.OrdenMarcacion == int.Parse(UbicacionIngresada)).FirstOrDefault();
                
                FechaReprog = DateTime.ParseExact(RefRegister.FechaInicio, "yyyyMMdd", null);
                HoraReprog = RefRegister.HoraInicio;
                
                oMatOrdenes.Columns.Item("check").Cells.Item(lineaseleccionada).Specific.Checked = false;
                oMatOrdenes.Columns.Item("Scheduled").Cells.Item(lineaseleccionada).Specific.Select("N", BoSearchKey.psk_ByValue);
                oMatOrdenes.Columns.Item("ProgDate").Cells.Item(lineaseleccionada).Specific.Value = string.Empty;
                //oMatOrdenes.Columns.Item("programdat").Cells.Item(lineaseleccionada).Specific.Value = string.Empty;
                oMatOrdenes.Columns.Item("Col_0").Cells.Item(lineaseleccionada).Specific.Value = string.Empty;
                oMatOrdenes.Columns.Item("StartTime").Cells.Item(lineaseleccionada).Specific.Value = "00:00";
                oMatOrdenes.Columns.Item("FinishTime").Cells.Item(lineaseleccionada).Specific.Value = "00:00";
                if (standBy) oMatOrdenes.Columns.Item("standby").Cells.Item(lineaseleccionada).Specific.Value = "Y";//Important
                if (parcial) oMatOrdenes.Columns.Item("parcial").Cells.Item(lineaseleccionada).Specific.Value = "Y";//Important
                if (terminado) oMatOrdenes.Columns.Item("terminado").Cells.Item(lineaseleccionada).Specific.Value = "Y";//Important
                if (otro) oMatOrdenes.Columns.Item("anulado").Cells.Item(lineaseleccionada).Specific.Value = "Y";//Important

                AccionClickEnCheck(lineaseleccionada);

                Programador.ClearProgramadorVal(lineaseleccionada, standBy, parcial, terminado, otro);

                if (ubicacionNueva < actual)
                {
                    disminuir = true;
                    foreach (KeyValuePair<int, int> seleccionado in sorted)
                    {
                        if (seleccionado.Value < ubicacionNueva) continue;
                        if (seleccionado.Value < actual)
                        {
                            nuevaseleccion.Add(seleccionado.Key, seleccionado.Value + 1);
                        }
                        else if (seleccionado.Value != actual)
                        {
                            nuevaseleccion.Add(seleccionado.Key, seleccionado.Value);
                        }
                    }
                }
                else
                {
                    foreach (KeyValuePair<int, int> seleccionado in sorted)
                    {
                        if (seleccionado.Value > actual)
                        {
                            nuevaseleccion.Add(seleccionado.Key, seleccionado.Value - 1);
                        }
                        else if (seleccionado.Value != actual)
                        {
                            //continue;
                            nuevaseleccion.Add(seleccionado.Key, seleccionado.Value);
                        }
                    }
                }
                valid=false;
                sorted = nuevaseleccion.OrderBy(x => x.Value);
                QuitarCheck(ref oMatOrdenes, nuevaseleccion);
                System.Threading.Thread.Sleep(500);
                foreach (KeyValuePair<int, int> seleccionado in sorted)
                {
                    oMatOrdenes.Columns.Item("check").Cells.Item(seleccionado.Key).Specific.Checked = true;
                    oMatOrdenes.Columns.Item("Scheduled").Cells.Item(seleccionado.Key).Specific.Select("Y", BoSearchKey.psk_ByValue);
                    if (disminuir && seleccionado.Value < ubicacionNueva) continue;
                    if (!disminuir && seleccionado.Value > ubicacionNueva) continue;
                    AccionClickEnCheck(seleccionado.Key);
                }
                Reprogramador(ref oMatOrdenes);
                valid = true;

            }
        }


        private void ParcialSeleccionado(ref Matrix oMatOrdenes)//TODO
        {

            oForm.Freeze(true);
            try
            {
                DesasignarRegistro(ref oMatOrdenes, parcial: true);
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }
        private void TerminarSeleccionado(ref Matrix oMatOrdenes)//TODO
        {
            try
            {
                oForm.Freeze(true);
                int lineaseleccionada = oMatOrdenes.GetNextSelectedRow();
                if (oMatOrdenes.Columns.Item("Scheduled").Cells.Item(lineaseleccionada).Specific.Value == "Y")
                {
                    DesasignarRegistro(ref oMatOrdenes, terminado: true);
                }
                else
                {
                    oMatOrdenes.Columns.Item("terminado").Cells.Item(lineaseleccionada).Specific.Value = "Y";
                    Programador.ChangeProgramadorVal(lineaseleccionada, terminar: true);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }
        private void AnularSeleccionado(ref Matrix oMatOrdenes)//TODO
        {
            try
            {
                oForm.Freeze(true);
                int lineaseleccionada = oMatOrdenes.GetNextSelectedRow();
                Programador.ChangeProgramadorVal(lineaseleccionada, anular: true);
                if (oMatOrdenes.Columns.Item("Scheduled").Cells.Item(lineaseleccionada).Specific.Value == "Y")
                {
                    DesasignarRegistro(ref oMatOrdenes, otro: true);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                oForm.Freeze(false);
            }
        }
        private void ProcesarOrdenes()
        {
            int rpta = ClsMain.oApplication.MessageBox("Se procesarán las órdenes, una vez realizado no se puede revertir, ¿Desea continuar?", 1, "Si", "No", "");
            if (rpta != 1) return;
            oForm.Freeze(true);
            try
            {
                int procesados = 0;
                List<string> Errores = new List<string>();
                string tipo = "2";
                switch (tipo)
                {
                    case "1":
                        //ProcesarPorFecha(out procesados, out Errores);
                        break;
                    case "2":
                        ProcesarPorSeleccion(out procesados, out Errores);
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
                ClsMain.MensajeError(ex.Message);
            }
            oForm.Freeze(false);
        }

        private void ProcesarPorSeleccion(out int procesados, out List<string> Errores)
        {
            procesados = 0;
            Errores = new List<string>();

            Programador.ProcesarProgramacion(out procesados, out Errores);
        }

        private void Limpiar()
        {
            Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
            if (oMatOrdenes.RowCount == 0)
            {
                ClsMain.MensajeError("No hay registros en la lista");
                return;
            }

            string validacionEtapas = oForm.DataSources.UserDataSources.Item("uValidar").Value;
            string msg = validacionEtapas == "Y" ? "Se limpiará la programación de las órdenes, si tienen etapas posteriores programadas también se borrarán, una vez realizado no se puede revertir, ¿Desea continuar?" : "Está a punto de borrar las programaciones seleccionadas sin validación de etapas. ¿Desea continuar?";

            int rpta = ClsMain.oApplication.MessageBox(msg, 1, "Si", "No", "");
            if (rpta != 1) return;

            for (int i = 1; i <= oMatOrdenes.RowCount; i++)
            {
                CheckBox line = oMatOrdenes.Columns.Item("check").Cells.Item(i).Specific;

                if (line.Checked)
                {
                    Programador.OrdenesFabricacion.Where(t => t.IndiceEnMatrix == i).FirstOrDefault().Seleccionado = true;
                }
                else
                {
                    Programador.OrdenesFabricacion.Where(t => t.IndiceEnMatrix == i).FirstOrDefault().Seleccionado = false;
                }
            }

            Programador.LimpiarProgramaciones(out int procesados, out List<string> Errores, validacionEtapas == "Y");


            if (Errores.Count == 0)
                ClsMain.MensajeSuccess("Limpiados todos los recursos con éxito");
            else
                ClsMain.MensajeError("Se encontraron los siguientes errores: \n" + string.Join("\n", Errores));

            MostrarOrdenes();
        }


        private void AccionClickEnCheck2(int fila)
        {
            try
            {
                oForm.Freeze(true);
                Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(fila).Specific;

                int orden = Convert.ToInt32(oMatOrdenes.Columns.Item("Col_2").Cells.Item(fila).Specific.Value);
                string recurso = oMatOrdenes.Columns.Item("Col_1").Cells.Item(fila).Specific.Value;
                int etapa = Convert.ToInt32(oMatOrdenes.Columns.Item("StageId").Cells.Item(fila).Specific.Value);
                string programadoSel = oMatOrdenes.Columns.Item("Scheduled").Cells.Item(fila).Specific.Value;

                Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().Seleccionado = oCheck.Checked;

                //int ordenSeleccion = oCheck.Checked ? Programador.OrdenesFabricacion.Where(x => x.Seleccionado).ToList().Count : 0;

                int programados = Programador.OrdenesFabricacion.Count(x => x.Programado);
                int list = Programador.OrdenesFabricacion.Where(x => x.Seleccionado && x.Programado == false).ToList().Count;
                int ordenSeleccion = oCheck.Checked ? list + programados : 0;
                if (programadoSel == "N")
                    Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().OrdenMarcacion = ordenSeleccion;

                //actualización
                if (oCheck.Checked)
                {
                    if (programadoSel == "N")
                        oMatOrdenes.Columns.Item("SelOrder").Cells.Item(fila).Specific.Value = ordenSeleccion.ToString();
                    oMatOrdenes.SelectRow(fila, true, true);

                }
                else
                {
                    if (!Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().ProgramadoEnSAP)
                    {
                        Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().Programado = false;
                        oMatOrdenes.Columns.Item("ProgDate").Cells.Item(fila).Specific.Value = string.Empty;
                        oMatOrdenes.Columns.Item("Col_0").Cells.Item(fila).Specific.Value = string.Empty;
                        oMatOrdenes.Columns.Item("StartTime").Cells.Item(fila).Specific.Value = "00:00";
                        oMatOrdenes.Columns.Item("FinishTime").Cells.Item(fila).Specific.Value = "00:00";
                    }

                    int ordenDesmarcado = Convert.ToInt32(oMatOrdenes.Columns.Item("SelOrder").Cells.Item(fila).Specific.Value);


                    if (programadoSel == "N")
                    {
                        ActualizarOrden(ref oMatOrdenes, ordenDesmarcado);
                        oMatOrdenes.Columns.Item("SelOrder").Cells.Item(fila).Specific.Value = ordenSeleccion.ToString();
                    }

                    oMatOrdenes.SelectRow(fila, false, true);
                }

            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
            finally { oForm.Freeze(false); }
        }


        private void AccionClickEnCheck(int fila)
        {
            try
            {
                oForm.Freeze(true);
                Matrix oMatOrdenes = oForm.Items.Item("matOrders").Specific;
                CheckBox oCheck = oMatOrdenes.Columns.Item("check").Cells.Item(fila).Specific;

                int orden = Convert.ToInt32(oMatOrdenes.Columns.Item("Col_2").Cells.Item(fila).Specific.Value);
                string recurso = oMatOrdenes.Columns.Item("Col_1").Cells.Item(fila).Specific.Value;
                int etapa = Convert.ToInt32(oMatOrdenes.Columns.Item("StageId").Cells.Item(fila).Specific.Value);

                Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().Seleccionado = oCheck.Checked;
                int ordenSeleccion = oCheck.Checked ? Programador.OrdenesFabricacion.Where(x => x.Seleccionado).ToList().Count : 0;
                Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().OrdenMarcacion = ordenSeleccion;

                if (oCheck.Checked)
                {
                    oMatOrdenes.Columns.Item("SelOrder").Cells.Item(fila).Specific.Value = ordenSeleccion.ToString();
                    oMatOrdenes.SelectRow(fila, true, true);
                }
                else
                {
                    if (!Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().ProgramadoEnSAP)
                    {
                        Programador.OrdenesFabricacion.Where(x => x.NroOrdenFabricacion == orden && x.Etapa == etapa && x.Recurso == recurso).FirstOrDefault().Programado = false;
                        oMatOrdenes.Columns.Item("ProgDate").Cells.Item(fila).Specific.Value = string.Empty;
                        oMatOrdenes.Columns.Item("Col_0").Cells.Item(fila).Specific.Value = string.Empty;
                        oMatOrdenes.Columns.Item("StartTime").Cells.Item(fila).Specific.Value = "00:00";
                        oMatOrdenes.Columns.Item("FinishTime").Cells.Item(fila).Specific.Value = "00:00";
                    }

                    int ordenDesmarcado = Convert.ToInt32(oMatOrdenes.Columns.Item("SelOrder").Cells.Item(fila).Specific.Value);
                    ActualizarOrden(ref oMatOrdenes, ordenDesmarcado);
                    oMatOrdenes.Columns.Item("SelOrder").Cells.Item(fila).Specific.Value = ordenSeleccion.ToString();
                    oMatOrdenes.SelectRow(fila, false, true);
                }

            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
            finally { oForm.Freeze(false); }
        }


        private bool ValidarEtapasFiltroRecurso(int docentry, int StageId)
        {
            try
            {
                int etapasSinProgramar = GetEtapasAnterioresSinProgramar(docentry, StageId);

                if (etapasSinProgramar > 0)
                {
                    ClsMain.oApplication.StatusBar.SetText("Existen etapas anteriores que aún no se han programado, para mayor visibilidad modifique los filtros de búsqueda", BoMessageTime.bmt_Short, BoStatusBarMessageType.smt_Error);
                    return false;
                }

                return true;

            }
            catch { }
            return false;
        }

        private int GetEtapasAnterioresSinProgramar(int docentry, int stageId)
        {
            try
            {
                Recordset oRS = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
                string query = Queries.ValidarStage(ClsMain.oCompany.DbServerType, docentry, stageId);
                logger.Debug(query);
                oRS.DoQuery(query);

                if (!oRS.EoF)
                    return oRS.Fields.Item(0).Value;

            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }

            return 1;
        }

        private void ActualizarOrden(ref Matrix oMatOrdenes, int fila)
        {
            Programador.ReordenarSeleccion(fila);
            List<OrdenFabricacion> ordenesSeleccionadas = Programador.OrdenesFabricacion.Where(x => x.Seleccionado).ToList();

            foreach (OrdenFabricacion orden in ordenesSeleccionadas)
            {
                if (!orden.Programado)
                    oMatOrdenes.Columns.Item("SelOrder").Cells.Item(orden.IndiceEnMatrix).Specific.Value = orden.OrdenMarcacion.ToString();
            }

            oMatOrdenes.AutoResizeColumns();

        }
    }
}