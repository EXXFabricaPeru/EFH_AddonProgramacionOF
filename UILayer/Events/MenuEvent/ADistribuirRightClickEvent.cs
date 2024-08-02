//using CrystalDecisions.CrystalReports.Engine;
//using log4net.Repository.Hierarchy;
//using Reportes.Events.ItemEvent;
//using Reportes.Events.RightClickEvent;
//using SAPbobsCOM;
//using SAPbouiCOM;
//using System;
//using System.Collections.Generic;
//using System.Linq;
//using System.Text;
//using System.Threading.Tasks;
//using System.Windows.Forms;
//using static System.Windows.Forms.VisualStyles.VisualStyleElement;

//namespace Reportes.Events.MenuEvent
//{
//    internal class ADistribuirRightClickEvent : IObjectRightClickEvent
//    {
//        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(ADistribuirRightClickEvent));
//        public void RightClickEvent(SAPbouiCOM.Form oForm, ref ContextMenuInfo eventInfo, out bool BubbleEvent)
//        {
//            BubbleEvent = true;
//            try
//            {
//                if (oForm.TypeEx == "65211")
//                {
//                    switch (eventInfo.EventType)
//                    {
//                        //case BoEventTypes.et_FORM_DEACTIVATE:
//                        //case BoEventTypes.et_CLICK:
//                        case BoEventTypes.et_RIGHT_CLICK:
//                            ClickMenu(oForm, ref eventInfo, out BubbleEvent);
//                            break;
//                    }
//                }
//            }
//            catch (Exception ex)
//            {
//                logger.Error("RightClickAction", ex);
//            }
//        }

//        private void ClickMenu(SAPbouiCOM.Form oForm, ref ContextMenuInfo eventInfo, out bool BubbleEvent)
//        {
//            BubbleEvent = false;
//            try
//            {
//                if (eventInfo.BeforeAction)
//                {
//                    if (ADistribuirItemEvent.bAddLine)
//                    {
//                        oForm.Menu.Item("1292").Activate();
//                        //SAPbouiCOM.Menus omenus;
//                        //SAPbouiCOM.MenuCreationParams oCreationPackage;
//                        //SAPbouiCOM.MenuItem oMenuItem = oForm.Menu;
//                        //if (!oMenuItem.SubMenus.Exists("1292"))
//                        //{
//                        //    oCreationPackage = ClsMain.oApplication.CreateObject(BoCreatableObjectType.cot_MenuCreationParams);
//                        //    oCreationPackage.Type = BoMenuType.mt_STRING;
//                        //    oCreationPackage.UniqueID = "1292";
//                        //    oCreationPackage.String = "Añadir línea";
//                        //    oCreationPackage.Enabled = true;
//                        //    omenus = oMenuItem.SubMenus;
//                        //    omenus.AddEx(oCreationPackage);
//                        //    oMenuItem.SubMenus.Item("1292").Activate();
//                        //}
//                        //else
//                        //    oMenuItem.SubMenus.Item("1292").Activate();
//                    }
//                }
//            }
//            catch (Exception)
//            {
//            }
//        }
//    }
//}
