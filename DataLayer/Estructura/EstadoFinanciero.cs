using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.IO;
using Microsoft.Office.Interop.Excel;
using DataLayer.Entidades;
using DataLayer.Util;
using SAPbobsCOM;

namespace DataLayer.Estructura
{
    public class EstadoFinanciero
    {
        Company oCompany;
        Application excel;
        private static readonly log4net.ILog logger = log4net.LogManager.GetLogger(typeof(EstadoFinanciero));
        Dictionary<int, string> FormulasNiv1 = new Dictionary<int, string>();
        Dictionary<int, string> FormulasNiv2 = new Dictionary<int, string>();
        Dictionary<int, string> FormulasNiv3 = new Dictionary<int, string>();
        Dictionary<int, string> FormulasNiv4 = new Dictionary<int, string>();
        List<int> ListaTotales = new List<int>();
        List<int> ColTotales = new List<int>();
        List<MesFinanciero> mesesFinancieros = new List<MesFinanciero>();
        List<string> ListaCC1 = new List<string>();
        List<string> ListaCC3 = new List<string>();
        string cnString = string.Empty;
        int NivelExcel;

        public EstadoFinanciero(Company oCmp, string cnn, ref List<string> cc1, ref List<string>cc3)
        {
            cnString = cnn;
            oCompany = oCmp;
            ListaCC1 = cc1;
            ListaCC3 = cc3;
        }

        public bool EjecutarReporte(DateTime fIni, DateTime fFin, string nivel, string ruta, string modelo, out string mensaje)
        {
            excel = new Application();
            Workbook wb = null;
            Worksheet ws = null;
            string reporte = "Template";
            mensaje = string.Empty;
            NivelExcel = int.Parse(nivel);
            try
            {
                string file = Directory.GetCurrentDirectory();
                string fileExcel = file + @"\Resources\" + reporte + ".xlsx";

                if (File.Exists(ruta))
                {
                    File.Delete(ruta);
                }

                wb = excel.Workbooks.Open(fileExcel);
                ws = wb.Worksheets["Hoja1"];

                System.Data.DataTable oDT = EjecutarQuery(fIni, fFin, modelo);
                List<NivelFinanciero> nivelFinanciero = CrearNiveles(oDT);
                LlenarNivelesExcel(ref ws, nivelFinanciero, 2, out int TotalFilas);
                LlenarSaldosExcel(oDT, ref ws, nivel, TotalFilas);
                LlenarFormulasSubtotales(ref ws);

                LLenarPorcentajes(ref ws, TotalFilas);
                FormatoCabecera(ref ws, "3");

                wb.SaveAs(ruta);
                mensaje = "Se finalizó la creación del Excel";
                return true;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                mensaje=ex.Message;
                return false;
            }
            finally
            {
                excel.Quit();
                Tools.LiberarExcel(ref wb, ref ws);
                Tools.LiberarObjeto(excel);
            }
        }

        private System.Data.DataTable EjecutarQuery(DateTime fIni, DateTime fFin, string modelo)
        {
            //string modelo = System.Configuration.ConfigurationManager.AppSettings["modelo"];
            string query = $"declare @fini datetime=convert(datetime,'{fIni.ToString("dd/MM/yyyy")}',103),@ffin datetime=convert(datetime,'{fFin.ToString("dd/MM/yyyy")}',103);" +
                           $"exec EXC_ANALISIS_ESTADO_RESULTADOS @fini,@ffin,{modelo},{NivelExcel}";

            //string connString = @"Server=LAP031;Database=SBO_BASE_PRUEBAS;User Id=sa;Password=B1admin;";
            cnString = cnString.Replace("{SBO_BD}", oCompany.CompanyDB);
            //logger.Debug(cnString);
            //logger.Debug(query);
            System.Data.DataTable oDT = new System.Data.DataTable();
            SqlConnection conn = new SqlConnection(cnString);
            SqlCommand cmd = new SqlCommand(query, conn);
            cmd.CommandTimeout = 0;
            conn.Open();
            SqlDataAdapter da = new SqlDataAdapter(cmd);
            da.Fill(oDT);
            conn.Close();
            da.Dispose();
            return oDT;
        }

