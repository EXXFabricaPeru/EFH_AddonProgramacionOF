//using ExxisBibliotecaClases.entidades;
using DataLayer.Entidades;
using SAPbobsCOM;
using System;
using System.Collections.Generic;
using System.Reflection;

namespace Reportes
{
    static class ClsMain
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(MethodBase.GetCurrentMethod().DeclaringType.Name);

        public static Company oCompany;
        public static SAPbouiCOM.Application oApplication;
        public static List<SAPB1FormInfo> ListaForms;
        public static int ErrCode;
        public static string ErrMsg;

        [STAThread]
        static void Main()
        {
            try
            {
                ListaForms = ConfigurationFactory.ListarFormularios();
                ClsInit oClsInit = new ClsInit();
                System.Windows.Forms.Application.Run();
            }
            catch (Exception ex)
            {
                logger.Error("Main", ex);
                Environment.Exit(0);
            }
        }
        public static void MensajeSuccess(string mensaje)
        {
            try
            {
                oApplication.StatusBar.SetText(mensaje, SAPbouiCOM.BoMessageTime.bmt_Short, SAPbouiCOM.BoStatusBarMessageType.smt_Success);
            }
            catch { }
        }
        public static void MensajeWarning(string mensaje)
        {
            try
            {
                oApplication.StatusBar.SetText(mensaje, SAPbouiCOM.BoMessageTime.bmt_Short, SAPbouiCOM.BoStatusBarMessageType.smt_Warning);
            }
            catch { }
        }

        public static void Mensaje(string mensaje)
        {
            try
            {
                oApplication.StatusBar.SetText(mensaje, SAPbouiCOM.BoMessageTime.bmt_Short, SAPbouiCOM.BoStatusBarMessageType.smt_None);
            }
            catch { }
        }
        public static void MensajeError(string mensaje, bool estado = false)
        {
            try
            {
                if (!estado)
                {
                    oApplication.MessageBox(mensaje);
                }
                else
                {
                    oApplication.StatusBar.SetText(mensaje, SAPbouiCOM.BoMessageTime.bmt_Short, SAPbouiCOM.BoStatusBarMessageType.smt_Error);
                }
            }
            catch { }
        }

        public static void StartTransaction()
        {
            try
            {
                oCompany.StartTransaction();
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }

        public static bool InTransaction()
        {
            try
            {
                return oCompany.InTransaction;
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }

        public static void CommitTransaction()
        {
            try
            {
                oCompany.EndTransaction(SAPbobsCOM.BoWfTransOpt.wf_Commit);
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }
        public static void RollBackTransaction()
        {
            try
            {
                if (oCompany.InTransaction)
                {
                    oCompany.EndTransaction(SAPbobsCOM.BoWfTransOpt.wf_RollBack);
                }
            }
            catch (Exception ex)
            {

                throw ex;
            }
        }

        public static string LoadFromXML(ref string FileName)
        {
            System.Xml.XmlDocument oXmlDoc = null;
            string sPath = null;
            oXmlDoc = new System.Xml.XmlDocument();
            sPath = System.Windows.Forms.Application.StartupPath;
            oXmlDoc.Load(sPath + FileName);
            return (oXmlDoc.InnerXml);
        }
    }
}