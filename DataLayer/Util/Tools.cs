using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataLayer.Util
{
    class Tools
    {
        public static string ObtenerNombreColumna(int columnNumber)
        {
            int dividend = columnNumber;
            string columnName = string.Empty;
            int modulo;

            while (dividend > 0)
            {
                modulo = (dividend - 1) % 26;
                columnName = Convert.ToChar(65 + modulo).ToString() + columnName;
                dividend = (int)((dividend - modulo) / 26);
            }

            return columnName;
        }

        public static int ObtenerUltimaColumna(Microsoft.Office.Interop.Excel.Worksheet ws)
        {
            int nInLastCol = ws.Cells.Find("*", System.Reflection.Missing.Value,
            System.Reflection.Missing.Value, System.Reflection.Missing.Value, Microsoft.Office.Interop.Excel.XlSearchOrder.xlByColumns, Microsoft.Office.Interop.Excel.XlSearchDirection.xlPrevious, false, System.Reflection.Missing.Value, System.Reflection.Missing.Value).Column;

            return nInLastCol;
        }

        public static int ObtenerUltimaFila(Microsoft.Office.Interop.Excel.Worksheet ws)
        {
            int nInLastRow = ws.Cells.Find("*", System.Reflection.Missing.Value,
            System.Reflection.Missing.Value, System.Reflection.Missing.Value, Microsoft.Office.Interop.Excel.XlSearchOrder.xlByRows, Microsoft.Office.Interop.Excel.XlSearchDirection.xlPrevious, false, System.Reflection.Missing.Value, System.Reflection.Missing.Value).Row;

            return nInLastRow;
        }

        public static void LiberarObjeto(object objeto)
        {
            try
            {
                if (objeto != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(objeto);
            }
            catch { }
            try
            {
                objeto = null;
            }
            catch { }
            GC.WaitForPendingFinalizers();
            GC.Collect();
        }

        public static string TabularTexto(string texto, int numTab)
        {
            string tabs = new string(' ', numTab * 5);
            return tabs + texto;
        }

        public static void LiberarExcel(ref Microsoft.Office.Interop.Excel.Workbook wb, ref Microsoft.Office.Interop.Excel.Worksheet ws)
        {
            try
            {
                if (ws != null)
                {
                    System.Runtime.InteropServices.Marshal.ReleaseComObject(ws);
                    ws = null;
                }
                if (wb != null)
                {
                    wb.Close(0);
                    System.Runtime.InteropServices.Marshal.ReleaseComObject(wb);
                    wb = null;
                }
                GC.Collect();
            }
            catch { }
        }

        public static string NormalizarForCol(string formula, string columna)
        {
            return formula.Replace("col", columna);
        }

        public static string NormalizarForRow(string formula, int fila)
        {
            return formula.Replace("row", fila.ToString());
        }
    }
}
