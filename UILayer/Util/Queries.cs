using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Reportes.Util
{
    class Queries
    {
        #region _Attributes_
        private static StringBuilder m_sSQL = new StringBuilder();
        #endregion

        #region _Functions_
        public static string GetHoraDefault()
        {
            m_sSQL.Length = 0;
            m_sSQL.Append("SELECT \"Phone2\" FROM OADM");
            return m_sSQL.ToString();
        }
        public static string ListaOrdenesProgramacion(SAPbobsCOM.BoDataServerTypes bo_ServerTypes,
            string fechaIni, string fechaFin, string order, string orderentry, string visual, string recurso, string razsocial )
        {
            m_sSQL.Length = 0;
            switch (bo_ServerTypes)
            {
                case SAPbobsCOM.BoDataServerTypes.dst_HANADB:
                    m_sSQL.Append($@"call ""EXX_ListaOrdenesProgramacion"" ('{fechaIni}','{fechaFin}','{order}',{orderentry},'{visual}', '{recurso}', '{razsocial}')");
                    break;
                default:
                    m_sSQL.Append($"exec EXX_ListaOrdenesProgramacion '{fechaIni}','{fechaFin}','{order}',{orderentry},'{visual}', '{recurso}', '{razsocial}'");
                    break;
            }
            return m_sSQL.ToString();
        }
        public static string ValidarStage(SAPbobsCOM.BoDataServerTypes bo_ServerTypes, int docentry, int stageId)
        {
            m_sSQL.Length = 0;
            switch (bo_ServerTypes)
            {
                case SAPbobsCOM.BoDataServerTypes.dst_HANADB:
                    m_sSQL.Append($@"call ""EXX_ValidarStage"" ({docentry},{stageId})");
                    break;
                default:
                    m_sSQL.Append($"exec EXX_ValidarStage {docentry},{stageId}");
                    break;
            }
            return m_sSQL.ToString();
        }
        #endregion
    }
}
