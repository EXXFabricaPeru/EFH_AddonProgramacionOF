using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataLayer.Entidades
{
    class MesFinanciero
    {
        public int Mes { get; set; }
        public IDictionary<int, string> ColumnasBase { get; set; } = new Dictionary<int, string>();
        public List<int> ColumnasTotales { get; set; } = new List<int>();
    }
}
