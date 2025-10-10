@isTest
private class AccountGeocodingQueueable_Test {

    /**
     * @description Tests the success scenario where the queueable job correctly
     * geocodes and updates accounts.
     */
    @isTest
    static void testQueueableExecution_Success() {
        // Create test data
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Success Account', BillingStreet = '123 Main St')
        };
        insert testAccounts;

        List<Id> accountIds = new List<Id>{ testAccounts[0].Id };

        // Set the mock for a successful API call
        Test.setMock(HttpCalloutMock.class, HttpMockFactory.createGeocodingSuccessMock());

        // Execute the queueable job
        Test.startTest();
        System.enqueueJob(new AccountGeocodingQueueable(accountIds));
        Test.stopTest();

        // Verify the account was updated with coordinates
        Account updatedAccount = [SELECT BillingLatitude, BillingLongitude FROM Account WHERE Id = :accountIds[0]];
        System.assertEquals(40.7486, updatedAccount.BillingLatitude, 'Latitude should be updated on success.');
        System.assertEquals(-73.9856, updatedAccount.BillingLongitude, 'Longitude should be updated on success.');
    }

    /**
     * @description Tests the failure scenario where the geocoding service call fails
     * and the account is NOT updated.
     */
    @isTest
    static void testQueueableExecution_ApiFailure() {
        // Create test data
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Failure Account', BillingStreet = 'Invalid Address')
        };
        insert testAccounts;

        List<Id> accountIds = new List<Id>{ testAccounts[0].Id };

        // Set the mock for a failed API call
        Test.setMock(HttpCalloutMock.class, HttpMockFactory.createGeocodingFailureMock());

        // Execute the queueable job
        Test.startTest();
        System.enqueueJob(new AccountGeocodingQueueable(accountIds));
        Test.stopTest();

        // Verify the account was NOT updated
        Account failedAccount = [SELECT BillingLatitude, BillingLongitude FROM Account WHERE Id = :accountIds[0]];
        System.assertEquals(null, failedAccount.BillingLatitude, 'Latitude should remain null on failure.');
        System.assertEquals(null, failedAccount.BillingLongitude, 'Longitude should remain null on failure.');
    }
}