using SAPbobsCOM;
using SAPbouiCOM;
using System;

namespace Reportes.Util
{
    class FormBuilder
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(FormBuilder));
        public static void CreateFormProgram(string fileName, string UID)
        {
            try
            {
                string sPath = null;
                string sXML = null;

                System.Xml.XmlDocument oXmlDoc = null;
                oXmlDoc = new System.Xml.XmlDocument();
                sPath = System.Windows.Forms.Application.StartupPath.ToString();
                oXmlDoc.Load(sPath + "\\Forms\\" + fileName);
                sXML = oXmlDoc.InnerXml.ToString();
                //ClsMain.oApplication.LoadBatchActions(ref sXML);
                FormCreationParams fCreationParams = ClsMain.oApplication.CreateObject(BoCreatableObjectType.cot_FormCreationParams);
                fCreationParams.XmlData = sXML;
                fCreationParams.FormType = UID;
                fCreationParams.UniqueID = UID + DateTime.Now.ToString("hhmmss");
                Form oForm = ClsMain.oApplication.Forms.AddEx(fCreationParams);
                //Form oForm = ClsMain.oApplication.Forms.Item(UID );
                oForm.DataSources.UserDataSources.Item("uOrden").Value = "E";
                oForm.DataSources.UserDataSources.Item("uValidar").Value = "Y";
                oForm.DataSources.UserDataSources.Item("uVisual").Value = "ALL";
                oForm.DataSources.UserDataSources.Item("uFprog").Value = ClsMain.oCompany.GetCompanyDate().AddDays(1).ToString("yyyyMMdd");
                oForm.DataSources.DBDataSources.Item("WOR1").SetValue("U_EXC_HoraIni", 0, GetHoraInicio().Substring(0, 5).Replace(":", ""));
                //oForm.Items.Item("Item_11").Specific.Value = horaInicio.Substring(0, 5);

                ComboBox oCombo = oForm.Items.Item("cboOrden").Specific;
                oCombo.ExpandType = BoExpandType.et_DescriptionOnly;
                oCombo = oForm.Items.Item("cboVisual").Specific;
                oCombo.ExpandType = BoExpandType.et_DescriptionOnly;
                CflOrden(oForm);
                oForm.Visible = true;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }

        private static string GetHoraInicio()
        {
            Recordset rs = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
            try
            {
                rs.DoQuery(Queries.GetHoraDefault());
                if (rs.RecordCount > 0)
                    return rs.Fields.Item(0).Value;
                else
                    throw new Exception("No se ha configurado la fecha inicial de programación. Detalles de Sociedad -> Hora Inicial de programación");
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
            finally
            {
                Tools.LiberarObjeto(rs);
            }
        }
        private static void CflOrden(Form oForm)
        {
            ChooseFromListCollection oCFLs = oForm.ChooseFromLists;
            ChooseFromListCreationParams oCFLCreationParams = (ChooseFromListCreationParams)ClsMain.oApplication.CreateObject(BoCreatableObjectType.cot_ChooseFromListCreationParams);

            oCFLCreationParams.MultiSelection = false;
            oCFLCreationParams.ObjectType = "202";
            oCFLCreationParams.UniqueID = "cflOrden";
            SAPbouiCOM.ChooseFromList oCFL = oCFLs.Add(oCFLCreationParams);

            Conditions oCons = oCFL.GetConditions();
            Condition oCon = oCons.Add();
            oCon.Alias = "Status";
            oCon.Operation = BoConditionOperation.co_EQUAL;
            oCon.CondVal = "R";
            oCFL.SetConditions(oCons);

            EditText txtCuenta = ((EditText)oForm.Items.Item("txtOrden").Specific);
            txtCuenta.ChooseFromListUID = "cflOrden";
            txtCuenta.ChooseFromListAlias = "DocEntry";
        }

        private static void CflRecurso(Form oForm)
        {
            ChooseFromListCollection oCFLs = oForm.ChooseFromLists;
            SAPbouiCOM.ChooseFromList oCFL = null;
            ChooseFromListCreationParams oCFLCreationParams = (ChooseFromListCreationParams)ClsMain.oApplication.CreateObject(BoCreatableObjectType.cot_ChooseFromListCreationParams);

            oCFLCreationParams.MultiSelection = false;
            oCFLCreationParams.ObjectType = "290";
            oCFLCreationParams.UniqueID = "cflRes";
            oCFL = oCFLs.Add(oCFLCreationParams);

            Conditions oCons = oCFL.GetConditions();
            Condition oCon = oCons.Add();
            oCon.Alias = "ResType";
            oCon.Operation = BoConditionOperation.co_EQUAL;
            oCon.CondVal = "M";
            oCon.Relationship = BoConditionRelationship.cr_AND;
            oCon = oCons.Add();
            oCon.Alias = "validFor";
            oCon.Operation = BoConditionOperation.co_EQUAL;
            oCon.CondVal = "Y";
            oCFL.SetConditions(oCons);

            EditText txtCuenta = ((EditText)oForm.Items.Item("txtRes").Specific);
            txtCuenta.ChooseFromListUID = "cflRes";
            txtCuenta.ChooseFromListAlias = "ResCode";
        }

        public static void CreateFormProgRec(string fileName, string UID)
        {
            try
            {
                string sPath = null;
                string sXML = null;

                System.Xml.XmlDocument oXmlDoc = null;
                oXmlDoc = new System.Xml.XmlDocument();
                sPath = System.Windows.Forms.Application.StartupPath.ToString();
                oXmlDoc.Load(sPath + "\\Forms\\" + fileName);
                sXML = oXmlDoc.InnerXml.ToString();
                ClsMain.oApplication.LoadBatchActions(ref sXML);

                Form oForm = ClsMain.oApplication.Forms.Item(UID);
                oForm.DataSources.UserDataSources.Item("uFprog").Value = ClsMain.oCompany.GetCompanyDate().AddDays(1).ToString("yyyyMMdd");
                oForm.DataSources.UserDataSources.Item("uOrden").Value = "E";

                Button boton = (Button)oForm.Items.Item("btnUP").Specific;
                boton.Image = sPath + "\\Resources\\UP.jpg";

                boton = (Button)oForm.Items.Item("btnDOWN").Specific;
                boton.Image = sPath + "\\Resources\\DOWN.jpg";
                CflRecurso(oForm);
                oForm.Visible = true;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }
        }

        public static void AddMenuItems()
        {
            Menus oMenus = ClsMain.oApplication.Menus;
            MenuCreationParams oCreationPackage = (MenuCreationParams)ClsMain.oApplication.CreateObject(BoCreatableObjectType.cot_MenuCreationParams);
            string sPath = System.Windows.Forms.Application.StartupPath.ToString();
            try
            {
                MenuItem oMenuItem = ClsMain.oApplication.Menus.Item("4352");
                oMenus = oMenuItem.SubMenus;
                oCreationPackage.Type = BoMenuType.mt_STRING;
                oCreationPackage.UniqueID = "mnuImpPO";
                oCreationPackage.String = "Impresión de órdenes programadas";
                oCreationPackage.Position = 6;
                oMenus.AddEx(oCreationPackage);

                oCreationPackage.Type = BoMenuType.mt_STRING;
                oCreationPackage.UniqueID = "mnuProgO";
                oCreationPackage.String = "Programación de órdenes";
                oCreationPackage.Position = 5;
                oMenus.AddEx(oCreationPackage);

    
                //oCreationPackage.Type = BoMenuType.mt_STRING;
                //oCreationPackage.UniqueID = "mnuProgR";
                //oCreationPackage.String = "Programación de recursos";
                //oCreationPackage.Position = 6;
                //oMenus.AddEx(oCreationPackage);
            }
            catch  { }
        }
    }
}