        private int ObtenerMes(string nombre)
        {
            int mesnum = 0;
            switch (nombre)
            {
                case "ENERO":
                    return 1;
                case "FEBRERO":
                    return 2;
                case "MARZO":
                    return 3;
                case "ABRIL":
                    return 4;
                case "MAYO":
                    return 5;
                case "JUNIO":
                    return 6;
                case "JULIO":
                    return 7;
                case "AGOSTO":
                    return 8;
                case "SETIEMBRE":
                    return 9;
                case "OCTUBRE":
                    return 10;
                case "NOVIEMBRE":
                    return 11;
                case "DICIEMBRE":
                    return 12;
            }
            return mesnum;
        }

        private void LlenarSaldosExcel(System.Data.DataTable oDT, ref Worksheet ws, string nivel, int totalFilas)
        {
            int fila;
            int ncolumna = 2;

            Range range = null;
            var meses = (from row in oDT.AsEnumerable()
                         select row.Field<string>("mes")).Distinct();
            foreach (string mes in meses)
            {
                MesFinanciero mesFin = new MesFinanciero();
                mesFin.Mes = ObtenerMes(mes);
                ncolumna++;
                string colActual = Tools.ObtenerNombreColumna(ncolumna);
                fila = 1;
                range = ws.Cells[fila, colActual];
                range.Value = mes;
                var CC1s = (from row in oDT.AsEnumerable()
                            where row.Field<string>("mes") == mes
                            select row.Field<string>("NombreCC1")).Distinct();
                foreach (string cc1 in CC1s)
                {
#if !DEBUG
                    if (!ListaCC1.Contains(cc1)) continue;
#endif
                    try
                    {
                        var CC3s = (from row in oDT.AsEnumerable()
                                    where row.Field<string>("mes") == mes && row.Field<string>("NombreCC1") == cc1
                                    select row.Field<string>("NombreCC3")).Distinct();

                        if (!ValidarContenedor(ListaCC3, CC3s)) continue;
                        fila = 2;
                        colActual = Tools.ObtenerNombreColumna(ncolumna);
                        range = ws.Cells[fila, colActual];
                        range.Value = cc1;

                        ncolumna--;
                        foreach (string cc3 in CC3s)
                        {
#if !DEBUG
                            if (!ListaCC3.Contains(cc3)) continue;
#endif
                            fila = 3;
                            ncolumna++;
                            mesFin.ColumnasBase.Add(new KeyValuePair<int, string>(ncolumna, cc3));
                            colActual = Tools.ObtenerNombreColumna(ncolumna);
                            range = ws.Cells[fila, colActual];
                            range.Value = cc3;

                            LlenarSaldos(oDT, ref ws, colActual, nivel, new SaldoFinanciero { CC1 = cc1, CC3 = cc3, Mes = mes }, totalFilas);
                        }
                        ncolumna++;
                        colActual = Tools.ObtenerNombreColumna(ncolumna);
                        range = ws.Cells[fila, colActual];
                        range.Value = "TOTAL";
                        ColTotales.Add(ncolumna);
                        LlenarTotales(ref ws, ncolumna, CC3s.Count(), totalFilas, "3");
                        ncolumna++;
                    }
                    catch { }
                }
                fila = 2;
                colActual = Tools.ObtenerNombreColumna(ncolumna);
                range = ws.Cells[fila, colActual];
                range.Value = "TOTAL MES";
                var totales = (from row in oDT.AsEnumerable()
                               where row.Field<string>("mes") == mes
                               select row.Field<string>("NombreCC3")).Distinct();
                ncolumna--;
                foreach (string cc3 in totales)
                {
#if !DEBUG
                    if (!ListaCC3.Contains(cc3)) continue;
#endif
                    fila = 3;
                    ncolumna++;
                    mesFin.ColumnasTotales.Add(ncolumna);
                    colActual = Tools.ObtenerNombreColumna(ncolumna);
                    range = ws.Cells[fila, colActual];
                    range.Value = cc3;
                    string formula = ObtenerFormula(ref ws, mesFin, cc3);
                    //range = ws.Cells[fila+1, colActual];
                    LlenarTotalMes(ref ws, formula, colActual, totalFilas);
                }
                ncolumna++;
                colActual = Tools.ObtenerNombreColumna(ncolumna);
                range = ws.Cells[fila, colActual];
                range.Value = "TOTAL";
                string formuTot = ObtenerFormulaTotMes(mesFin.ColumnasTotales);
                LlenarTotalMes(ref ws, formuTot, colActual, totalFilas);
                mesesFinancieros.Add(mesFin);
            }
        }

