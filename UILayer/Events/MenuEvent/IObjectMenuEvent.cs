namespace Reportes.Events.MenuEvent
{
    public interface IObjectMenuEvent
    {
        void MenuEventAction(ref SAPbouiCOM.MenuEvent pVal, out bool BubbleEvent);
    }
}
