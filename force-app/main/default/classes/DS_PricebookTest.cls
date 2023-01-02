/*******************************************************************************************************
 * @description       : Test class for DS_Pricebook
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
@isTest
public class DS_PricebookTest {
    @testSetup static void setup() {
        Pricebook2 pbTest = new Pricebook2(Name = 'pbTest', Description = 'pbTest', IsActive = true);
        insert pbTest;
    }
    @isTest static void testGetCustomPriceBookId() {
        DS_Pricebook.Get_Custom_PB = true;
        Pricebook2 pbTest = [SELECT Id,Name FROM Pricebook2 WHERE Name = 'pbTest'];
        Id customPBId = DS_Pricebook.getStdPricebookId();
        System.assertEquals(null,customPBId);
    }
    @isTest static void testGetStdPriceBookId() {
        Id stdPBId = DS_Pricebook.getStdPricebookId();
        System.assertEquals(stdPBId, Test.getStandardPricebookId());
    }
}