        private bool ValidarContenedor(List<string> Lista, IEnumerable<string> CC)
        {
#if DEBUG
            return true;
#endif
            int conteo = 0;
            foreach (string cc in CC)
            {
                if (!Lista.Contains(cc)) continue;
                conteo++;
            }
            return conteo > 0;
        }

        private void LlenarTotalMes(ref Worksheet ws, string formula, string col, int totalFilas)
        {
            for (int fila = 4; fila <= totalFilas; fila++)
            {
                Range range = ws.Cells[fila, col];
                range.Value = Tools.NormalizarForRow(formula, fila);
            }
        }

        private List<string> ObtenerFormulas(ref Worksheet ws)
        {
            List<string> Formulas = new List<string>();
            foreach (MesFinanciero mesFin in mesesFinancieros)
            {
                foreach (int col in mesFin.ColumnasTotales)
                {
                    Range range = ws.Cells[3, col];
                    string valor = range.Value;

                    List<int> colBase = mesFin.ColumnasBase.Where(x => x.Value == valor)
                    .Select(x => x.Key)
                    .ToList();
                    List<string> coluBase = new List<string>();
                    colBase.ForEach(c => coluBase.Add(Tools.ObtenerNombreColumna(c)));

                    string formula = $"{string.Join("+", coluBase)}";
                    formula = "=+" + formula.Replace("+", "row+") + "row";
                    Formulas.Add(formula);
                }
            }
            return Formulas;
        }

        private string ObtenerFormula(ref Worksheet ws, MesFinanciero mesFin, string valor)
        {
            string Formulas = string.Empty;

            List<int> colBase = mesFin.ColumnasBase.Where(x => x.Value == valor)
            .Select(x => x.Key)
            .ToList();
            List<string> coluBase = new List<string>();
            if (colBase.Count == 0)
            {
                return "=0";
            }
            colBase.ForEach(c => coluBase.Add(Tools.ObtenerNombreColumna(c)));

            Formulas = $"{string.Join("+", coluBase)}";
            Formulas = "=+" + Formulas.Replace("+", "row+") + "row";

            return Formulas;
        }

        private string ObtenerFormulaTotMes(List<int> ColTotMes)
        {
            string Formulas = string.Empty;

            List<string> coluBase = new List<string>();
            ColTotMes.ForEach(c => coluBase.Add(Tools.ObtenerNombreColumna(c)));

            Formulas = $"{string.Join("+", coluBase)}";
            Formulas = "=+" + Formulas.Replace("+", "row+") + "row";

            return Formulas;
        }

        private void LlenarSaldos(System.Data.DataTable oDT, ref Worksheet ws, string columna, string nivel, SaldoFinanciero saldoFin, int totalFilas)
        {
            string niv1 = string.Empty;
            string niv2 = string.Empty;
            string niv3 = string.Empty;
            string niv4 = string.Empty;
            for (int fila = 1; fila <= totalFilas; fila++)
            {
                Range rangeNivel = ws.Cells[fila, "A"];
                if (rangeNivel.Value == null) continue;
                string niv = rangeNivel.Value.ToString();
                Range range = ws.Cells[fila, "B"];
                if (niv == "1")
                {
                    niv1 = ((string)range.Value).Trim();
                }
                else if (niv == "2")
                {
                    niv2 = ((string)range.Value).Trim();
                }
                else if (niv == "3")
                {
                    niv3 = ((string)range.Value).Trim();
                }
                else if (niv == "4")
                {
                    niv4 = ((string)range.Value).Trim();
                }

                if (nivel.Equals(niv))
                {
                    string nombreNivel = range.Value;
                    string selectQ = string.Empty;
                    switch (nivel)
                    {
                        case "1":
                            selectQ = $"NombreCC1='{saldoFin.CC1}' and NombreCC3='{saldoFin.CC3}' and mes='{saldoFin.Mes}' and NombreNiv1='{niv1.Trim()}'";
                            break;
                        case "2":
                            selectQ = $"NombreCC1='{saldoFin.CC1}' and NombreCC3='{saldoFin.CC3}' and mes='{saldoFin.Mes}' and NombreNiv1='{niv1.Trim()}' and NombreNiv2='{niv2.Trim()}'";
                            break;
                        case "3":
                            selectQ = $"NombreCC1='{saldoFin.CC1}' and NombreCC3='{saldoFin.CC3}' and mes='{saldoFin.Mes}' and NombreNiv1='{niv1.Trim()}' and NombreNiv2='{niv2.Trim()}' and NombreNiv3='{niv3.Trim()}'";
                            break;
                        case "4":
                            selectQ = $"NombreCC1='{saldoFin.CC1}' and NombreCC3='{saldoFin.CC3}' and mes='{saldoFin.Mes}' and NombreNiv1='{niv1.Trim()}' and NombreNiv2='{niv2.Trim()}' and NombreNiv3='{niv3.Trim()}' and NombreNiv4='{niv4.Trim()}'";
                            break;
                        case "5":
                            selectQ = $"NombreCC1='{saldoFin.CC1}' and NombreCC3='{saldoFin.CC3}' and mes='{saldoFin.Mes}' and NombreNiv1='{niv1.Trim()}' and NombreNiv2='{niv2.Trim()}' and NombreNiv3='{niv3.Trim()}' and NombreNiv4='{niv4.Trim()}' and acctname='{nombreNivel.Trim()}'";
                            break;
                    }
                    DataRow[] saldos = oDT.Select(selectQ);
                    range = ws.Cells[fila, columna];
                    if (saldos.Length > 0)
                        range.Value = saldos[0]["saldo"].ToString();
                    else
                        range.Value = 0;
                }
            }
        }

