/*******************************************************************************************************
 * @description       : Service class to check for the Duplicates as per the configured Duplicate Rules
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
public with sharing class DuplicateService {
    public static List<Object> checkAndReturnDuplicates(List<Sobject> targetSobjects, Schema.SObjectType sobjectType, Boolean isReturnDuplicates) {
        List<Object> returnLst = new List<Object>();
        if(validSobjectsList(targetSobjects, sobjectType)) {
            String sobjectNameStr = sobjectType.getDescribe().getLocalName();
            List<DuplicateCriteria__mdt> duplicateCriterias = [SELECT Field_Name__c,Is_Active__c,Object_Name__c,Order__c
                                                           FROM DuplicateCriteria__mdt
                                                           WHERE Is_Active__c = true AND
                                                            Object_Name__c = :sobjectNameStr
                                                           ORDER BY Order__c Asc];
            Map<String,Schema.SObjectField> fldMap = Schema.getGlobalDescribe().get(sobjectNameStr).getDescribe().fields.getMap();
            String fldNameLowercase;
            Schema.DescribeFieldResult describeFldRes;
            Map<String, Set<String>> uniquenessCriteriaMap = new Map<String, Set<String>>();
            Map<String, Schema.SOAPType> fieldSoapTypeMap = new Map<String, Schema.SOAPType>();
            for(DuplicateCriteria__mdt dupeCriteria : duplicateCriterias) {
                fldNameLowercase = dupeCriteria.Field_Name__c.toLowercase();
                if(fldMap.containsKey(fldNameLowercase)) {
                    describeFldRes = fldMap.get(fldNameLowercase).getDescribe();
                    if(describeFldRes.isFilterable()) {
                        fieldSoapTypeMap.put(fldNameLowercase,describeFldRes.getSOAPType());
                        uniquenessCriteriaMap.put(fldNameLowercase, null);
                    }
                    else {
                        throw new DuplicateServiceException('This type of field cannot be used as Duplication criteria. : '+ dupeCriteria.Object_Name__c + '=>' + dupeCriteria.Field_Name__c);
                    }
                }
                else {
                    throw new DuplicateServiceException('Duplicate criteria contains invalid fields');
                }
            }
            if(uniquenessCriteriaMap.isEmpty() == false) {
                String uniquenessKey;
                Map<String,List<Integer>> uniquenessKeyToIndexMap = new Map<String,List<Integer>>();
                Map<String,List<Integer>> uniquenessKeyToDuplicateIndexMap = new Map<String,List<Integer>>();
                Integer itrIndex = 0;
                String sobjFldValue;
                String tempStr;
                for(Sobject sobj : targetSobjects) {
                    uniquenessKey = '';
                    for(String fldName : uniquenessCriteriaMap.keySet()) {
                        uniquenessKey += (sobj.get(fldName) + Constants.colon).toLowerCase();
                        sobjFldValue = sobj.get(fldName)!=null?String.valueOf(sobj.get(fldName)).toLowerCase():null;
                        
                        if(uniquenessCriteriaMap.get(fldName) == null) {
                            if(sobjFldValue != null){
                                
                                if(fieldSoapTypeMap.get(fldName) == Schema.SOAPType.String || fieldSoapTypeMap.get(fldName) == Schema.SOAPType.ID) {
                                    tempStr = Constants.SINGLE_QUOTE + sobjFldValue + Constants.SINGLE_QUOTE;
                                }
                                else {
                                    tempStr = sobjFldValue;
                                }
                                uniquenessCriteriaMap.put(fldName,new Set<String>{tempStr});
                            }
                            else {
                                uniquenessCriteriaMap.put(fldName,
                                new Set<String>{null});
                            }

                        }
                        else {
                            if(sobjFldValue == null){
                                uniquenessCriteriaMap.get(fldName).add(null);
                            }
                            else {
                                if(fieldSoapTypeMap.get(fldName) == Schema.SOAPType.String || fieldSoapTypeMap.get(fldName) == Schema.SOAPType.ID) {
                                    tempStr = Constants.SINGLE_QUOTE + sobjFldValue + Constants.SINGLE_QUOTE;
                                }
                                else {
                                    tempStr = sobjFldValue;
                                }
                                uniquenessCriteriaMap.get(fldName).add(tempStr);
                            }
                        }
                        
                    }
                    
                    if(uniquenessKeyToIndexMap.containsKey(uniquenessKey)) {
                        uniquenessKeyToIndexMap.get(uniquenessKey).add(itrIndex);
                    }
                    else {
                        uniquenessKeyToIndexMap.put(uniquenessKey,new List<Integer>{itrIndex});
                    }
                    itrIndex++;
                }//end of for each Sobject loop
                String filterCondition = '';
                for(String fldname : uniquenessCriteriaMap.keySet()) {
                    tempStr = '';
                    for(Object fldValuesStr : uniquenessCriteriaMap.get(fldname)) {
                        tempStr += fldValuesStr + Constants.COMMA;
                    }
                    tempStr = tempStr.removeEnd(Constants.COMMA);
                    filterCondition += ' ' + fldname + ' IN (' + tempStr + ') ' + 'AND';
                }
                filterCondition = filterCondition.removeEnd('AND');
                List<Sobject> duplicateSobjectRecords = queryAndGetSobjects(uniquenessCriteriaMap.keySet(), filterCondition , sobjectNameStr);
                itrIndex = 0;
                for(Sobject duplicateSobj : duplicateSobjectRecords) {
                    uniquenessKey = '';
                    for(String fldName : uniquenessCriteriaMap.keySet()) {
                        uniquenessKey += (duplicateSobj.get(fldName) + Constants.colon).toLowerCase();
                    }
                    if(uniquenessKeyToDuplicateIndexMap.containsKey(uniquenessKey)) {
                        uniquenessKeyToDuplicateIndexMap.get(uniquenessKey).add(itrIndex);
                    }
                    else {
                        uniquenessKeyToDuplicateIndexMap.put(uniquenessKey,new List<Integer>{itrIndex});
                    }
                    itrIndex++;
                }

                for(Sobject sobj : targetSobjects) {
                    uniquenessKey = '';
                    for(String fldName : uniquenessCriteriaMap.keySet()) {
                        uniquenessKey += (sobj.get(fldName) + Constants.colon).toLowerCase();
                    }
                    if(uniquenessKeyToDuplicateIndexMap.containsKey(uniquenessKey)) {
                        if(isReturnDuplicates) {
                            List<Sobject> duplicatesLst = new List<Sobject>();
                            for(Integer dupeIndex : uniquenessKeyToDuplicateIndexMap.get(uniquenessKey)) {
                                duplicatesLst.add(duplicateSobjectRecords[dupeIndex]);
                            }
                            returnLst.add(duplicatesLst);
                        }
                        else{
                            returnLst.add(true);
                        }
                    }
                    else {
                        if(isReturnDuplicates) {
                            returnLst.add(null);
                        }
                        else{
                            returnLst.add(false);
                        }
                    }
                }
            }
            else {
                throw new DuplicateServiceException('Duplicate criteria not configured');
            }
            
        }
        else {
            throw new DuplicateServiceException(Constants.sobjectTypeMissmatch);
        }
        return returnLst;
    }
    
    private static List<Sobject> queryAndGetSobjects(Set<String> fieldsToQuery, String filterCondition, String sobjectNameStr) {
        // to be taken care of correctly later
        if(sobjectNameStr == 'Lead') {
            filterCondition += ' AND IsConverted = false';
        }
        return Database.query('SELECT '+ String.join(new List<String>(fieldsToQuery),',') + ' FROM ' + sobjectNameStr + ' WHERE '+filterCondition);
    }
    private static Boolean validSobjectsList(List<Sobject> targetSobjects, Schema.SObjectType sobjectType){
        Boolean isValid = true;
        for(Sobject sobj : targetSobjects) {
            isValid = isValid && sobj.getSObjectType() == sobjectType;
            if(!isValid) {
                break;
            }
        }
        return isValid;
    }

    public static List<Object> dupeCheckCorrespondingSobject(Schema.SObjectType targetSobject, Schema.SObjectType sourceSobject, List<Sobject> sourceSobjectLst, Boolean returnDuplicates) {
        List<Object> duplicateResult;
        
        String targetSobjectName = targetSobject.getDescribe().getLocalName().toLowerCase();
        String sourceSobjectName = sourceSobject.getDescribe().getLocalName().toLowerCase();
        List<Sobject> sobjToCheckForDuplicates = new List<Sobject>();
        if(targetSobjectName != sourceSobjectName) {
            Map<String,List<OpportunityManagementApiJsonMapping__mdt>> jsonMappingsMap = DuplicateService.fetchJsonMappings(new Set<String>{targetSobjectName,sourceSobjectName});
        
            Map<String,String> mapSrcSobjectJsonKeyToSFfieldApi  = new Map<String,String>();
            Map<String,String> mapTargetSobjectSFfieldApiToJsonKey  = new Map<String,String>();
            if(jsonMappingsMap.containsKey(targetSobjectName) && jsonMappingsMap.containsKey(sourceSobjectName)) {
                for(String sobjName : jsonMappingsMap.keySet()) {
                    for(OpportunityManagementApiJsonMapping__mdt mappngObj : jsonMappingsMap.get(sobjName)) {
                        if(sobjName == sourceSobjectName) {
                            mapSrcSobjectJsonKeyToSFfieldApi.put(mappngObj.Json_Key__c.toLowerCase(), mappngObj.Sobject_Field_Api_Name__c.toLowerCase());
                        }
                        if(sobjName == targetSobjectName) {
                            mapTargetSobjectSFfieldApiToJsonKey.put(mappngObj.Json_Key__c.toLowerCase(), mappngObj.Sobject_Field_Api_Name__c.toLowerCase());
                        }
                    }
                }
                for(Sobject srcSobj : sourceSobjectLst) {
                    Sobject sObj = targetSobject.newSObject();
                    for(String jsonKey : mapTargetSobjectSFfieldApiToJsonKey.keySet()) {
                        if(mapSrcSobjectJsonKeyToSFfieldApi.containsKey(jsonKey)) {
                            sObj.put(mapTargetSobjectSFfieldApiToJsonKey.get(jsonKey), srcSobj.get(mapSrcSobjectJsonKeyToSFfieldApi.get(jsonKey)));
                        }
                    }
                    sobjToCheckForDuplicates.add(sObj);
                }

                
            }
        }
        else {
            sobjToCheckForDuplicates = sourceSobjectLst.deepClone();
        }
        duplicateResult = checkAndReturnDuplicates(sobjToCheckForDuplicates, targetSobject, returnDuplicates);
        return duplicateResult;
    }

    //can be moved to DS_OppManagementObjectMappings cls
    public static Map<String,List<OpportunityManagementApiJsonMapping__mdt>> fetchJsonMappings(Set<String> objectNames) {
        Map<String,List<OpportunityManagementApiJsonMapping__mdt>> objectToMappings = new Map<String,List<OpportunityManagementApiJsonMapping__mdt>>();
        String objName = '';
        for(OpportunityManagementApiJsonMapping__mdt objMapp : [SELECT Is_Active__c,Json_Key__c,Sobject_Field_Api_Name__c,Sobject_Name__c
                                                                FROM OpportunityManagementApiJsonMapping__mdt
                                                                WHERE Is_Active__c = true AND
                                                                    Sobject_Name__c IN :objectNames
                                                                ORDER BY Sobject_Name__c Asc]) {
            objName = objMapp.Sobject_Name__c.toLowercase();
            if(objectToMappings.containsKey(objName)) {
                objectToMappings.get(objName).add(objMapp);
            }
            else {
                objectToMappings.put(objName, new List<OpportunityManagementApiJsonMapping__mdt>{objMapp});
            }
        }
        return objectToMappings;
    }
    public class DuplicateServiceException extends Exception {}
}