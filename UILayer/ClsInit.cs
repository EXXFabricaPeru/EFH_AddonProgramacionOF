using log4net.Appender;
using log4net.Layout;
using log4net.Repository.Hierarchy;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Linq;
using System.Reflection;

namespace Reportes
{
    class ClsInit
    {
        //public static SAPdata.Producto producto = new SAPdata.Producto();
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType.Name);
        private static bool instalado = false;

        public ClsInit()
        {
            Init();
        }
        public void Init()
        {
            try
            {
                SetUpLogger();
                SetApplication();
                SetCompany();
                //SetProducto();
                SetFilters();
                SetEvents();
                //ValidarLicencia();
                //ValidarVersion();
                //SetVariables();
                Util.FormBuilder.AddMenuItems();
                ClsMain.MensajeSuccess("[EXXIS - Programación] Inicio Satisfactorio.");
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw ex;
            }
        }

        private void SetApplication()
        {
            try
            {
                SAPbouiCOM.SboGuiApi SboGuiApi = new SAPbouiCOM.SboGuiApi();
                string sConnectionString = Convert.ToString(Environment.GetCommandLineArgs().GetValue(1));
                SboGuiApi.Connect(sConnectionString);
                ClsMain.oApplication = SboGuiApi.GetApplication();
            }
            catch (Exception ex)
            {
                logger.Error("SetApplication", ex);
            }

        }
        private void SetCompany()
        {
            try
            {
                ClsMain.oCompany = (SAPbobsCOM.Company)ClsMain.oApplication.Company.GetDICompany();
                logger.Info($"SetCompany: conectado a {ClsMain.oCompany.CompanyName}({ClsMain.oCompany.CompanyDB})");
            }
            catch (Exception ex)
            {
                logger.Error("SetCompany", ex);
            }
        }
        //private void SetProducto()
        //{
        //    producto.Codigo = "EXCPRG";
        //    producto.Nombre = "Addon Programacion";
        //    producto.Version = "1.00.0";
        //    producto.Server = ClsMain.oCompany.Server;
        //}
        //private static void ValidarLicencia()
        //{
        //    SAPdata.Conexion.ConectarCliente();
        //    bool res = SAPdata.Licencia.ValidarLicencia(ref producto, out string error);
        //    if (!res)
        //    {
        //        SAPdata.LicenciaGUI licenciaGUI = new SAPdata.LicenciaGUI(producto, error);
        //        SAPdata.Conexion.DesconectarCliente();
        //        if (!licenciaGUI.Correcto)
        //        {
        //            ClsMain.oApplication.MessageBox("No se encontró una licencia válida, el addon se cerrará");
        //            ClsMain.oCompany.Disconnect();
        //            Environment.Exit(0);
        //        }
        //        else
        //        {
        //            ClsMain.MensajeSuccess("Licencia instalada correctamente");
        //            ClsMain.oApplication.MessageBox("Licencia instalada correctamente");
        //            instalado = true;
        //        }
        //    }
        //}

        //private void ValidarVersion()
        //{
        //    SAPdata.Conexion.ConectarCliente();

        //    bool res = SAPdata.Licencia.ValidarVersion(producto);
        //    if (res || instalado)
        //    {
        //        //ValidarEstructura();
        //        SAPdata.Licencia.ActualizarVersion(producto);
        //    }
        //    SAPdata.Conexion.DesconectarCliente();
        //}

        private void SetFilters()
        {
            SAPbouiCOM.EventFilters oFilters = new SAPbouiCOM.EventFilters();

            SAPbouiCOM.EventFilter oFilter;

            IEnumerable<string> formsSelfCancel = ClsMain.ListaForms.Where(x => x.SelfCancelable).Select(x => x.FormType);
            IEnumerable<string> formsAll = ClsMain.ListaForms.Select(x => x.FormType);


            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_CLICK);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }
            
            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_DOUBLE_CLICK);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_COMBO_SELECT);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_MENU_CLICK);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_ITEM_PRESSED);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }
            oFilter.AddEx("0");

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_CHOOSE_FROM_LIST);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_FORM_UNLOAD);
            oFilter.AddEx("0");

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_FORM_LOAD);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }
            oFilter.AddEx("0");

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_FORM_ACTIVATE);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_FORM_DATA_ADD);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_FORM_DATA_LOAD);
            foreach (string formul in formsSelfCancel)
            {
                oFilter.AddEx(formul);
            }

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_FORM_CLOSE);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }
            oFilter.AddEx("0");

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_VALIDATE);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }

            oFilter = oFilters.Add(SAPbouiCOM.BoEventTypes.et_MATRIX_LINK_PRESSED);
            foreach (string formul in formsAll)
            {
                oFilter.AddEx(formul);
            }

            ClsMain.oApplication.SetFilter(oFilters);
        }
        private void SetEvents()
        {
            Events._AppEvent oAppEvent = new Events._AppEvent();
            Events._ItemEvent oItemEvent = new Events._ItemEvent();
            Events._FormDataEvent oFormDataEvent = new Events._FormDataEvent();
            Events._MenuEvent oMenuEvent = new Events._MenuEvent();

            ClsMain.oApplication.AppEvent += new SAPbouiCOM._IApplicationEvents_AppEventEventHandler(oAppEvent.DoAction);
            ClsMain.oApplication.FormDataEvent += new SAPbouiCOM._IApplicationEvents_FormDataEventEventHandler(oFormDataEvent.DoAction);
            ClsMain.oApplication.ItemEvent += new SAPbouiCOM._IApplicationEvents_ItemEventEventHandler(oItemEvent.DoAction);
            ClsMain.oApplication.MenuEvent += new SAPbouiCOM._IApplicationEvents_MenuEventEventHandler(oMenuEvent.DoAction);
        }
        private void SetVariables()
        {

        }
        private void SetUpLogger()
        {
            NameValueCollection _settings = System.Configuration.ConfigurationManager.AppSettings;

            Hierarchy hierarchy = (Hierarchy)log4net.LogManager.GetRepository();

            PatternLayout patternLayout = new PatternLayout();
            //patternLayout.ConversionPattern = "%date %-5level %logger - %message%newline";
            patternLayout.ConversionPattern = "%d{yyyyMMdd-HH:mm:ss} [%-10t] %-5p (%c{2}:%L) [%logger] [%method] %m%n";
            patternLayout.ActivateOptions();

            RollingFileAppender roller = new RollingFileAppender();
            roller.AppendToFile = true;
            roller.File = @"Log\Mensajes.log";
            roller.Layout = patternLayout;
            roller.MaxSizeRollBackups = 5;
            roller.MaximumFileSize = "5MB";
            roller.RollingStyle = RollingFileAppender.RollingMode.Size;
            roller.StaticLogFileName = true;
            roller.ActivateOptions();
            hierarchy.Root.AddAppender(roller);

            ConsoleAppender console = new ConsoleAppender();
            console.Layout = patternLayout;
            console.ActivateOptions();
            hierarchy.Root.AddAppender(console);

            hierarchy.Root.Level = hierarchy.LevelMap[_settings.Get("loglevel")] == null ? log4net.Core.Level.Error : hierarchy.LevelMap[_settings.Get("loglevel")];
            hierarchy.Configured = true;
        }
        private void ValidarEstructura()
        {
            ClsMain.MensajeWarning("Validando estructura, por favor espere");

        }
    }
}