        private void LlenarTotales(ref Worksheet ws, int columna, int totCol, int totFil, string CC)
        {
            Range range = null;
            ListaTotales.Add(columna);
            int cIni = columna - totCol < 3 ? 3 : columna - totCol;
            string column = Tools.ObtenerNombreColumna(columna);
            string colIni = Tools.ObtenerNombreColumna(cIni);
            string colfin = Tools.ObtenerNombreColumna(columna - 1);
            for (int i = int.Parse(CC) + 1; i <= totFil; i++)
            {
                range = ws.Cells[i, column];
                range.Value = $"=SUM({colIni}{i}:{colfin}{i})";
            }
            Tools.LiberarObjeto(range);
        }

        private void LlenarFormulasSubtotales(ref Worksheet ws)
        {
            int ultCol = Tools.ObtenerUltimaColumna(ws);
            //int ultFila = Tools.ObtenerUltimaFila(ws);
            int columna = 3;
            if (NivelExcel >= 2)
            {
                foreach (KeyValuePair<int, string> formu1 in FormulasNiv1)
                {
                    for (int i = columna; i <= ultCol; i++)
                    {
                        if (ListaTotales.Contains(i)) continue;
                        string col = Tools.ObtenerNombreColumna(i);
                        Range range = ws.Cells[formu1.Key, col];
                        range.Value = Tools.NormalizarForCol(formu1.Value, col);
                    }
                }
            }
            if (NivelExcel >= 3)
            {
                foreach (KeyValuePair<int, string> formu2 in FormulasNiv2)
                {
                    for (int i = columna; i <= ultCol; i++)
                    {
                        if (ListaTotales.Contains(i)) continue;
                        string col = Tools.ObtenerNombreColumna(i);
                        Range range = ws.Cells[formu2.Key, col];
                        range.Value = Tools.NormalizarForCol(formu2.Value, col);
                    }
                }
            }
            if (NivelExcel >= 4)
            {
                foreach (KeyValuePair<int, string> formu3 in FormulasNiv3)
                {
                    for (int i = columna; i <= ultCol; i++)
                    {
                        if (ListaTotales.Contains(i)) continue;
                        string col = Tools.ObtenerNombreColumna(i);
                        Range range = ws.Cells[formu3.Key, col];
                        range.Value = Tools.NormalizarForCol(formu3.Value, col);
                    }
                }
            }
            if (NivelExcel == 5)
            {
                foreach (KeyValuePair<int, string> formu4 in FormulasNiv4)
                {
                    for (int i = columna; i <= ultCol; i++)
                    {
                        if (ListaTotales.Contains(i)) continue;
                        string col = Tools.ObtenerNombreColumna(i);
                        Range range = ws.Cells[formu4.Key, col];
                        range.Value = Tools.NormalizarForCol(formu4.Value, col);
                    }
                }
            }
        }

