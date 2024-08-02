using SAPbouiCOM;

namespace Reportes.Events.ItemEvent
{
    public interface IObjectItemEvent
    {
        void ItemEventAction(string FormUID, ref SAPbouiCOM.ItemEvent temEvent, out bool BubbleEvent);
    }
}
