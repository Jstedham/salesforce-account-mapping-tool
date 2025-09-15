@isTest
private class AccountGeocodingBatch_Test {

    /**
     * @description Tests that a batch of accounts with a valid address are geocoded and updated.
     */
    @isTest
    static void testBatchExecution_Success() {

        // Create test data and set mock
        List<Account> testAccounts = new List<Account>();

        for(Integer i = 0; i < 10; i++) {
            testAccounts.add(new Account(
                Name = 'Success Account ' + i,
                BillingStreet = '123 Main St',
                BillingCity = 'Anytown'
            ));
        }
        insert testAccounts;

        Test.setMock(HttpCalloutMock.class, HttpMockFactory.createGeocodingSuccessMock());

        // Run test
        Test.startTest();
        Database.executeBatch(new AccountGeocodingBatch(), 10);
        Test.stopTest();

        // Verify tests
        List<Account> updatedAccounts = [SELECT BillingLatitude, BillingLongitude FROM Account WHERE Name LIKE 'Success Account%'];
        for (Account acc : updatedAccounts) {
            System.assertEquals(40.7486, acc.BillingLatitude, 'Latitude should be updated on success.');
            System.assertEquals(-73.9856, acc.BillingLongitude, 'Longitude should be updated on success.');
        }

    }

    /**
     * @description Tests that an Account record will not update on API call failures.
     */
    @isTest
    static void testBatchExecution_Failure() {

        // Create test account and set mock
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Failure Account', BillingStreet = 'Invalid Address')
        };
        insert testAccounts;

        Test.setMock(HttpCalloutMock.class, HttpMockFactory.createGeocodingFailureMock());

        // Run test
        Test.startTest();
        Database.executeBatch(new AccountGeocodingBatch(), 10);
        Test.stopTest();

        // Verify the account was NOT updated
        Account failedAccount = [SELECT BillingLatitude, BillingLongitude FROM Account WHERE Name = 'Failure Account'];
        System.assertEquals(null, failedAccount.BillingLatitude, 'Latitude should remain null on failure.');
        System.assertEquals(null, failedAccount.BillingLongitude, 'Longitude should remain null on failure.');
        
    }

    /**
     * @description Tests that the batch job correctly skips records with blank addresses and that no callouts are made.
     * 
     */
    @isTest
    static void testBatchExecution_BlankAddress() {
        // Create test account
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Blank Account')
        };
        insert testAccounts;

        // Run tests
        Test.startTest();
        Database.executeBatch(new AccountGeocodingBatch(), 10);
        Test.stopTest();

        // Verify that record was skipped and no callouts were made.
        Account skippedAccount = [SELECT BillingLatitude, BillingLongitude FROM Account WHERE Name = 'Blank Account'];
        System.assertEquals(null, skippedAccount.BillingLatitude, 'Latitude should be null for skipped records.');
        System.assertEquals(null, skippedAccount.BillingLongitude, 'Longitude should be null for skipped records.');

        System.assertEquals(0, Limits.getCallouts(), 'No callouts should have been made for records with blank addresses.');
    }
}   