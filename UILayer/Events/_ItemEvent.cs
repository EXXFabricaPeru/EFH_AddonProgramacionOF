using DataLayer.Entidades;
using Reportes.Events.ItemEvent;
using SAPbouiCOM;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Reportes.Events
{
    class _ItemEvent
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(_ItemEvent));

        public void DoAction(string FormUID, ref SAPbouiCOM.ItemEvent itemEvent, out bool BubbleEvent)
        {
            BubbleEvent = true;
            try
            {
                string frm = itemEvent.FormTypeEx;
                SAPB1FormInfo sb1fi = ClsMain.ListaForms.FirstOrDefault(x => x.FormType == frm);

                if (sb1fi != null)
                {
                    ItemEvent.IObjectItemEvent IObjectItemEvent = sb1fi.ProcesadorItem;
                    IObjectItemEvent.ItemEventAction(FormUID, ref itemEvent, out BubbleEvent);
                }
                else if (frm == "0")
                {
                    if (ADistribuirItemEvent.bUpdatePO)
                    {
                        ItemEvent.IObjectItemEvent IObjectItemEvent = new ADistribuirItemEvent();
                        IObjectItemEvent.ItemEventAction(FormUID, ref itemEvent, out BubbleEvent);
                    }
                }
                else if (frm == "65211")
                {
                    if (ADistribuirItemEvent.bAddLine)
                    {
                        ItemEvent.IObjectItemEvent IObjectItemEvent = new ADistribuirItemEvent();
                        IObjectItemEvent.ItemEventAction(FormUID, ref itemEvent, out BubbleEvent);
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error("DoAction", ex);
            }
        }
    }
}