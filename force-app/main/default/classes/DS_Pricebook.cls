/*******************************************************************************************************
 * @description       : Data accessor class for Pricebook
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
public with sharing class DS_Pricebook {
    private static Pricebook2 stdPriceBook;
    @testVisible
    private static Boolean Get_Custom_PB = false;
    public static Id getStdPricebookId() {
        if (Test.isRunningTest() && !DS_Pricebook.Get_Custom_PB) {
            return Test.getStandardPricebookId();
        }
        else {
            if(getStdPricebook() != null) {
                return getStdPricebook().id;
            }
        }
        return null;
        
    }
    public static Pricebook2 getStdPriceBook () {
        if (stdPriceBook == null && !DS_Pricebook.Get_Custom_PB) {
            stdPriceBook    = [SELECT id, name FROM Pricebook2 WHERE isStandard = true limit 1];
        }
        return stdPriceBook;
    }
}