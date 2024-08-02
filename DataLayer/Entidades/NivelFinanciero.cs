using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataLayer.Entidades
{
    class NivelFinanciero
    {
        public string Nombre { get; set; }
        public List<Nivel2> SubNiveles { get; set; } = new List<Nivel2>();
    }

    class Nivel2
    {
        public string Nombre { get; set; }
        public List<Nivel3> SubNiveles { get; set; } = new List<Nivel3>();
    }
    class Nivel3
    {
        public string Nombre { get; set; }
        public List<Nivel4> SubNiveles { get; set; } = new List<Nivel4>();
    }

    class Nivel4
    {
        public string Nombre { get; set; }
        public List<Nivel5> SubNiveles { get; set; } = new List<Nivel5>();
    }
    class Nivel5
    {
        public string Nombre { get; set; }
    }
    class SaldoFinanciero
    {
        public string CC1 { get; set; }
        public string CC2 { get; set; }
        public string CC3 { get; set; }
        public string Mes { get; set; }
    }
}
