/*******************************************************************************************************
 * @description       : Handler class for Account trigger
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
public with sharing class AccountTriggerHandler {
    public static Boolean bypassForLeadConversionThroughApi = false;
    public static void existingLeadsCheck(List<Account> newAccountsLst) {
        List<Object> duplicateResult = DuplicateService.dupeCheckCorrespondingSobject(Lead.SobjectType, Account.SobjectType, newAccountsLst, false);
        if(duplicateResult != null && duplicateResult.size() == newAccountsLst.size()) {
            for(Integer index=0; index < newAccountsLst.size(); index++) {
                if(duplicateResult[index] == true) {
                    newAccountsLst[index].addError(Label.Account_Trigger_Matching_Lead_Exists);
                }
            }
        }
    }
    public static void existingAccountsCheck(List<Account> newAccountsLst) {
        List<Object> duplicateResult = DuplicateService.dupeCheckCorrespondingSobject(Account.SobjectType, Account.SobjectType, newAccountsLst, false);
        if(duplicateResult != null && duplicateResult.size() == newAccountsLst.size()) {
            for(Integer index=0; index < newAccountsLst.size(); index++) {
                if(duplicateResult[index] == true) {
                    newAccountsLst[index].addError(Label.Account_Trigger_Matching_Account_Exists);
                }
            }
        }
    }
    
}