        private void LLenarPorcentajes(ref Worksheet ws, int TotalFilas)
        {
            //int columna = 3;
            //int ultCol = Tools.ObtenerUltimaColumna(ws);
            /*
             oRng.EntireColumn.Insert(Excel.XlInsertShiftDirection.xlShiftToRight, 
                    Excel.XlInsertFormatOrigin.xlFormatFromRightOrBelow);
             */
            int agregado = 0;
            for (int i = 0; i < ListaTotales.Count; i++)
            {
                int col = ListaTotales[i] + agregado + 1;
                string colname = Tools.ObtenerNombreColumna(col);
                Range range = ws.Range[$"{colname}1"];
                range.EntireColumn.Insert(XlInsertShiftDirection.xlShiftToRight,
                    XlInsertFormatOrigin.xlFormatFromRightOrBelow);
                range = ws.Range[colname + "3"];
                range.Value = "%";
                range = ws.Range[$"{colname}1"];
                range.EntireColumn.NumberFormat = "0.00%";
                LlenarFormulaPorcentajes(ref ws, col, TotalFilas);
                agregado++;
            }
            int ultCol = Tools.ObtenerUltimaColumna(ws);
            Range rangeFinal = ws.Range[Tools.ObtenerNombreColumna(ultCol + 1) + "3"];
            rangeFinal.Value = "%";
            rangeFinal.EntireColumn.NumberFormat = "0.00%";
            LlenarFormulaPorcentajes(ref ws, ultCol + 1, TotalFilas);
        }

        private void LlenarFormulaPorcentajes(ref Worksheet ws, int col, int totalFilas)
        {
            //string nivelPrincipal = "2";
            int niv1 = 0;
            //int niv2 = 0;
            //int niv3 = 0;
            //int niv4 = 0;
            string colname = Tools.ObtenerNombreColumna(col);
            for (int fila = 4; fila <= totalFilas; fila++)
            {
                Range rangeNivel = ws.Cells[fila, "A"];
                if (rangeNivel.Value == null) continue;
                Range rango = ws.Cells[fila, colname];
                string niv = rangeNivel.Value.ToString();
                string colAnt = Tools.ObtenerNombreColumna(col - 1);
                switch (niv)
                {
                    case "1":
                        rango.Value = "=1";
                        niv1 = fila;
                        break;
                    default:
                        rango.Value = $"=IFERROR(ABS({colAnt}{fila}/{colAnt}{niv1}),0)";
                        break;
                        /*case "2":
                            //rango.Value = "=1";
                            //niv2 = fila;
                            rango.Value = $"=IFERROR({colAnt}{fila}/{colAnt}{niv1},0)";
                            niv2 = fila;
                            break;
                        case "3":
                            rango.Value = $"=IFERROR({colAnt}{fila}/{colAnt}{niv2},0)";
                            niv3 = fila;
                            break;
                        case "4":
                            rango.Value = $"=IFERROR({colAnt}{fila}/{colAnt}{niv3},0)";
                            niv4 = fila;
                            break;
                        case "5":
                            rango.Value = $"=IFERROR({colAnt}{fila}/{colAnt}{niv4},0)";
                            break;*/
                }
            }
        }

        private void FormatoCabecera(ref Worksheet ws, string CC)
        {
            int ultCol = Tools.ObtenerUltimaColumna(ws);

            int anterior = 3;

            for (int i = 4; i <= ultCol; i++)
            {
                Range range = ws.Cells[1, Tools.ObtenerNombreColumna(i)];
                if (range.Value == null) continue;
                range = ws.Range[ws.Cells[1, anterior], ws.Cells[1, i - 1]];
                range.Merge();
                range.HorizontalAlignment = XlHAlign.xlHAlignCenter;
                anterior = i;
            }
            ws.Range[ws.Cells[1, anterior], ws.Cells[1, ultCol]].Merge();
            ws.Range[ws.Cells[1, anterior], ws.Cells[1, ultCol]].HorizontalAlignment = XlHAlign.xlHAlignCenter;

            anterior = 3;
            for (int i = 4; i <= ultCol; i++)
            {
                Range range = ws.Cells[2, Tools.ObtenerNombreColumna(i)];
                if (range.Value == null) continue;
                range = ws.Range[ws.Cells[2, anterior], ws.Cells[2, i - 1]];
                range.Merge();
                range.HorizontalAlignment = XlHAlign.xlHAlignCenter;
                anterior = i;
            }
            ws.Range[ws.Cells[2, anterior], ws.Cells[2, ultCol]].Merge();
            ws.Range[ws.Cells[2, anterior], ws.Cells[2, ultCol]].HorizontalAlignment = XlHAlign.xlHAlignCenter;
            //eWSheet.Range[eWSheet.Cells[1, 1], eWSheet.Cells[4, 1]].Merge();
            Range rangeCab = ws.Range["C1:" + Tools.ObtenerNombreColumna(ultCol) + "3"];
            Borders border = rangeCab.Borders;
            border[XlBordersIndex.xlEdgeLeft].LineStyle =
                Microsoft.Office.Interop.Excel.XlLineStyle.xlContinuous;
            border[XlBordersIndex.xlEdgeTop].LineStyle =
                Microsoft.Office.Interop.Excel.XlLineStyle.xlContinuous;
            border[XlBordersIndex.xlEdgeBottom].LineStyle =
                Microsoft.Office.Interop.Excel.XlLineStyle.xlContinuous;
            border[XlBordersIndex.xlEdgeRight].LineStyle =
                Microsoft.Office.Interop.Excel.XlLineStyle.xlContinuous;
            border[XlBordersIndex.xlInsideHorizontal].LineStyle =
                Microsoft.Office.Interop.Excel.XlLineStyle.xlContinuous;
            border[XlBordersIndex.xlInsideVertical].LineStyle =
                Microsoft.Office.Interop.Excel.XlLineStyle.xlContinuous;
            ws.get_Range("C:" + Tools.ObtenerNombreColumna(ultCol)).EntireColumn.AutoFit();
        }

