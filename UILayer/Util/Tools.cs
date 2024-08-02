using System;

namespace Reportes.Util
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
