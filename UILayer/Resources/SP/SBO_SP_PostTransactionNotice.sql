
//solo agregar la línea al posttransaction 
if (:object_type = '202'  AND :transaction_type = 'A') THEN
CALL "SBO_EXP_PTN_OBJ202_OWOR_ADDON" (:list_of_cols_val_tab_del, :transaction_type, :error, :error_message);
End IF;