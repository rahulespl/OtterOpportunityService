/*******************************************************************************************************
 * @description       : Handler class for Leads trigger
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
public with sharing class LeadTriggerHandler {
    public static void existingAccountsCheck(List<Lead> newLeadsLst) {
        List<Object> duplicateResult = DuplicateService.dupeCheckCorrespondingSobject(Account.SobjectType, Lead.SobjectType, newLeadsLst, false);
        if(duplicateResult != null && duplicateResult.size() == newLeadsLst.size()) {
            for(Integer index=0; index < newLeadsLst.size(); index++) {
                if(duplicateResult[index] == true) {
                    newLeadsLst[index].addError(Label.Lead_Trigger_Matching_Account_Exists);
                }
            }
        }
    }
    public static void existingLeadsCheck(List<Lead> newLeadsLst) {
        List<Object> duplicateResult = DuplicateService.dupeCheckCorrespondingSobject(Lead.SobjectType, Lead.SobjectType, newLeadsLst, false);
        if(duplicateResult != null && duplicateResult.size() == newLeadsLst.size()) {
            for(Integer index=0; index < newLeadsLst.size(); index++) {
                if(duplicateResult[index] == true) {
                    newLeadsLst[index].addError(Label.Lead_Trigger_Matching_Lead_Exists);
                }
            }
        }
    }
}