        private void LlenarNivelesExcel(ref Worksheet ws, List<NivelFinanciero> niveles, int numCC, out int filas)
        {
            int fila = numCC + 1;
            Range range = null;
            Range rangeIndex = null;
            string columna = "B";
            string colIndex = "A";
            int filaIni1 = 0;
            int filaIni2 = 0;
            int filaIni3 = 0;
            int filaIni4 = 0;
            List<int> filasNiv2 = new List<int>();
            List<int> filasNiv3 = new List<int>();
            List<int> filasNiv4 = new List<int>();
            List<int> filasDet = new List<int>();
            foreach (NivelFinanciero niv1 in niveles)
            {
                filasNiv2 = new List<int>();
                fila++;
                range = ws.Range[$"{columna}{fila}:ZZ{fila}"];
                range.Font.Bold = true;
                range.Font.Color = 0xFF0000;
                range = ws.Cells[fila, columna];
                range.Value = niv1.Nombre;
                rangeIndex = ws.Cells[fila, colIndex];
                rangeIndex.Value = "1";
                filaIni1 = fila;
                foreach (Nivel2 niv2 in niv1.SubNiveles)
                {
                    fila++;
                    filasNiv2.Add(fila);
                    filasNiv3 = new List<int>();
                    range = ws.Range[$"{columna}{fila}:ZZ{fila}"];
                    range.Font.Bold = true;
                    range.Font.Color = 0xFF0000;
                    range = ws.Cells[fila, columna];
                    range.Value = Tools.TabularTexto(niv2.Nombre, 1);
                    rangeIndex = ws.Cells[fila, colIndex];
                    rangeIndex.Value = "2";
                    filaIni2 = fila;
                    foreach (Nivel3 niv3 in niv2.SubNiveles)
                    {
                        fila++;
                        filasNiv3.Add(fila);
                        filasNiv4 = new List<int>();
                        filasDet = new List<int>();
                        ws.Range[$"{columna}{fila}:ZZ{fila}"].Font.Bold = true;
                        range = ws.Cells[fila, columna];
                        range.Value = Tools.TabularTexto(niv3.Nombre, 2);
                        rangeIndex = ws.Cells[fila, colIndex];
                        rangeIndex.Value = "3";
                        filaIni3 = fila;
                        foreach (Nivel4 niv4 in niv3.SubNiveles)
                        {
                            fila++;
                            range = ws.Cells[fila, columna];
                            range.Value = Tools.TabularTexto(niv4.Nombre, 3);
                            rangeIndex = ws.Cells[fila, colIndex];
                            rangeIndex.Value = "4";
                            if (NivelExcel == 4)
                            {
                                filasDet.Add(fila);
                            }
                            else
                            {
                                filasNiv4.Add(fila);
                                filasDet = new List<int>();
                                ws.Range[$"{columna}{fila}:ZZ{fila}"].Font.Bold = true;
                                filaIni4 = fila;
                                foreach (Nivel5 niv5 in niv4.SubNiveles)
                                {
                                    fila++;
                                    range = ws.Cells[fila, columna];
                                    range.Value = Tools.TabularTexto(niv5.Nombre, 4);
                                    rangeIndex = ws.Cells[fila, colIndex];
                                    rangeIndex.Value = "5";
                                    filasDet.Add(fila);
                                }
                                FormulasNiv4.Add(filaIni4, $"=+col{string.Join("+col", filasDet)}");
                            }
                        }
                        if (NivelExcel == 4)
                        {
                            FormulasNiv3.Add(filaIni3, $"=+col{string.Join("+col", filasDet)}");
                        }
                        else
                        {
                            FormulasNiv3.Add(filaIni3, $"=+col{string.Join("+col", filasNiv4)}");
                        }
                    }
                    FormulasNiv2.Add(filaIni2, $"=+col{string.Join("+col", filasNiv3)}");
                }
                FormulasNiv1.Add(filaIni1, $"=+col{string.Join("+col", filasNiv2)}");
            }
            range = ws.Range[$"={colIndex}1:{colIndex}{fila}"];
            range.EntireColumn.Hidden = true;
            filas = fila;
            Tools.LiberarObjeto(range);
            Tools.LiberarObjeto(rangeIndex);
        }

