/*******************************************************************************************************
 * @description       : Lead trigger
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
trigger LeadTrigger on Lead (before insert) {
    
    if(Trigger.isBefore && Trigger.isInsert) {
        LeadTriggerHandler.existingAccountsCheck(Trigger.new);
        LeadTriggerHandler.existingLeadsCheck(Trigger.new);
    }
}