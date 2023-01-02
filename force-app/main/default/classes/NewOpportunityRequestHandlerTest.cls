/*******************************************************************************************************
 * @description       : Test class for NewOpportunityRequest 
 * @author            : Rahul Panditrao
 * @last modified on  : 30-12-2022
 * @last modified by  : Rahul Panditrao
 * -----------------------------------------------------------------------------------------------------
 * Developer            Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Rahul Panditrao     30-12-2022         Initial Version
******************************************************************************************************/
@isTest
public with sharing class NewOpportunityRequestHandlerTest {
    @testSetup static void setup() {

        /***************Should make use of Test Data factory as an enhancement*****/

        Account acc1 = new Account(Name='ExistingAcc-1');
        insert acc1;
        Account acc2 = new Account(Name='ExistingAcc-2');
        insert acc2;

        Lead lead1 = new Lead (LastName = 'ExistingLead-1', Email = 'ExistingLead-1@ExistingLead-1.com',
            mobilephone = '+1234567890', Company = 'ExistingLead-1');
        insert lead1;
        Lead lead2 = new Lead (LastName = 'ExistingLead-2', Email = 'ExistingLead-2@ExistingLead-2.com',
            mobilephone = '+1234567890', Company = 'ExistingLead-2');
        insert lead2;

        Product2 prod = new Product2(Name = 'Test Product1', 
                                     External_Id__c = 'extr1');
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        prod = new Product2(Name = 'Test Product2', 
                                     External_Id__c = 'extr2');
        insert prod;
        standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 20000, IsActive = true);
        insert standardPrice;
    }

    //one non existing Account
    @isTest static void handleInappropriateRequestTest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response= res;
        req.requestBody = Blob.valueOf('{"test":"Test"}');//invalid Json
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/v1/ProcessOpportunityRequests/';
        NewOpportunityRequest.doPutMethod();
        System.assertEquals(400, res.statusCode);
    }
    //one non existing Account
    @isTest static void newAccountSingle() {
        String jsonStr = '[{"CompanyName":"NewAcc-1","Email":"NewAcc-1FRMJson@test.test","Phone":"3333333333","selectedproducts":[{"Quantity":4,"ProductCode":"extr1"},{"Quantity":5,"ProductCode":"extr2"}],"PersonalFirstName":"testConFNameNewAcc","PersonalLastName":"testConLNameNewAcc"}]';
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response= res;
        req.requestBody = Blob.valueOf(jsonStr);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/v1/ProcessOpportunityRequests/';
        NewOpportunityRequest.doPutMethod();
        System.assertEquals(200, res.statusCode);
        Test.stopTest();

        List<Account> accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'NewAcc-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals('3333333333', accLst[0].Phone);
        System.assertEquals('NewAcc-1', accLst[0].Name);


        List<Contact> conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, conLst.size());
        System.assertEquals('testConFNameNewAcc', conLst[0].FirstName);
        System.assertEquals('testConLNameNewAcc', conLst[0].LastName);
        System.assertEquals('NewAcc-1FRMJson@test.test'.toLowerCase(), conLst[0].Email.toLowerCase());
        System.assertEquals('3333333333', conLst[0].Phone);

        List<Opportunity> oppLst = [SELECT Id,Name FROM Opportunity WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('NewAcc-1', oppLst[0].Name);

        List<OpportunityLineItem> lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem WHERE OpportunityId = :oppLst[0].Id];
        System.assertEquals(2, lstOLI.size());
        List<String> prodCodes = new List<String>{'extr1','extr2'};
        for(OpportunityLineItem oli : lstOLI) {
            System.assert(prodCodes.contains(oli.Product2.External_Id__c));
            if(oli.Product2.External_Id__c == prodCodes[0]){
                System.assertEquals(4, oli.Quantity);
            }
            else if(oli.Product2.External_Id__c == prodCodes[1]){
                System.assertEquals(5, oli.Quantity);
            }
        }
    }

    //one non existing Account Negative
    @isTest static void newAccountSingle_Negative() {
        String jsonStr = '[{"CompanyName":"NewAcc-1","Email":"NewAcc-1FRMJson@test.test","Phone":"3333333333","selectedproducts":[{"Quantity":4,"ProductCode":"extr1"},{"Quantity":5,"ProductCode":"extr2"}],"PersonalFirstName":"testConFNameNewAcc","PersonalLastName":"testConLNameNewAcc"}]';
        Test.startTest();
        NewOpportunityRequestHandler.causeOpportunityLineItemCreationExceptionForIndex = 0;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response= res;
        req.requestBody = Blob.valueOf(jsonStr);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/v1/ProcessOpportunityRequests/';
        NewOpportunityRequest.doPutMethod();
        System.assertEquals(200, res.statusCode);
        Test.stopTest();

        List<Account> accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'NewAcc-1'];
        System.assertEquals(0, accLst.size());


        List<Contact> conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact];
        System.assertEquals(0, conLst.size());

        List<Opportunity> oppLst = [SELECT Id,Name FROM Opportunity];
        System.assertEquals(0, oppLst.size());

        List<OpportunityLineItem> lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem];
        System.assertEquals(0, lstOLI.size());
        
    }

    //one existing Account one non existing
    @isTest static void ExistingAccountAndNonExistingAccount() {
        String jsonStr = '[{"CompanyName":"ExistingAcc-1","Email":"ExistingAcc-1FRMJson@test.test","Phone":"1111111111","selectedproducts":[{"Quantity":1,"ProductCode":"extr1"},{"Quantity":2,"ProductCode":"extr2"}],"PersonalFirstName":"testConFNameExistingAcc","PersonalLastName":"testConLNameExistingAcc"},{"CompanyName":"NewAcc-1","Email":"NewAcc-1FRMJson@test.test","Phone":"3333333333","selectedproducts":[{"Quantity":4,"ProductCode":"extr1"},{"Quantity":5,"ProductCode":"extr2"}],"PersonalFirstName":"testConFNameNewAcc","PersonalLastName":"testConLNameNewAcc"}]';
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response= res;
        req.requestBody = Blob.valueOf(jsonStr);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/v1/ProcessOpportunityRequests/';
        NewOpportunityRequest.doPutMethod();
        System.assertEquals(200, res.statusCode);
        Test.stopTest();

        /**** CHECK FOR EXISTING ACCOUNT START***/
        List<Account> accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'ExistingAcc-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals(null, accLst[0].Phone); //Since we donot update the info from payload to existing account
        System.assertEquals('ExistingAcc-1', accLst[0].Name);


        List<Contact> conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE AccountId = :accLst[0].Id];
        System.assertEquals(0, conLst.size());

        List<Opportunity> oppLst = [SELECT Id,Name FROM Opportunity WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('ExistingAcc-1', oppLst[0].Name);

        List<OpportunityLineItem> lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem WHERE OpportunityId = :oppLst[0].Id];
        System.assertEquals(2, lstOLI.size());
        List<String> prodCodes = new List<String>{'extr1','extr2'};
        for(OpportunityLineItem oli : lstOLI) {
            System.assert(prodCodes.contains(oli.Product2.External_Id__c));
            if(oli.Product2.External_Id__c == prodCodes[0]){
                System.assertEquals(1, oli.Quantity);
            }
            else if(oli.Product2.External_Id__c == prodCodes[1]){
                System.assertEquals(2, oli.Quantity);
            }
        }
        /**** CHECK FOR EXISTING ACCOUNT END***/

        /**** CHECK FOR NEW ACCOUNT START***/
        accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'NewAcc-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals('3333333333', accLst[0].Phone);
        System.assertEquals('NewAcc-1', accLst[0].Name);


        conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, conLst.size());
        System.assertEquals('testConFNameNewAcc', conLst[0].FirstName);
        System.assertEquals('testConLNameNewAcc', conLst[0].LastName);
        System.assertEquals('NewAcc-1FRMJson@test.test'.toLowerCase(), conLst[0].Email.toLowerCase());
        System.assertEquals('3333333333', conLst[0].Phone);

        oppLst = [SELECT Id,Name FROM Opportunity WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('NewAcc-1', oppLst[0].Name);

        lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem WHERE OpportunityId = :oppLst[0].Id];
        System.assertEquals(2, lstOLI.size());
        prodCodes = new List<String>{'extr1','extr2'};
        for(OpportunityLineItem oli : lstOLI) {
            System.assert(prodCodes.contains(oli.Product2.External_Id__c));
            if(oli.Product2.External_Id__c == prodCodes[0]){
                System.assertEquals(4, oli.Quantity);
            }
            else if(oli.Product2.External_Id__c == prodCodes[1]){
                System.assertEquals(5, oli.Quantity);
            }
        }
        /**** CHECK FOR NEW ACCOUNT END***/
    }

    //one existing Lead conversion test
    @isTest static void ExistingLeadConversionTest() {
        String jsonStr = '[{"CompanyName":"ExistingLead-1","Email":"ExistingLead-1FRMJson@test.test","Phone":"2222222222","selectedproducts":[{"Quantity":3,"ProductCode":"extr1"}],"PersonalFirstName":"testConFname","PersonalLastName":"testConLname"}]';
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response= res;
        req.requestBody = Blob.valueOf(jsonStr);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/v1/ProcessOpportunityRequests/';
        NewOpportunityRequest.doPutMethod();
        System.assertEquals(200, res.statusCode);
        Test.stopTest();

        List<Account> accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'ExistingLead-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals('2222222222', accLst[0].Phone);
        System.assertEquals('ExistingLead-1', accLst[0].Name);

        System.assertEquals(1, [SELECT Id FROM Lead WHERE IsConverted = true].size());

        List<Contact> conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact];
        System.assertEquals(1, conLst.size());
        System.assertEquals('testConFname', conLst[0].FirstName);
        System.assertEquals('testConLname', conLst[0].LastName);
        System.assertEquals('ExistingLead-1FRMJson@test.test'.toLowerCase(), conLst[0].Email.toLowerCase());
        System.assertEquals('2222222222', conLst[0].Phone);

        List<Opportunity> oppLst = [SELECT Id,Name FROM Opportunity];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('ExistingLead-1', oppLst[0].Name);

        List<OpportunityLineItem> lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem];
        System.assertEquals(1, lstOLI.size());
        for(OpportunityLineItem oli : lstOLI) {
            System.assertEquals('ExistingLead-1', oli.Opportunity.Name);
            System.assertEquals(3, oli.Quantity);
            System.assertEquals('extr1', oli.Product2.External_Id__c);
        }
    }

    @isTest static void MixedExistingNonExistingAccountLeadsTest() {
        String jsonStr = '[{"CompanyName":"ExistingAcc-1","Email":"25Dec@test.test","Phone":"1111111111","selectedproducts":[{"Quantity":1,"ProductCode":"extr1"},{"Quantity":2,"ProductCode":"extr2"}],"PersonalFirstName":"25Dec","PersonalLastName":"25Dec"},{"CompanyName":"ExistingLead-1","Email":"ExistingLead-1FRMJson@test.test","Phone":"2222222222","selectedproducts":[{"Quantity":3,"ProductCode":"extr1"}],"PersonalFirstName":"testConFnameExistingLead","PersonalLastName":"testConLnameExistingLead"},{"CompanyName":"NewAcc-1","Email":"NewAcc-1FRMJson@test.test","Phone":"3333333333","selectedproducts":[{"Quantity":4,"ProductCode":"extr1"},{"Quantity":5,"ProductCode":"extr2"}],"PersonalFirstName":"testConFNameNewAcc","PersonalLastName":"testConLNameNewAcc"}]';
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response= res;
        req.requestBody = Blob.valueOf(jsonStr);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/v1/ProcessOpportunityRequests/';
        NewOpportunityRequest.doPutMethod();
        System.assertEquals(200, res.statusCode);
        Test.stopTest();

        /**** CHECK FOR EXISTING ACCOUNT START***/
        List<Account> accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'ExistingAcc-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals(null, accLst[0].Phone); //Since we donot update the info from payload to existing account
        System.assertEquals('ExistingAcc-1', accLst[0].Name);


        List<Contact> conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE AccountId = :accLst[0].Id];
        System.assertEquals(0, conLst.size());

        List<Opportunity> oppLst = [SELECT Id,Name FROM Opportunity WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('ExistingAcc-1', oppLst[0].Name);

        List<OpportunityLineItem> lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem WHERE OpportunityId = :oppLst[0].Id];
        System.assertEquals(2, lstOLI.size());
        List<String> prodCodes = new List<String>{'extr1','extr2'};
        for(OpportunityLineItem oli : lstOLI) {
            System.assert(prodCodes.contains(oli.Product2.External_Id__c));
            if(oli.Product2.External_Id__c == prodCodes[0]){
                System.assertEquals(1, oli.Quantity);
            }
            else if(oli.Product2.External_Id__c == prodCodes[1]){
                System.assertEquals(2, oli.Quantity);
            }
        }
        /**** CHECK FOR EXISTING ACCOUNT END***/

        /**** CHECK FOR NEW ACCOUNT START***/
        accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'NewAcc-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals('3333333333', accLst[0].Phone);
        System.assertEquals('NewAcc-1', accLst[0].Name);


        conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, conLst.size());
        System.assertEquals('testConFNameNewAcc', conLst[0].FirstName);
        System.assertEquals('testConLNameNewAcc', conLst[0].LastName);
        System.assertEquals('NewAcc-1FRMJson@test.test'.toLowerCase(), conLst[0].Email.toLowerCase());
        System.assertEquals('3333333333', conLst[0].Phone);

        oppLst = [SELECT Id,Name FROM Opportunity WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('NewAcc-1', oppLst[0].Name);

        lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem WHERE OpportunityId = :oppLst[0].Id];
        System.assertEquals(2, lstOLI.size());
        prodCodes = new List<String>{'extr1','extr2'};
        for(OpportunityLineItem oli : lstOLI) {
            System.assert(prodCodes.contains(oli.Product2.External_Id__c));
            if(oli.Product2.External_Id__c == prodCodes[0]){
                System.assertEquals(4, oli.Quantity);
            }
            else if(oli.Product2.External_Id__c == prodCodes[1]){
                System.assertEquals(5, oli.Quantity);
            }
        }
        /**** CHECK FOR NEW ACCOUNT END***/

        /**** CHECK FOR EXISTING LEAD START***/
        accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'ExistingLead-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals('2222222222', accLst[0].Phone);
        System.assertEquals('ExistingLead-1', accLst[0].Name);

        System.assertEquals(1, [SELECT Id FROM Lead WHERE IsConverted = true].size());

        conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, conLst.size());
        System.assertEquals('testConFnameExistingLead', conLst[0].FirstName);
        System.assertEquals('testConLnameExistingLead', conLst[0].LastName);
        System.assertEquals('ExistingLead-1FRMJson@test.test'.toLowerCase(), conLst[0].Email.toLowerCase());
        System.assertEquals('2222222222', conLst[0].Phone);

        oppLst = [SELECT Id,Name FROM Opportunity WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('ExistingLead-1', oppLst[0].Name);

        lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem WHERE OpportunityId = :oppLst[0].Id];
        System.assertEquals(1, lstOLI.size());
        for(OpportunityLineItem oli : lstOLI) {
            System.assertEquals('ExistingLead-1', oli.Opportunity.Name);
            System.assertEquals(3, oli.Quantity);
            System.assertEquals('extr1', oli.Product2.External_Id__c);
        }
        /**** CHECK FOR EXISTING LEAD END***/
    }

    @isTest static void MixedExistingNonExistingAccountLeadsTest_Negative() {
        String jsonStr = '[{"CompanyName":"ExistingAcc-1","Email":"25Dec@test.test","Phone":"1111111111","selectedproducts":[{"Quantity":1,"ProductCode":"extr1"},{"Quantity":2,"ProductCode":"extr2"}],"PersonalFirstName":"25Dec","PersonalLastName":"25Dec"},{"CompanyName":"ExistingLead-1","Email":"ExistingLead-1FRMJson@test.test","Phone":"2222222222","selectedproducts":[{"Quantity":3,"ProductCode":"extr1"}],"PersonalFirstName":"testConFnameExistingLead","PersonalLastName":"testConLnameExistingLead"},{"CompanyName":"NewAcc-1","Email":"NewAcc-1FRMJson@test.test","Phone":"3333333333","selectedproducts":[{"Quantity":4,"ProductCode":"extr1"},{"Quantity":5,"ProductCode":"extr2"}],"PersonalFirstName":"testConFNameNewAcc","PersonalLastName":"testConLNameNewAcc"}]';
        Test.startTest();
        NewOpportunityRequestHandler.causeOpportunityLineItemCreationExceptionForIndex = 2;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response= res;
        req.requestBody = Blob.valueOf(jsonStr);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/v1/ProcessOpportunityRequests/';
        NewOpportunityRequest.doPutMethod();
        System.assertEquals(200, res.statusCode);
        Test.stopTest();

        /**** CHECK FOR EXISTING ACCOUNT START***/
        List<Account> accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'ExistingAcc-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals(null, accLst[0].Phone); //Since we donot update the info from payload to existing account
        System.assertEquals('ExistingAcc-1', accLst[0].Name);


        List<Contact> conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE AccountId = :accLst[0].Id];
        System.assertEquals(0, conLst.size());

        List<Opportunity> oppLst = [SELECT Id,Name FROM Opportunity WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('ExistingAcc-1', oppLst[0].Name);

        List<OpportunityLineItem> lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem WHERE OpportunityId = :oppLst[0].Id];
        System.assertEquals(2, lstOLI.size());
        List<String> prodCodes = new List<String>{'extr1','extr2'};
        for(OpportunityLineItem oli : lstOLI) {
            System.assert(prodCodes.contains(oli.Product2.External_Id__c));
            if(oli.Product2.External_Id__c == prodCodes[0]){
                System.assertEquals(1, oli.Quantity);
            }
            else if(oli.Product2.External_Id__c == prodCodes[1]){
                System.assertEquals(2, oli.Quantity);
            }
        }
        /**** CHECK FOR EXISTING ACCOUNT END***/

        /**** CHECK FOR NEW ACCOUNT START***/
        accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'NewAcc-1'];
        System.assertEquals(0, accLst.size());


        conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE FirstName = 'testConFNameNewAcc'];
        System.assertEquals(0, conLst.size());
        

        oppLst = [SELECT Id,Name FROM Opportunity WHERE Name = 'NewAcc-1'];
        System.assertEquals(0, oppLst.size());

        lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem];
        System.assertEquals(3, lstOLI.size());
        
        /**** CHECK FOR NEW ACCOUNT END***/

        /**** CHECK FOR EXISTING LEAD START***/
        accLst = [SELECT Id,Name,Phone FROM Account WHERE Name = 'ExistingLead-1'];
        System.assertEquals(1, accLst.size());
        System.assertEquals('2222222222', accLst[0].Phone);
        System.assertEquals('ExistingLead-1', accLst[0].Name);

        System.assertEquals(1, [SELECT Id FROM Lead WHERE IsConverted = true].size());

        conLst = [SELECT Id,FirstName,LastName,Email,Phone FROM Contact WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, conLst.size());
        System.assertEquals('testConFnameExistingLead', conLst[0].FirstName);
        System.assertEquals('testConLnameExistingLead', conLst[0].LastName);
        System.assertEquals('ExistingLead-1FRMJson@test.test'.toLowerCase(), conLst[0].Email.toLowerCase());
        System.assertEquals('2222222222', conLst[0].Phone);

        oppLst = [SELECT Id,Name FROM Opportunity WHERE AccountId = :accLst[0].Id];
        System.assertEquals(1, oppLst.size());
        System.assertEquals('ExistingLead-1', oppLst[0].Name);

        lstOLI = [SELECT Id,OpportunityId,Opportunity.Name,Quantity,Product2.External_Id__c FROM OpportunityLineItem WHERE OpportunityId = :oppLst[0].Id];
        System.assertEquals(1, lstOLI.size());
        for(OpportunityLineItem oli : lstOLI) {
            System.assertEquals('ExistingLead-1', oli.Opportunity.Name);
            System.assertEquals(3, oli.Quantity);
            System.assertEquals('extr1', oli.Product2.External_Id__c);
        }
        /**** CHECK FOR EXISTING LEAD END***/
    }
    
}