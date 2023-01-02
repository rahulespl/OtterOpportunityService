/*******************************************************************************************************
 * @description       : Account trigger
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
trigger AccountTrigger on Account (before insert) {
    if(Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.existingLeadsCheck(Trigger.new);
        AccountTriggerHandler.existingAccountsCheck(Trigger.new);
    }
}