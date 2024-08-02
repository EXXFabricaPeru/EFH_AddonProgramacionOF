using Reportes.Events.FormDataEvent;
using Reportes.Events.ItemEvent;
using Reportes.Events.MenuEvent;
using System;

namespace DataLayer.Entidades
{
    public class SAPB1FormInfo
    {
        public string FormType { get; set; }
        public string Nombre { get; set; }
        public IObjectFormDataEvent ProcesadorFormData { get; set; }
        public IObjectItemEvent ProcesadorItem { get; set; }
        public IObjectMenuEvent ProcesadorMenu { get; set; }
        public SAPbobsCOM.BoObjectTypes B1Tipo { get; set; }
        public string ObjectType { get; set; }
        public string Tabla { get; set; }
        public string LLave { get; set; }
        /// <summary>
        /// Indica si el formulario permite la cancelación desde si mismo sin generar uno adicional.
        /// </summary>
        public bool SelfCancelable { get; internal set; }
    }
}
