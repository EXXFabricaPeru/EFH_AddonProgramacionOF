using Itenso.TimePeriod;
using SAPbobsCOM;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Xml.Linq;

namespace Reportes.Entidades
{
    public class ProgramadorOrdenes
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(ProgramadorOrdenes));
        public List<OrdenFabricacion> OrdenesFabricacion { get; set; }
        public bool FiltroPorRecurso { get; set; }
        public string HoraInicioLabores { get; set; }
        public int HoraIL { get; set; }
        public int MinutoIL { get; set; }
        public int SegundoIL { get; set; }

        public ProgramadorOrdenes()
        {
            OrdenesFabricacion = new List<OrdenFabricacion>();
        }

        public void CargarOrdenes(string query)
        {
            Recordset oRs = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.BoRecordset);
            oRs.DoQuery(query);

            if (oRs.RecordCount > 0)
            {
                string xml = oRs.GetAsXML();
                XDocument XDoc = XDocument.Parse(xml);
                int indiceMatrix = 1;
                OrdenesFabricacion = (from q in XDoc.Descendants("row")
                                      select new OrdenFabricacion
                                      {
                                          IndiceEnMatrix = indiceMatrix++,
                                          Programado = q.Element("Scheduled").Value == "Y",
                                          StandBy =  (string.IsNullOrEmpty(q.Element("Standby").Value) || q.Element("Terminado").Value == "N" ? "N": q.Element("Standby").Value ) == "Y",
                                          Parcial = (string.IsNullOrEmpty(q.Element("Parcial").Value) ? "N" : q.Element("Parcial").Value) == "Y",
                                          Anular = (string.IsNullOrEmpty(q.Element("Anulado").Value) ? "N" : q.Element("Anulado").Value) == "Y",
                                          Terminado = (string.IsNullOrEmpty(q.Element("Terminado").Value) || q.Element("Terminado").Value == "N" ? "N" : q.Element("Terminado").Value) == "Y",
                                          ProgramadoEnSAP = q.Element("Scheduled").Value == "Y",
                                          Seleccionado = q.Element("Check").Value == "Y",
                                          OrdenMarcacion = int.Parse(q.Element("SelOrder").Value),
                                          NroOrdenFabricacion = Convert.ToInt32(q.Element("OrderDE").Value),
                                          LineaOF = Convert.ToInt32(q.Element("OLineNum").Value),
                                          Etapa = Convert.ToInt32(q.Element("StageId").Value),
                                          Recurso = q.Element("ResCode").Value,
                                          FechaInicio = (string.IsNullOrEmpty(q.Element("ProgramDate").Value) ? "00010101" : q.Element("ProgramDate").Value), // q.Element("ProgramDate").Value
                                          HoraInicio = (string.IsNullOrEmpty(q.Element("StartTime").Value) ? "00:00" : q.Element("StartTime").Value), //q.Element("StartTime").Value
                                          FechaFin = (string.IsNullOrEmpty(q.Element("ProgramDateEnd").Value) ? "00010101" : q.Element("ProgramDateEnd").Value), //q.Element("ProgramDateEnd").Value
                                          HoraFin = (string.IsNullOrEmpty(q.Element("FinishTime").Value) ? "00:00" : q.Element("FinishTime").Value), //q.Element("FinishTime").Value
                                          CantidadHoras = (string.IsNullOrEmpty(q.Element("Hours").Value) ? "00:00:00" : q.Element("Hours").Value), //q.Element("Hours").Value,
                                          CantidadPlaneada = double.Parse(q.Element("PlannedQty").Value, CultureInfo.InvariantCulture),
                                          Velocidad = q.Element("TimeResUn").Value,
                                          DtFechaInicio = DateTime.ParseExact((string.IsNullOrEmpty(q.Element("ProgramDate").Value) ? "00010101" : q.Element("ProgramDate").Value) + " " + (string.IsNullOrEmpty(q.Element("StartTime").Value) ? "00:00" : q.Element("StartTime").Value), "yyyyMMdd HH:mm", null),
                                          DtFechaFin = DateTime.ParseExact((string.IsNullOrEmpty(q.Element("ProgramDateEnd").Value) ? "00010101" : q.Element("ProgramDateEnd").Value) + " " + (string.IsNullOrEmpty(q.Element("FinishTime").Value) ? "00:00" : q.Element("FinishTime").Value), "yyyyMMdd HH:mm", null),
                                      }).ToList();
            }
        }

        internal void ProgramarOrdenes(DateTime fechaInicio, string horaInicio, int noLineaRP = -1)
        {
            try
            {
                HoraInicioLabores = horaInicio;
                ValidarConfiguraciones();

                if (OrdenesFabricacion.Where(x => x.Programado).ToList().Count == 0) //CASO BÁSICO
                {
                    List<OrdenFabricacion> ordenesSeleccionadas = OrdenesFabricacion.Where(x => x.Seleccionado).OrderBy(x => x.OrdenMarcacion).ToList();
                    TimeSpan horaInicioActividades = TimeSpan.ParseExact(HoraInicioLabores, "hh\\:mm", null);
                    DateTime ultimaFechaInicio = fechaInicio.Add(horaInicioActividades);

                    foreach (OrdenFabricacion of in ordenesSeleccionadas)
                    {
                        of.DtFechaInicio = ultimaFechaInicio;
                       
                        of.FechaInicio = ultimaFechaInicio.ToString("yyyyMMdd");
                        of.HoraInicio = horaInicioActividades.ToString(@"hh\:mm");

                        TimeSpan cantidadHoras = TimeSpan.ParseExact(of.CantidadHoras, "hh\\:mm\\:ss", null);
                        of.DtFechaFin = ultimaFechaInicio.Add(cantidadHoras);

                        ultimaFechaInicio = of.DtFechaFin;
                        of.FechaFin = ultimaFechaInicio.Add(cantidadHoras).ToString("yyyyMMdd");
                        of.HoraFin = cantidadHoras.ToString(@"hh\:mm");
                        of.Programado = true; //cambio por lushianna
                    }
                }
                //CASO EN LAS QUE HAY PROGRAMADOS 
                else
                {
                    if (noLineaRP > -1)
                    {
                        DateTime fechaMinimaProgramada = noLineaRP > 1 ? OrdenesFabricacion.Min(x => x.DtFechaInicio) : fechaInicio;
                        OrdenesFabricacion.Where(w => w.OrdenMarcacion >= noLineaRP).ToList().ForEach(s =>
                       {
                           s.HoraFin = "";
                           s.FechaInicio = "";
                           s.FechaFin = "";
                           s.DtFechaFin = fechaMinimaProgramada;
                           s.DtFechaInicio = fechaMinimaProgramada;
                           s.Programado = false;
                       }
                        );
                    }


                    ProgramarEntreFechasProgramadas(fechaInicio, noLineaRP);
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
        }

        private void ProgramarEntreFechasProgramadas(DateTime fechaInicio, int noLineaRP = -1)
        {
            List<OrdenFabricacion> OFS = OrdenesFabricacion.Where(x => x.Seleccionado || x.Programado).OrderBy(x => x.OrdenMarcacion).ToList();
            logger.Debug($"hora inicio {HoraInicioLabores}");
            TimeSpan horaInicioActividades = TimeSpan.ParseExact(HoraInicioLabores, "hh\\:mm", null);

            foreach (OrdenFabricacion orden in OFS)
            {
                if (orden.Programado && noLineaRP == -1) continue;
                if (orden.OrdenMarcacion < noLineaRP) continue;
                TimePeriodCollection huecos = EncontrarHuecosEnRangos(fechaInicio, noLineaRP);

                ////noLineaRP++;
                //if (!orden.Programado)
                //{
                if (huecos.Count > 0)
                {
                    int indiceGap = 0;

                    while (!orden.Programado && indiceGap < huecos.Count)
                    {
                        logger.Debug($"CantidadHoras {orden.CantidadHoras}");
                        TimeSpan cantidadHoras = TimeSpan.ParseExact(orden.CantidadHoras, "hh\\:mm\\:ss", null);

                        if (cantidadHoras <= huecos[indiceGap].Duration)
                        {
                            orden.DtFechaInicio = huecos[indiceGap].Start;
                            orden.DtFechaFin = orden.DtFechaInicio.Add(cantidadHoras);
                            orden.Programado = true;
                        }
                        else
                            indiceGap++;
                    }

                    if (!orden.Programado) //INTENTÓ ASIGNARLO EN LOS HUECOS Y NO SE PUDO
                    {
                        DateTime ultimaFechaFin = OrdenesFabricacion.Max(x => x.DtFechaFin);

                        orden.DtFechaInicio = ultimaFechaFin;
                        logger.Debug($"CantidadHoras no programado {orden.CantidadHoras}");
                        TimeSpan cantidadHoras = TimeSpan.ParseExact(orden.CantidadHoras, "hh\\:mm\\:ss", null);
                        orden.DtFechaFin = orden.DtFechaInicio.Add(cantidadHoras);
                        orden.FechaInicio = orden.DtFechaInicio.ToString("yyyyMMdd");
                        orden.FechaFin = orden.DtFechaFin.ToString("yyyyMMdd");
                        orden.Programado = true;
                    }
                }
                else
                {
                    DateTime ultimaFechaFin = OrdenesFabricacion.Max(x => x.DtFechaFin);

                    if (ultimaFechaFin > fechaInicio.Add(horaInicioActividades))
                        orden.DtFechaInicio = ultimaFechaFin;
                    else
                        orden.DtFechaInicio = fechaInicio.Add(horaInicioActividades);
                    logger.Debug($"CantidadHoras programado {orden.CantidadHoras}");
                    TimeSpan cantidadHoras = TimeSpan.ParseExact(orden.CantidadHoras, "hh\\:mm\\:ss", null);

                    //if (orden.DtFechaInicio.TimeOfDay < horaInicioActividades)
                    //    orden.DtFechaInicio = orden.DtFechaInicio.Date.Add(horaInicioActividades);

                    orden.DtFechaFin = orden.DtFechaInicio.Add(cantidadHoras);
                    orden.FechaInicio = orden.DtFechaInicio.ToString("yyyyMMdd");
                    orden.FechaFin = orden.DtFechaFin.ToString("yyyyMMdd");
                    orden.Programado = true;
                    //cambio lushianna 
                    orden.StandBy = false;
                    orden.Terminado = false;
                    orden.Anular = false;
                    orden.Parcial = false;
                }
                //}
            }
        }
        public void ChangeProgramadorVal(int linea, string newRecurso = "", string newTime = "", double cantPlaneada = 0, bool anular = false, bool terminar = false)
        {
            var changeLine = OrdenesFabricacion.Where(c => c.IndiceEnMatrix == linea).ToList();
            changeLine.ForEach(c => c.Seleccionado = true);
            if (!string.IsNullOrEmpty(newRecurso))
            {
                changeLine.ForEach(c => c.Recurso = newRecurso);
            }
            if(!string.IsNullOrEmpty(newTime))changeLine.ForEach(c => c.CantidadHoras = newTime);
            if(!string.IsNullOrEmpty(newTime))changeLine.ForEach(c => c.CantidadPlaneada = cantPlaneada);
            if (anular) changeLine.ForEach(c => c.Anular = true);
            if (terminar) changeLine.ForEach(c => c.Terminado = true);
            changeLine.ForEach(c => c.ActualizarProgramacion());
        }
        public void ClearProgramadorVal(int linea, bool standBy = false, bool parcial = false, bool terminado = false, bool otro = false)
        {
            var removerLine = OrdenesFabricacion.Where(c => c.IndiceEnMatrix == linea).ToList();
            removerLine.ForEach(c => c.Seleccionado = false);
            removerLine.ForEach(c => c.StandBy = standBy);
            removerLine.ForEach(c => c.Parcial = parcial);
            removerLine.ForEach(c => c.Terminado = terminado);
            removerLine.ForEach(c => c.Anular = otro);

            removerLine.ForEach(c => c.Programado = false);
            //removerLine.ForEach(c => c.ProgramadoEnSAP = false);
            removerLine.ForEach(c => c.HoraInicio = "");
            removerLine.ForEach(c => c.FechaInicio = "");
            removerLine.ForEach(c => c.HoraFin = "");
            removerLine.ForEach(c => c.FechaFin = "");
            removerLine.ForEach(c => c.DtFechaInicio = DateTime.MinValue);
            removerLine.ForEach(c => c.DtFechaFin = DateTime.MinValue);
        }
        public TimePeriodCollection EncontrarHuecosEnRangos(DateTime fechaInicio, int noLineaRP)
        {
            // Periodos de Fechas Programadas
            List<OrdenFabricacion> ordenesProgramadas = OrdenesFabricacion.Where(x => x.Programado).ToList();
            
            DateTime fechaMinimaProgramada = OrdenesFabricacion.Min(x => x.DtFechaInicio);
            TimePeriodCollection periodos = new TimePeriodCollection();

            TimeSpan horaInicioActividades = TimeSpan.ParseExact(HoraInicioLabores, "hh\\:mm", null);

            periodos.Add(new TimeRange(fechaInicio.Add(horaInicioActividades), fechaMinimaProgramada));

            foreach (OrdenFabricacion orden in ordenesProgramadas)
            {
                if (!orden.Seleccionado && orden.Programado) //PROGRAMADOS ANTERIORMENTE (NO SE PUEDEN SELECCIONAR)
                {
                    orden.DtFechaInicio = DateTime.ParseExact(orden.FechaInicio, "yyyyMMdd", null);
                    TimeSpan horaInicio = TimeSpan.ParseExact(orden.HoraInicio, "hh\\:mm", null);
                    orden.DtFechaInicio = orden.DtFechaInicio.Add(horaInicio);
                    TimeSpan duracion = TimeSpan.ParseExact(orden.CantidadHoras, "hh\\:mm\\:ss", null);
                    orden.DtFechaFin = orden.DtFechaInicio.Add(duracion);
                    //if(orden.DtFechaInicio >= fechaInicio)
                    periodos.Add(new TimeRange(orden.DtFechaInicio, orden.DtFechaFin));
                }
                else
                {
                    //if (orden.DtFechaInicio >= fechaInicio)
                    periodos.Add(new TimeRange(orden.DtFechaInicio, orden.DtFechaFin));
                }
            }
            // huecos
            TimePeriodCollection gaps = new TimePeriodCollection();
            gaps.AddAll(new TimeGapCalculator<TimeRange>().GetGaps(periodos));

            return gaps;
        }

        private void ValidarConfiguraciones()
        {
            if (string.IsNullOrEmpty(HoraInicioLabores))
                throw new Exception("No se ha configurado la hora de inicio de labores de los recursos.");

            string[] horaInfo = HoraInicioLabores.Split(':');

            if (horaInfo.Length != 2)
                throw new Exception("La hora configurada no tiene el formato correcto. Debe configurar un valor con el formato hh:mm");
        }

        internal void ProcesarProgramacion(out int procesados, out List<string> errores)
        {
            try
            {
                procesados = 0;
                errores = new List<string>();

                OrdenesFabricacion = OrdenesFabricacion.Where(x => x.Seleccionado).ToList();
                if (OrdenesFabricacion.Count > 0)
                {
                    foreach (OrdenFabricacion ordenF in OrdenesFabricacion)
                    {
                        try
                        {
                            ordenF.ActualizarProgramacion();
                            procesados++;
                        }
                        catch (Exception ex)
                        {
                            errores.Add("Error en línea: " + ordenF.IndiceEnMatrix + " .Detalle: " + ex.Message);
                            continue;
                        }
                    }
                }
                else
                    throw new Exception("Debe haber seleccionado al menos una orden para programar");
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
        }

        internal void LimpiarProgramaciones(out int procesados, out List<string> errores, bool validacionEtapas)
        {
            try
            {
                procesados = 0;
                errores = new List<string>();

                OrdenesFabricacion = OrdenesFabricacion.Where(x => x.Seleccionado).ToList();

                if (OrdenesFabricacion.Count > 0)
                {
                    foreach (OrdenFabricacion orden in OrdenesFabricacion)
                    {
                        try
                        {
                            orden.LimpiarProgramacion(validacionEtapas);
                            procesados++;
                        }
                        catch (Exception ex)
                        {
                            errores.Add(ex.Message);
                            continue;
                        }
                    }
                }
                else
                    throw new Exception("Debe seleccionar al menos una linea para limpiar la programación");
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
        }

        internal void ReordenarSeleccion(int fila)
        {
            List<OrdenFabricacion> listaReordenable = OrdenesFabricacion.Where(x => x.Seleccionado && x.OrdenMarcacion > fila).ToList();

            foreach (OrdenFabricacion of in listaReordenable)
            {
                of.OrdenMarcacion--;
            }
        }
    }

    public class OrdenFabricacion
    {
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(OrdenFabricacion));
        public int IndiceEnMatrix { get; set; }
        public bool Seleccionado { get; set; }
        public int OrdenMarcacion { get; set; }
        public int NroOrdenFabricacion { get; set; }
        public int LineaOF { get; set; }
        public int Etapa { get; set; }
        public string Recurso { get; set; }
        public string FechaInicio { get; set; }
        public string HoraInicio { get; set; }
        public DateTime DtFechaInicio { get; set; }
        public string FechaFin { get; set; }
        public string HoraFin { get; set; }
        public DateTime DtFechaFin { get; set; }
        public string CantidadHoras { get; set; }
        public double CantidadPlaneada { get; set; }
        public string Velocidad { get; set; }
        public bool Programado { get; set; }
        public bool StandBy { get; set; }

        public bool Terminado { get; set; }
        public bool Parcial { get; set; }
        public bool Anular { get; set; }
        public bool ProgramadoEnSAP { get; set; }

        internal void ActualizarProgramacion()
        {
            try
            {
                ProductionOrders oPOrders = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.oProductionOrders);
                if (oPOrders.GetByKey(NroOrdenFabricacion))
                {
                    oPOrders.Lines.SetCurrentLine(LineaOF);
                    //DateTime Horas = DateTime.ParseExact(horacadena, "H:mm", null);
                    if (!actualizado(oPOrders.Lines, DtFechaInicio, DtFechaFin, Recurso, (CantidadPlaneada)) || Terminado || Anular)
                    {
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraIni").Value = DtFechaInicio;
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraFin").Value = DtFechaFin;
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value = Programado ? "Y" : "N";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXX_DSTANDBY").Value = StandBy ? "Y" : "N";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXX_DTERMIN").Value = Terminado ? "Y" : "N";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXX_DPARCIAL").Value = Parcial ? "Y" : "N";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXX_DANULA").Value = Anular ? "Y" : "N";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_FProgam").Value = DtFechaInicio;
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_FPROGF").Value = DtFechaFin;
                        oPOrders.Lines.PlannedQuantity = CantidadPlaneada;
                        oPOrders.Lines.ItemNo = Recurso;
                        oPOrders.UserFields.Fields.Item("U_EXX_CANULA").Value = Anular ? "Y" : "N";

                        if (oPOrders.Update() != 0)
                            throw new Exception(ClsMain.oCompany.GetLastErrorDescription());
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
        }


        bool actualizado(ProductionOrders_Lines linea, DateTime DtFechaInicio, DateTime DtFechaFin, string recurso, double cantidadPlanada)
        {
            DateTime hIni = linea.UserFields.Fields.Item("U_EXC_HoraIni").Value;
            DateTime hFion = linea.UserFields.Fields.Item("U_EXC_HoraFin").Value;
            double cantPlan = linea.PlannedQuantity;
            string originRes = linea.ItemNo;

            return (hIni.TimeOfDay == DtFechaInicio.TimeOfDay && hFion.TimeOfDay == DtFechaFin.TimeOfDay) && originRes == recurso && cantPlan == cantidadPlanada;
        }

        internal void LimpiarProgramacion(bool validacionEtapas)
        {
            try
            {
                ProductionOrders oPOrders = ClsMain.oCompany.GetBusinessObject(BoObjectTypes.oProductionOrders);
                if (oPOrders.GetByKey(NroOrdenFabricacion))
                {
                    if (validacionEtapas)
                    {
                        for (int i = 0; i < oPOrders.Lines.Count; i++)
                        {
                            oPOrders.Lines.SetCurrentLine(i);
                            if (oPOrders.Lines.ItemType == ProductionItemType.pit_Resource)
                            {
                                if (oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value == "Y" && oPOrders.Lines.StageID >= Etapa)
                                {
                                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_FProgam").Value = "";
                                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_FPROGF").Value = "";
                                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraIni").Value = "";
                                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraFin").Value = "";
                                    oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value = "N";
                                }
                            }
                        }
                    }
                    else
                    {
                        oPOrders.Lines.SetCurrentLine(LineaOF);
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraIni").Value = "";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_HoraFin").Value = "";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_Programado").Value = "N";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_FProgam").Value = "";
                        oPOrders.Lines.UserFields.Fields.Item("U_EXC_FPROGF").Value = "";
                    }

                    if (oPOrders.Update() != 0)
                        throw new Exception(ClsMain.oCompany.GetLastErrorDescription());
                }
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw;
            }
        }
    }
}
