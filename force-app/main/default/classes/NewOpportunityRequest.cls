/*******************************************************************************************************
 * @description       : Exposed Api class for Inbound opportunity requests
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
@RestResource(urlMapping='/v1/ProcessOpportunityRequests/')
global with sharing class NewOpportunityRequest {
    @HttpPut
    global static void doPutMethod(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            if(req.requestBody != null) {
                Object reqObjParsed = JSON.deserializeUntyped(req.requestBody.toString());
                if(reqObjParsed instanceof List<Object>){
                    Map<Integer,NewOpportunityRequestHandler.NewOpportunityRequestProcessResult> result =
                        NewOpportunityRequestHandler.processRequest((List<Object>)reqObjParsed);
                    List<Object> responseBodyLst = new List<Object>();
                    for(Integer index=0; index<((List<Object>)reqObjParsed).size(); index++) {
                        responseBodyLst.add(result.get(index));
                    }
                    res.statusCode = 200;
                    res.responseBody = Blob.valueOf(Json.serialize(responseBodyLst));
                }
                else {
                    res.statusCode = 400;
                    res.responseBody = Blob.valueOf(Label.Invalid_Json_Format);
                }
            }
        }
        catch(Exception exp) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(Label.Generic_Opportunity_Processing_API_Error + Constants.NEWLINE +exp.getMessage());
        }

        
        
    }
}