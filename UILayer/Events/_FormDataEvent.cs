using System;
using SAPbouiCOM;
using System.Linq;
using DataLayer.Entidades;

namespace Reportes.Events
{
    class _FormDataEvent
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(_FormDataEvent));
        public void DoAction(ref BusinessObjectInfo BusinessObjectInfo, out bool BubbleEvent)
        {
            BubbleEvent = true;
            //logger.Debug($"DoAction: EventType = {Enum.GetName(typeof(SAPbouiCOM.BoEventTypes), BusinessObjectInfo.EventType)}, FormType = {BusinessObjectInfo.FormTypeEx}, ObjectKey = {BusinessObjectInfo.ObjectKey}, Type = {BusinessObjectInfo.Type}");
            try
            {
                string frm = BusinessObjectInfo.FormTypeEx;
                SAPB1FormInfo sb1fi = ClsMain.ListaForms.FirstOrDefault(x => x.FormType == frm);

                if (sb1fi != null) {
                    FormDataEvent.IObjectFormDataEvent oFormDataEvent = sb1fi.ProcesadorFormData;
                    oFormDataEvent.DataFormAction(ref BusinessObjectInfo, out BubbleEvent);
                }
            }
            catch (Exception ex)
            {
                logger.Error("DoAction", ex);
            }
        }
    }
}