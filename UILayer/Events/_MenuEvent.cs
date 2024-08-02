using System;
using System.Linq;
using DataLayer.Entidades;

namespace Reportes.Events
{
    class _MenuEvent
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(_MenuEvent));
        public void DoAction(ref SAPbouiCOM.MenuEvent pVal, out bool BubbleEvent)
        {
            BubbleEvent = true;

            if (pVal.BeforeAction) return;
            try
            {
                string frm = ClsMain.oApplication.Forms.ActiveForm.TypeEx;
                SAPB1FormInfo sb1fi = ClsMain.ListaForms.FirstOrDefault(x => x.FormType == frm);
                //if (sb1fi != null)
                //{
                //    //MenuEvent.IObjectMenuEvent oMenuEvent = sb1fi.ProcesadorMenu;
                //    //oMenuEvent.MenuEventAction(ref pVal, out BubbleEvent);
                //}

                switch (pVal.MenuUID)
                {
                    case "mnuProgO":
                        Util.FormBuilder.CreateFormProgram("frmProgram.srf", "frmProg");
                        break;
                    case "mnuProgR":
                        Util.FormBuilder.CreateFormProgRec("frmProgRec.srf", "frmProgR");
                        break;
                }
               
            }
            catch (Exception ex)
            {
                logger.Error("DoAction", ex);
            }
        }
    }
}
