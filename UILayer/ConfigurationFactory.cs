using System;
using System.Collections.Generic;
using DataLayer.Entidades;
using Reportes.Events.FormDataEvent;
using Reportes.Events.ItemEvent;
using Reportes.Events.MenuEvent;

namespace Reportes
{
    public class ConfigurationFactory
    {
        public static List<SAPB1FormInfo> ListarFormularios()
        {
            List<SAPB1FormInfo> lista = new List<SAPB1FormInfo>()
            {
                new SAPB1FormInfo(){ Nombre = "Programacion", FormType = "frmProg", ProcesadorItem = new AProgramItemEvent() },//,ProcesadorFormData=new AReportesFormDataEvent(),ProcesadorMenu= new AReportesMenuEvent(), SelfCancelable = false },
                new SAPB1FormInfo(){ Nombre = "ProgramacionR", FormType = "frmProgR", ProcesadorItem = new AProgRecItemEvent() },//,ProcesadorFormData=new AReportesFormDataEvent(),ProcesadorMenu= new AReportesMenuEvent(), SelfCancelable = false },
                new SAPB1FormInfo(){ Nombre = "Distribuir", FormType = "frmKilosMaq", ProcesadorItem = new ADistribuirItemEvent() },//,ProcesadorFormData=new AReportesFormDataEvent(),ProcesadorMenu= new AReportesMenuEvent(), SelfCancelable = false },
                new SAPB1FormInfo(){ Nombre = "Imprimir", FormType = "frmImpres", ProcesadorItem = new AImprimirItemEvent() },//,ProcesadorFormData=new AReportesFormDataEvent(),ProcesadorMenu= new AReportesMenuEvent(), SelfCancelable = false },
                new SAPB1FormInfo(){ Nombre = "Cambiar", FormType = "frmCambiar", ProcesadorItem = new ACambiarItemEvent() }//,ProcesadorFormData=new AReportesFormDataEvent(),ProcesadorMenu= new AReportesMenuEvent(), SelfCancelable = false },

            };


            return lista;
        }
    }
}