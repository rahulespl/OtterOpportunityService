/*******************************************************************************************************
 * @description       : Handler class to handle inbound API requests from NewOpportunityRequest
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
public with sharing class NewOpportunityRequestHandler {
    @TestVisible
    private static Integer causeAccountCreationExceptionForIndex;
    @TestVisible
    private static Integer causeContactCreationExceptionForIndex;
    @TestVisible
    private static Integer causeOpportunityCreationExceptionForIndex;
    @TestVisible
    private static Integer causeOpportunityLineItemCreationExceptionForIndex;

    //can be moved to DuplicateService class
    public static List<SObject> formSobjects(Map<Integer,Object> indexToRequestsToProcess, Map<Integer,SObject> indexToParentRecordMap,
        String relationshipFld, List<Integer> indexesForFurtherProcessing,
        Map<Integer,SObject> indexToSobjectMap, Map<Integer,List<Sobject>> mapIndexToNewSobjectsToDelete, SobjectType sobjectTyp) {
        List<SObject> sobjectsFormedFromRequest = new List<SObject>();
        String sobjName = sobjectTyp.getDescribe().getLocalName();
        Map<String,Schema.SObjectField> fldMap = Schema.getGlobalDescribe().get(sobjName).getDescribe().fields.getMap();
        List<OpportunityManagementApiJsonMapping__mdt> fieldMappings = [SELECT Is_Active__c,
                                                                               Json_Key__c,
                                                                               Sobject_Field_Api_Name__c,
                                                                               Sobject_Name__c
                                                                        FROM OpportunityManagementApiJsonMapping__mdt
                                                                        WHERE Sobject_Name__c = :sobjName];
        if(fieldMappings.isEmpty() == false) {
            try {
                Map<String,Object> mapJsonData ;
                SObject sObj;
                Object req;
                for(Integer index : indexesForFurtherProcessing){
                //for(Integer index : indexToRequestsToProcess.keySet()) {
                    req = indexToRequestsToProcess.get(index);
                    sObj = sobjectTyp.newSObject();
                    mapJsonData = (Map<String,Object>)req;
                    Schema.DescribeFieldResult describeFldRes;
                    for(OpportunityManagementApiJsonMapping__mdt fldMapping : fieldMappings) {
                            if(mapJsonData.containsKey(fldMapping.Json_Key__c)) { //Can be made case insensitive
                                if(fldMap.containsKey(fldMapping.Sobject_Field_Api_Name__c) ){
                                    //Should be removed and taken care of in more generalised way
                                    if(sobjectTyp == OpportunityLineItem.SobjectType && fldMapping.Sobject_Field_Api_Name__c == Constants.FLD_PRODUCT2ID &&
                                        String.isNotBlank(String.valueOf(mapJsonData.get(fldMapping.Json_Key__c)))) {
                                        sObj.putSObject('Product2', new Product2(External_Id__c = String.valueOf(mapJsonData.get(fldMapping.Json_Key__c))));
                                    }
                                    else if(String.isNotBlank(String.valueOf(mapJsonData.get(fldMapping.Json_Key__c)))) {
                                        describeFldRes = fldMap.get(fldMapping.Sobject_Field_Api_Name__c).getDescribe();
                                        if(describeFldRes.isCreateable()) {
                                            //Other data types to be handled accordingly
                                            if(describeFldRes.getSOAPType() == Schema.SOAPType.String) {
                                                sObj.put(fldMapping.Sobject_Field_Api_Name__c, String.valueOf(mapJsonData.get(fldMapping.Json_Key__c)));
                                            }
                                            else if(describeFldRes.getSOAPType() == Schema.SOAPType.ID) {
                                                sObj.put(fldMapping.Sobject_Field_Api_Name__c, Id.valueOf(String.valueof(mapJsonData.get(fldMapping.Json_Key__c))));
                                            }
                                            else if(describeFldRes.getSOAPType() == Schema.SOAPType.Integer) {
                                                sObj.put(fldMapping.Sobject_Field_Api_Name__c, Integer.valueOf(mapJsonData.get(fldMapping.Json_Key__c)));
                                            }
                                            else if(describeFldRes.getSOAPType() == Schema.SOAPType.Double) {
                                                sObj.put(fldMapping.Sobject_Field_Api_Name__c, Double.valueOf(mapJsonData.get(fldMapping.Json_Key__c)));
                                            }
                                            else if(describeFldRes.getSOAPType() == Schema.SOAPType.DateTime) {
                                                sObj.put(fldMapping.Sobject_Field_Api_Name__c, DateTime.valueOf(mapJsonData.get(fldMapping.Json_Key__c)));
                                            }
                                            else if(describeFldRes.getSOAPType() == Schema.SOAPType.Date) {
                                                sObj.put(fldMapping.Sobject_Field_Api_Name__c, Date.valueOf(mapJsonData.get(fldMapping.Json_Key__c)));
                                            }
                                            else if(describeFldRes.getSOAPType() == Schema.SOAPType.Boolean) {
                                                sObj.put(fldMapping.Sobject_Field_Api_Name__c, Boolean.valueOf(mapJsonData.get(fldMapping.Json_Key__c)));
                                            }
                                        }
                                        else {
                                            throw new NewOpportunityRequestException('Field Mapping '+fldMapping.Json_Key__c+' not writable for the Object '+sobjName);
                                        }
                                    }
                                    
                                }
                                else {
                                    throw new NewOpportunityRequestException('Field Mapping '+fldMapping.Json_Key__c+' not configured Properly for the Object '+sobjName);
                                }
                            }
                        
                    }
                    sobjectsFormedFromRequest.add(sObj);
                    if(indexToSobjectMap != null) {
                        indexToSobjectMap.put(index,sObj);
                    }
                    if(mapIndexToNewSobjectsToDelete != null) {
                        if(mapIndexToNewSobjectsToDelete.containsKey(index)) {
                            mapIndexToNewSobjectsToDelete.get(index).add(sObj);
                        }
                        else {
                            mapIndexToNewSobjectsToDelete.put(index, new List<Sobject>{sObj});
                        }
                    }
                    if(indexToParentRecordMap != null && indexToParentRecordMap.containsKey(index)) {
                        sObj.put(relationshipFld,indexToParentRecordMap.get(index).Id);
                    }

                    //Should be removed and taken care of in more generalised way
                    if(sobjectTyp == Opportunity.SobjectType) {
                        sObj.put(Constants.FLD_STAGENAME, 'Closed Won'); // not to be hardcoded temporary
                        sObj.put(Constants.FLD_CLOSEDATE, Date.today()); // not to be hardcoded temporary
                        sObj.put(Constants.FLD_PRICEBOOK2ID, DS_Pricebook.getStdPricebookId());
                    }
                    system.debug('---------Pricebook2Id-----------'+DS_Pricebook.getStdPricebookId());
                    
                    //to handle negative scenarios for Opportunity in test class
                    if(Test.isRunningTest() && sobjectTyp == Opportunity.SobjectType
                        && NewOpportunityRequestHandler.causeOpportunityCreationExceptionForIndex != null &&
                            index == NewOpportunityRequestHandler.causeOpportunityCreationExceptionForIndex) {
                        sObj.put(Constants.FLD_CLOSEDATE, null); //So that it will fail with required field missing error
                    }

                    //to handle negative scenarios for Account in test class
                    if(Test.isRunningTest() && sobjectTyp == Account.SobjectType
                        && NewOpportunityRequestHandler.causeAccountCreationExceptionForIndex != null &&
                            index == NewOpportunityRequestHandler.causeAccountCreationExceptionForIndex) {
                        sObj.put(Constants.FLD_NAME, null); //So that it will fail with required field missing error
                    }

                    //to handle negative scenarios for Contact in test class
                    if(Test.isRunningTest() && sobjectTyp == Contact.SobjectType
                        && NewOpportunityRequestHandler.causeContactCreationExceptionForIndex != null &&
                            index == NewOpportunityRequestHandler.causeContactCreationExceptionForIndex) {
                        sObj.put(Constants.FLD_LASTNAME, null); //So that it will fail with required field missing error
                    }
                    
                }
                return sobjectsFormedFromRequest;
            }
            catch(NewOpportunityRequestException exp) {
                throw new NewOpportunityRequestException(exp.getMessage());
            }
            catch(Exception exp) {
                System.debug('-------EXCEPTION-----'+exp.getMessage());
                throw new NewOpportunityRequestException(Label.Generic_Opportunity_Processing_API_Error);
            }
        }
        else {
            throw new NewOpportunityRequestException(Label.Invalid_Json_Field_Mapping_Configuration + Constants.COLON +sobjName);
        }
        
    }


    public static void performDML(List<Integer> indexesForFurtherProcessing, Map<Integer,SObject> indexToSobjectsMap,
        Map<Integer,NewOpportunityRequestProcessResult> requestProcessedResult, Map<Integer,Object> indexToRequestsToProcess, String dmlType) {

        List<Sobject> newSobjectsToInsert = new List<Sobject>();
        List<Database.SaveResult> saveResLst;
        List<Integer> indexOfCorrespondingRequest = new List<Integer>();
        for(Integer index : indexesForFurtherProcessing) {
            if(indexToSobjectsMap.containsKey(index)) {
                newSobjectsToInsert.add(indexToSobjectsMap.get(index));
                indexOfCorrespondingRequest.add(index);
            }
        }
        if(dmlType == Constants.DML_INSERT) {
            saveResLst = Database.insert(newSobjectsToInsert,false);
        }
        else if(dmlType == Constants.DML_UPDATE) {
            saveResLst = Database.update(newSobjectsToInsert,false);
        }
        
        for(Integer index = 0; index < saveResLst.size(); index++) {
            if(saveResLst[index].isSuccess() == false) {
                requestProcessedResult.put(indexOfCorrespondingRequest[index],
                    new NewOpportunityRequestProcessResult(false, String.valueOf(saveResLst[index].getErrors())));
                indexToRequestsToProcess.remove(indexOfCorrespondingRequest[index]);
            }
            else {
                requestProcessedResult.put(indexOfCorrespondingRequest[index],
                    new NewOpportunityRequestProcessResult(true, null));
            }
        }
    }

    public static void performLeadConversion(Map<Integer,SObject> indexToLeadsMap, Map<Integer,NewOpportunityRequestProcessResult> requestProcessedResult,
        Map<Integer,Object> indexToRequestsToProcess, Map<Integer, Database.LeadConvertResult> mapIndexToLeadConvertResult,
        Map<Integer,List<Sobject>> mapIndexToNewSobjectsToDelete) {
        List<Lead> leadsToConvert = new List<Lead>();
        List<Integer> leadConversionIndexes = new List<Integer>();
        for(Integer index : indexToLeadsMap.keySet()) {
            if(indexToLeadsMap.get(index).Id != null) {
                leadsToConvert.add((Lead)indexToLeadsMap.get(index));
                leadConversionIndexes.add(index);
            }
        }
        if(leadsToConvert.isEmpty() == false) {
            Database.LeadConvert[] lcList = new List<Database.LeadConvert>();
            LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted=true limit 1];
            for(Lead leadObj : leadsToConvert){
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(leadObj.id);
                lc.setConvertedStatus(convertStatus.ApiName);
                lcList.add(lc);
            }
            Database.LeadConvertResult[] leadConversionResLst = Database.convertLead(lcList);
            Integer index = 0;
            List<Sobject> accConOppCreatedbecauseOfLeadConversion;
            for(Database.LeadConvertResult leadConversionRes: leadConversionResLst) {
                if(leadConversionRes.isSuccess()) {
                    requestProcessedResult.put(leadConversionIndexes[index],
                        new NewOpportunityRequestProcessResult(true, null));
                    mapIndexToLeadConvertResult.put(leadConversionIndexes[index], leadConversionRes);
                    accConOppCreatedbecauseOfLeadConversion = new List<Sobject>{
                        new Opportunity(Id=leadConversionRes.getOpportunityId()),
                        new Account(Id=leadConversionRes.getAccountId()),
                        new Contact(Id=leadConversionRes.getContactId())
                    };
                    if(mapIndexToNewSobjectsToDelete.containsKey(leadConversionIndexes[index])) {
                        mapIndexToNewSobjectsToDelete.get(leadConversionIndexes[index]).addAll(accConOppCreatedbecauseOfLeadConversion);
                    }
                    else {
                        mapIndexToNewSobjectsToDelete.put(leadConversionIndexes[index],accConOppCreatedbecauseOfLeadConversion);
                    }
                }
                else {
                    requestProcessedResult.put(leadConversionIndexes[index],
                        new NewOpportunityRequestProcessResult(false, String.valueOf(leadConversionRes.getErrors())));
                    indexToRequestsToProcess.remove(leadConversionIndexes[index]);
                }
                index++;
            }
        }
    }

    public static Map<Integer,NewOpportunityRequestProcessResult> processRequest(List<Object> lstRequestsToProcess) {
        Map<Integer,NewOpportunityRequestProcessResult> requestProcessedResult = new Map<Integer,NewOpportunityRequestProcessResult>();
        Map<Integer,Object> indexToRequestsToProcess = new Map<Integer,Object>();
        Map<Integer,List<Sobject>> mapIndexToNewSobjectsToDelete = new Map<Integer,List<Sobject>>();//to delete if transaction with index is unsuccessfull at any point of processing
        List<Integer> indexOfCorrespondingRequest = new List<Integer>();
        List<Database.SaveResult> saveResLst;
        List<Integer> indexesForFurtherProcessing = new List<Integer>();
        Map<Integer,Sobject> matchingRecordsToProcess = new Map<Integer,Sobject>();
        List<SObject> sobjDupeCheck;
        for(Integer index = 0; index < lstRequestsToProcess.size(); index++) {
            indexToRequestsToProcess.put(index,lstRequestsToProcess[index]);
            indexesForFurtherProcessing.add(index);
        }

        /********************************************************Duplicate Lead Check Start*******/
        //formed Lead Sobjects from payload request using configurable Json key-SF field mapping records
        sobjDupeCheck = NewOpportunityRequestHandler.formSobjects(indexToRequestsToProcess,null, null, indexesForFurtherProcessing,
            null, mapIndexToNewSobjectsToDelete,Lead.SobjectType);
        
        if(indexesForFurtherProcessing.isEmpty() == false) {
            //Checked for the existing duplicates for the formed Lead records
            NewOpportunityRequestHandler.dupeCheckProcess(indexesForFurtherProcessing, sobjDupeCheck, Lead.sobjectType,
            matchingRecordsToProcess, indexToRequestsToProcess);
        }
        
        indexesForFurtherProcessing = new List<Integer>(indexToRequestsToProcess.keySet());
        System.debug('-------LEAD CHECK-------matching Leads found??? matchingRecordsToProcess-----------'+matchingRecordsToProcess);
        System.debug('----LEAD CHECK-----indexesForFurtherProcessing--------'+indexesForFurtherProcessing);
        /********************************************************Duplicate Lead Check END*******/


        /********************************************************Duplicate Account Check Start*******/
        Map<Integer,SObject> indexToAccountsMap = new Map<Integer,SObject>();
        //formed Account Sobjects from payload request using configurable Json key-SF field mapping records
        sobjDupeCheck = NewOpportunityRequestHandler.formSobjects(indexToRequestsToProcess, null, null, indexesForFurtherProcessing,
            indexToAccountsMap,mapIndexToNewSobjectsToDelete,Account.SobjectType);

        if(indexesForFurtherProcessing.isEmpty() == false) {
            //Checked for the existing duplicates for the formed Account records
            NewOpportunityRequestHandler.dupeCheckProcess(indexesForFurtherProcessing, sobjDupeCheck, Account.sobjectType,
            matchingRecordsToProcess, indexToRequestsToProcess);
        }
        indexesForFurtherProcessing = new List<Integer>(indexToRequestsToProcess.keySet());

        System.debug('-------Accounts CHECK-------matching Accounts found??? matchingRecordsToProcess-----------'+matchingRecordsToProcess);
        System.debug('----Accounts CHECK-----indexesForFurtherProcessing--------'+indexesForFurtherProcessing);
        /********************************************************Duplicate Account Check ENDF*******/


        //niether matching Leads nor Accounts found for the Requests so create new Account, Con, Opp, Opp Lines
        if(indexesForFurtherProcessing.isEmpty() == false ) {
            System.debug('--niether matching Leads nor Accounts found so create new Account, Con, Opp, Opp Lines-------');
            //Inserted the new Accounts
            NewOpportunityRequestHandler.performDML(indexesForFurtherProcessing,indexToAccountsMap,requestProcessedResult,indexToRequestsToProcess, Constants.DML_INSERT);
            indexesForFurtherProcessing = new List<Integer>(indexToRequestsToProcess.keySet());
            //Formed the related Contacts for successfully inserted Accounts per request
            Map<Integer,SObject> indexToContactsMap = new Map<Integer,SObject>();
            NewOpportunityRequestHandler.formSobjects(indexToRequestsToProcess, indexToAccountsMap, Constants.FLD_ACCOUNTID,
                indexesForFurtherProcessing, indexToContactsMap, mapIndexToNewSobjectsToDelete, Contact.SobjectType);
            //Inserted the related Contacts
            NewOpportunityRequestHandler.performDML(indexesForFurtherProcessing,indexToContactsMap,requestProcessedResult,indexToRequestsToProcess, Constants.DML_INSERT);
            indexesForFurtherProcessing = new List<Integer>(indexToRequestsToProcess.keySet());

            //Formed the related Opportunities for successfully inserted Accounts per request
            Map<Integer,SObject> indexToOpportunitiesMap = new Map<Integer,SObject>();
            NewOpportunityRequestHandler.formSobjects(indexToRequestsToProcess, indexToAccountsMap, Constants.FLD_ACCOUNTID, indexesForFurtherProcessing, indexToOpportunitiesMap, mapIndexToNewSobjectsToDelete, Opportunity.SobjectType);
            //Inserted the related Opportunities
            NewOpportunityRequestHandler.performDML(indexesForFurtherProcessing,indexToOpportunitiesMap,requestProcessedResult,indexToRequestsToProcess, Constants.DML_INSERT);
            indexesForFurtherProcessing = new List<Integer>(indexToRequestsToProcess.keySet());

            if(indexesForFurtherProcessing.isEmpty() == false){
                processOpportunityLines(indexesForFurtherProcessing,indexToRequestsToProcess,requestProcessedResult,indexToOpportunitiesMap, 'OpportunityId' , mapIndexToNewSobjectsToDelete);
            }
        }
        
        //either matching Leads or Accounts found so convert the matching Leads/ create Opp, Opp Lines for matching Accounts
        if(matchingRecordsToProcess.isEmpty() == false) {
            System.debug('------either matching Leads or Accounts found so convert the matching Leads/ create Opp, Opp Lines for matching Accounts----');
            Sobject matchingSobj;
            Map<Integer,Lead> mapRequestIndexesToMatchingLead = new Map<Integer,Lead>();
            List<Account> accountsForOpportunityCreation = new List<Account>();
            List<Integer> lstMatchingAccountRequestIndexes = new List<Integer>();


            Map<Integer,Object> accountIndexToRequestsToProcess = new Map<Integer,Object>();
            List<Integer> accountIndexesForFurtherProcessing = new List<Integer>();
            Map<Integer,Object> leadIndexToRequestsToProcess = new Map<Integer,Object>();
            List<Integer> leadIndexesForFurtherProcessing = new List<Integer>();

            indexToRequestsToProcess.clear();
            indexesForFurtherProcessing.clear();
            
            //Segragating the matched Lead and Account records
            for(Integer index : matchingRecordsToProcess.keySet()) {
                
                matchingSobj = matchingRecordsToProcess.get(index);
                if(matchingSobj.getSObjectType() == Lead.SobjectType) {
                    mapRequestIndexesToMatchingLead.put(index, (Lead)matchingSobj);

                    leadIndexToRequestsToProcess.put(index,lstRequestsToProcess[index]);
                    leadIndexesForFurtherProcessing.add(index);
                }
                else if(matchingSobj.getSObjectType() == Account.SobjectType) {
                    accountsForOpportunityCreation.add((Account)matchingSobj);
                    lstMatchingAccountRequestIndexes.add(index);

                    accountIndexToRequestsToProcess.put(index,lstRequestsToProcess[index]);
                    accountIndexesForFurtherProcessing.add(index);
                }
            }

            if(mapRequestIndexesToMatchingLead.isEmpty() == false) {
                System.debug('-------found matching Leads----');
                //Creating new Leads from Requests
                Map<Integer,SObject> indexToSobjectsMap = new Map<Integer,SObject>();
                NewOpportunityRequestHandler.formSobjects(leadIndexToRequestsToProcess,null,null,
                leadIndexesForFurtherProcessing, indexToSobjectsMap, mapIndexToNewSobjectsToDelete, Lead.SobjectType);
                //copied Id from existing leads to newly Created Leads with latest information
                for(Integer index : indexToSobjectsMap.keySet()){
                    if(mapRequestIndexesToMatchingLead.containsKey(index)) {
                        indexToSobjectsMap.get(index).Id = mapRequestIndexesToMatchingLead.get(index).Id;
                    }
                }

                //Updating existing Leads
                NewOpportunityRequestHandler.performDML(leadIndexesForFurtherProcessing,indexToSobjectsMap,requestProcessedResult,leadIndexToRequestsToProcess, Constants.DML_UPDATE);
                leadIndexesForFurtherProcessing = new List<Integer>(leadIndexToRequestsToProcess.keySet());
                
                Map<Integer, Database.LeadConvertResult> mapIndexToLeadConvertResult = new Map<Integer, Database.LeadConvertResult>();
                NewOpportunityRequestHandler.performLeadConversion(indexToSobjectsMap, requestProcessedResult, leadIndexToRequestsToProcess, mapIndexToLeadConvertResult, mapIndexToNewSobjectsToDelete);
                leadIndexesForFurtherProcessing = new List<Integer>(leadIndexToRequestsToProcess.keySet());


                Map<Integer,SObject> indexToOpportunitiesMap = new Map<Integer,SObject>();
                for(Integer index : leadIndexesForFurtherProcessing) {
                    indexToOpportunitiesMap.put(index,
                        new Opportunity(Id=mapIndexToLeadConvertResult.get(index).getOpportunityId(), Pricebook2Id=DS_Pricebook.getStdPricebookId()));
                }


                //Creating corresponding new Accounts To update converted Accounts with data from Requests
                indexToSobjectsMap = new Map<Integer,SObject>();
                NewOpportunityRequestHandler.formSobjects(leadIndexToRequestsToProcess,null,null,
                leadIndexesForFurtherProcessing, indexToSobjectsMap, mapIndexToNewSobjectsToDelete, Account.SobjectType);
                //copied Id from converted Accounts to newly Created Accounts with latest information
                for(Integer index : indexToSobjectsMap.keySet()){
                    if(mapIndexToLeadConvertResult.containsKey(index)) {
                        indexToSobjectsMap.get(index).Id = mapIndexToLeadConvertResult.get(index).getAccountId();
                    }
                }
                //Updating converted Leads Accounts
                NewOpportunityRequestHandler.performDML(leadIndexesForFurtherProcessing,indexToSobjectsMap,requestProcessedResult,leadIndexToRequestsToProcess, Constants.DML_UPDATE);
                leadIndexesForFurtherProcessing = new List<Integer>(leadIndexToRequestsToProcess.keySet());



                //Creating corresponding new Contact To update converted Contacts with data from Requests
                indexToSobjectsMap = new Map<Integer,SObject>();
                NewOpportunityRequestHandler.formSobjects(leadIndexToRequestsToProcess,null,null,
                leadIndexesForFurtherProcessing, indexToSobjectsMap, mapIndexToNewSobjectsToDelete, Contact.SobjectType);
                //copied Id from converted Contact to newly Created Leads with latest information
                for(Integer index : indexToSobjectsMap.keySet()){
                    if(mapIndexToLeadConvertResult.containsKey(index)) {
                        indexToSobjectsMap.get(index).Id = mapIndexToLeadConvertResult.get(index).getContactId();
                    }
                }
                //Updating converted Leads Contacts
                NewOpportunityRequestHandler.performDML(leadIndexesForFurtherProcessing,indexToSobjectsMap,requestProcessedResult,leadIndexToRequestsToProcess, Constants.DML_UPDATE);
                leadIndexesForFurtherProcessing = new List<Integer>(leadIndexToRequestsToProcess.keySet());

                //Creating corresponding new Opportunities To update converted Opportunities with data from Requests
                indexToSobjectsMap = new Map<Integer,SObject>();
                NewOpportunityRequestHandler.formSobjects(leadIndexToRequestsToProcess,null,null,
                leadIndexesForFurtherProcessing, indexToSobjectsMap, mapIndexToNewSobjectsToDelete, Opportunity.SobjectType);
                //copied Id from converted Opportunity to newly Created Opportunity with latest information
                for(Integer index : indexToSobjectsMap.keySet()){
                    if(mapIndexToLeadConvertResult.containsKey(index)) {
                        indexToSobjectsMap.get(index).Id = mapIndexToLeadConvertResult.get(index).getOpportunityId();
                    }
                }
                //Updating converted Leads Opportunities
                NewOpportunityRequestHandler.performDML(leadIndexesForFurtherProcessing,indexToSobjectsMap,requestProcessedResult,leadIndexToRequestsToProcess, Constants.DML_UPDATE);
                leadIndexesForFurtherProcessing = new List<Integer>(leadIndexToRequestsToProcess.keySet());

                if(leadIndexesForFurtherProcessing.isEmpty() == false){
                    processOpportunityLines(leadIndexesForFurtherProcessing,leadIndexToRequestsToProcess,requestProcessedResult,indexToOpportunitiesMap, 'OpportunityId' , mapIndexToNewSobjectsToDelete);
                }
            }

            if(accountsForOpportunityCreation.isEmpty() == false) {
                System.debug('-------found matching Accounts----');
                //Creating new Opportunities related to matched Accounts
                Map<Integer,SObject> indexToOpportunitiesMap = new Map<Integer,SObject>();
                NewOpportunityRequestHandler.formSobjects(accountIndexToRequestsToProcess,matchingRecordsToProcess,Constants.FLD_ACCOUNTID,
                    accountIndexesForFurtherProcessing, indexToOpportunitiesMap, mapIndexToNewSobjectsToDelete, Opportunity.SobjectType);
                //Inserting Opportunities
                NewOpportunityRequestHandler.performDML(accountIndexesForFurtherProcessing,indexToOpportunitiesMap,requestProcessedResult,accountIndexToRequestsToProcess, Constants.DML_INSERT);
                accountIndexesForFurtherProcessing = new List<Integer>(accountIndexToRequestsToProcess.keySet());

                if(accountIndexesForFurtherProcessing.isEmpty() == false){
                    processOpportunityLines(accountIndexesForFurtherProcessing,accountIndexToRequestsToProcess,requestProcessedResult,indexToOpportunitiesMap, 'OpportunityId' , mapIndexToNewSobjectsToDelete);
                }
            }
        }
        NewOpportunityRequestHandler.deleteNewlyCreatedSobjectsForFailedTransactions(mapIndexToNewSobjectsToDelete, requestProcessedResult);
        system.debug('-------requestProcessedResult---------'+requestProcessedResult);
        return requestProcessedResult;

    }
    
    private static void processOpportunityLines(List<Integer> indexesForFurtherProcessing,Map<Integer,Object> indexToRequestsToProcess,
        Map<Integer,NewOpportunityRequestProcessResult> requestProcessedResult, Map<Integer,SObject> indexToParentRecordMap, String relationshipFld,
        Map<Integer,List<Sobject>> mapIndexToNewSobjectsToDelete) {

        Map<String,Object> mapObjData;
        List<Object> selectedProductsLst;
        Map<Integer,Object> selProdIndexToSelProdDetailsMap;
        List<Integer> selProdIndexes;
        Map<Integer,List<Sobject>> mapIndexLstOppLinesToInsert = new Map<Integer,List<Sobject>>();
        Map<Id,Integer> mapOppIdToReqIndex = new Map<Id,Integer>();
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oliLst;
        for(Integer index : indexesForFurtherProcessing) {
            selProdIndexToSelProdDetailsMap = new Map<Integer,Object>();
            selProdIndexes = new List<Integer>();
            mapObjData = (Map<String,Object>)indexToRequestsToProcess.get(index);

            if(mapObjData.containsKey(Constants.JSON_KEY_SELECTEDPRODUCTS)) {
                selectedProductsLst = (List<Object>)mapObjData.get(Constants.JSON_KEY_SELECTEDPRODUCTS);
                for(Integer selProdIndex = 0; selProdIndex < selectedProductsLst.size(); selProdIndex++) {
                    selProdIndexToSelProdDetailsMap.put(selProdIndex,selectedProductsLst[selProdIndex]);
                    selProdIndexes.add(selProdIndex);
                }
                mapOppIdToReqIndex.put(indexToParentRecordMap.get(index).Id, index);
                oliLst = (List<OpportunityLineItem>)formSobjects(selProdIndexToSelProdDetailsMap,
                                null, 
                                relationshipFld, 
                                selProdIndexes,
                                null,
                                null, 
                                OpportunityLineItem.sobjectType);
                for(OpportunityLineItem oli : oliLst){
                    oli.put(relationshipFld,indexToParentRecordMap.get(index).Id);//no need to send relationshipFld as a parameter
                }
                //to handle negative scenarios for Opportunity in test class
                if(Test.isRunningTest() && NewOpportunityRequestHandler.causeOpportunityLineItemCreationExceptionForIndex != null
                    && index == NewOpportunityRequestHandler.causeOpportunityLineItemCreationExceptionForIndex) {
                    oliLst[0].put(Constants.FLD_QUANTITY, null); //So that it will fail with required field missing error
                }
                if(mapIndexToNewSobjectsToDelete.containsKey(index)) {
                    mapIndexToNewSobjectsToDelete.get(index).addAll(oliLst);//added partial successfull olis
                }
                else {
                    mapIndexToNewSobjectsToDelete.put(index,new List<Sobject>((List<Sobject>)oliLst));//added partial successfull olis
                }
                opportunityLineItemsToInsert.addAll(oliLst);
            }
            else {
                requestProcessedResult.put(index, new NewOpportunityRequestProcessResult(false,Label.Invalid_Json_Selected_Products_Absent));
            }
        }
        
        List<Database.SaveResult> saveResLst = Database.insert(opportunityLineItemsToInsert, false);
        Map<Integer, List<OpportunityLineItem>> mapIndexListOLI = new Map<Integer, List<OpportunityLineItem>>();
        Integer requestIndex;
        for(Integer index=0; index < saveResLst.size(); index++) {
            requestIndex = mapOppIdToReqIndex.get(opportunityLineItemsToInsert[index].OpportunityId);
            if(saveResLst[index].isSuccess()) {
                if(mapIndexListOLI.containsKey(requestIndex)) {
                    mapIndexListOLI.get(requestIndex).add(opportunityLineItemsToInsert[index]);
                }
                else {
                    mapIndexListOLI.put(requestIndex, new List<OpportunityLineItem>{opportunityLineItemsToInsert[index]});
                }
            }
            else {
                requestProcessedResult.put(requestIndex,
                    new NewOpportunityRequestProcessResult(false,String.valueOf(saveResLst[index].getErrors())));
            }
        }
    }

    private static void dupeCheckProcess(List<Integer> indexesForFurtherProcessing, List<SObject> sobjDupeCheckLst, Schema.SObjectType sobjectType,
                                        Map<Integer,Sobject> matchingRecordsToProcess, Map<Integer,Object> indexToRequestsToProcess) {
        List<Object> duplicatesLst = DuplicateService.checkAndReturnDuplicates(sobjDupeCheckLst, sobjectType, true);
        Integer index = 0;
        for(Object obj : duplicatesLst) {
            if(obj == null) {}
            else {
                matchingRecordsToProcess.put(indexesForFurtherProcessing[index],((List<Sobject>)obj)[0]);
                indexToRequestsToProcess.remove(indexesForFurtherProcessing[index]);
            }
            index++;
        }
    }

    

    private static void deleteNewlyCreatedSobjectsForFailedTransactions(Map<Integer,List<Sobject>> mapIndexToNewSobjectsToDelete, Map<Integer,NewOpportunityRequestProcessResult> requestProcessedResult) {
        List<Sobject> sobjToDelete = new List<Sobject>();
        List<Sobject> reversedSobjLst = new List<Sobject>();
        for(Integer index : requestProcessedResult.keySet()) {
            if(!requestProcessedResult.get(index).isSuccess && mapIndexToNewSobjectsToDelete.containsKey(index)) {
                for(Sobject sobj : mapIndexToNewSobjectsToDelete.get(index)) {
                    if(sobj.Id != null) {
                        sobjToDelete.add(sobj);
                    }
                }
            }
        }
        //reversing the list since the Parent Sobjects should be deleted after Children
        for(Integer index = sobjToDelete.size() - 1; index >= 0; index--){
            reversedSobjLst.add(sobjToDelete[index]);
        }
        Database.DeleteResult[] deleteResLst = Database.delete(reversedSobjLst, false);
    }

    public class NewOpportunityRequestException extends Exception {}

    public class NewOpportunityRequestProcessResult {
        public Boolean isSuccess;
        public String errorReason;
        public NewOpportunityRequestProcessResult(Boolean isSuccess, String errorReason) {
            this.isSuccess = isSuccess;
            this.errorReason = errorReason;
        }
    }
}