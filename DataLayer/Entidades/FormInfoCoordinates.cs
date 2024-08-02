using System;

namespace DataLayer.Entidades
{
    public class FormItemCoordinates
    {
        public string FormUID { get; set; }
        public string FormType { get; set; }
        public string ItemUID { get; set; }
        public int Row { get; set; }
        public string ColUID { get; set; }
        public override string ToString()
        {
            return $"FormUID = {FormUID}, FormType = {FormType}, ItemUID = {ItemUID}, Row = {Row}, ColUID = {ColUID}";
        }
    }
}
