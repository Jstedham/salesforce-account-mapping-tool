public with sharing class AccountMapperController {
    /**
     * @description A wrapper class to hold the paginated list of accounts and the total record count.
     */
    public class AccountSearchResult {
        @AuraEnabled
        public List<Account> accounts {get; set;}
        @AuraEnabled
        public Integer totalRecords {get; set;}
    }

    /**
     * @description Queries and returns a paginated list of Accounts that have geocoded information. 
     * @param pageSize The number of records to return per page.
     * @param pageNumber The page number to retrieve.
     * @return An AccountSearchResult containing the list of accounts and the total number of records.
     */
    @AuraEnabled(cacheable=true)
    public static AccountSearchResult getAccounts(Integer pageSize, Integer pageNumber) {
        AccountSearchResult result = new AccountSearchResult();

        Integer offset = (pageNumber - 1) * pageSize;

        result.accounts = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude, Team__c, Region__c
            FROM Account
            WHERE BillingLatitude != NULL AND
            BillingLongitude != NULL
            ORDER BY BillingCountry, Region__c, BillingState, BillingCity, Name
            LIMIT :pageSize
            OFFSET :offset
            ];

        result.totalRecords = [SELECT COUNT() FROM Account WHERE BillingLatitude != NULL and BillingLongitude !=NULL];

        return result;
    }
}