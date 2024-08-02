using System;

namespace Reportes.Events
{
    class _AppEvent
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(_AppEvent));
        public void DoAction(SAPbouiCOM.BoAppEventTypes EventType)
        {
            try
            {
                switch (EventType)
                {
                    case SAPbouiCOM.BoAppEventTypes.aet_ServerTerminition:
                    case SAPbouiCOM.BoAppEventTypes.aet_ShutDown:
                    case SAPbouiCOM.BoAppEventTypes.aet_CompanyChanged:
                        Environment.Exit(0);
                        break;
                    case SAPbouiCOM.BoAppEventTypes.aet_LanguageChanged:
                    default:
                        break;
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }
    }
}