using SAPbouiCOM;

namespace Reportes.Events.FormDataEvent
{
    public interface IObjectFormDataEvent
    {
        void DataFormAction(ref BusinessObjectInfo BusinessObjectInfo, out bool BubbleEvent);
    }
}