        private List<NivelFinanciero> CrearNiveles(System.Data.DataTable oDT)
        {
            List<NivelFinanciero> Niveles = new List<NivelFinanciero>();
            var niveles1 = oDT.DefaultView.ToTable(true, "NombreNiv1").Rows.Cast<DataRow>().Select(row => row["NombreNiv1"]).ToList();
            foreach (var nivel1 in niveles1)
            {
                NivelFinanciero nivelFinanciero = new NivelFinanciero();
                //var niveles2 = oDT.DefaultView.ToTable(true, "NombreNiv2").Rows.Cast<DataRow>().Select(row => row["NombreNiv2"]).ToList();
                nivelFinanciero.Nombre = nivel1.ToString();
                if (NivelExcel >= 2)
                {
                    var niveles2 = (from row in oDT.AsEnumerable()
                                    where row.Field<string>("NombreNiv1") == nivelFinanciero.Nombre
                                    select row.Field<string>("NombreNiv2")).Distinct();
                    foreach (var nivel2 in niveles2)
                    {
                        Nivel2 niv2 = new Nivel2();
                        niv2.Nombre = nivel2.ToString();
                        if (NivelExcel >= 3)
                        //var niveles3 =  oDT.Select($"NombreNiv2='{niv2.Nombre}'");
                        //var niveles3 = oDT.DefaultView.ToTable(true, new string[] { "NombreNiv2", "NombreNiv3" }).Rows.Cast<DataRow>().Select(row => row["NombreNiv3"]).ToList();
                        {
                            var niveles3 = (from row in oDT.AsEnumerable()
                                            where row.Field<string>("NombreNiv2") == niv2.Nombre
                                            select row.Field<string>("NombreNiv3")).Distinct();
                            foreach (string nivel3 in niveles3)
                            {
                                Nivel3 niv3 = new Nivel3();
                                niv3.Nombre = nivel3;
                                if (NivelExcel >= 4)
                                {
                                    var niveles4 = (from row in oDT.AsEnumerable()
                                                    where row.Field<string>("NombreNiv3") == niv3.Nombre
                                                    select row.Field<string>("NombreNiv4")).Distinct();
                                    foreach (string nivel4 in niveles4)
                                    {
                                        Nivel4 niv4 = new Nivel4();
                                        niv4.Nombre = nivel4;
                                        if (NivelExcel == 5)
                                        {
                                            var niveles5 = (from row in oDT.AsEnumerable()
                                                            where row.Field<string>("NombreNiv4") == niv4.Nombre
                                                            select row.Field<string>("acctname")).Distinct();
                                            foreach (string nivel5 in niveles5)
                                            {
                                                Nivel5 niv5 = new Nivel5();
                                                niv5.Nombre = nivel5;
                                                niv4.SubNiveles.Add(niv5);
                                            }
                                        }
                                        niv3.SubNiveles.Add(niv4);
                                    }
                                }
                                niv2.SubNiveles.Add(niv3);
                            }
                        }
                        nivelFinanciero.SubNiveles.Add(niv2);
                    }
                }
                Niveles.Add(nivelFinanciero);
            }
            //var nivel4 = oDT.DefaultView.ToTable(true, "NombreNiv4").Rows.Cast<DataRow>().Select(row => row["NombreNiv4"]).ToList();
            return Niveles;
        }
    }
}