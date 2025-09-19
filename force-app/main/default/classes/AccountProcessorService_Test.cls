@isTest
private class AccountProcessorService_Test {

    /**
     * @description Tests the success scenario where accounts are geocoded correctly.
     */
    @isTest
    static void testGeocodeAccounts_Success() {
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Success Account', BillingStreet = '123 Main St')
        };
        insert testAccounts;

        Test.setMock(HttpCalloutMock.class, HttpMockFactory.createGeocodingSuccessMock());

        Test.startTest();
        AccountProcessorService.GeocodeAccountsResult result = AccountProcessorService.geocodeAccounts(testAccounts);
        Test.stopTest();

        // Assert: Verify the results
        System.assertEquals(1, result.recordsProcessed, 'Should have processed one record.');
        System.assertEquals(0, result.recordsFailed, 'Should have zero failures.');
        System.assertEquals(1, result.accountsToUpdate.size(), 'One account should be ready for update.');
        System.assertEquals(40.7486, result.accountsToUpdate[0].BillingLatitude, 'Latitude should be updated.');
        System.assertEquals(-73.9856, result.accountsToUpdate[0].BillingLongitude, 'Longitude should be updated.');
    }

    /**
     * @description Tests the failure scenario where the GeocodingService throws an exception.
     */
    @isTest
    static void testGeocodeAccounts_Failure() {
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Failure Account', BillingStreet = 'Invalid Address')
        };
        insert testAccounts;
        
        Test.setMock(HttpCalloutMock.class, HttpMockFactory.createGeocodingFailureMock());

        Test.startTest();
        AccountProcessorService.GeocodeAccountsResult result = AccountProcessorService.geocodeAccounts(testAccounts);
        Test.stopTest();

        System.assertEquals(1, result.recordsProcessed, 'Should have processed one record.');
        System.assertEquals(1, result.recordsFailed, 'Should have one failure.');
        System.assertEquals(0, result.accountsToUpdate.size(), 'No accounts should be ready for update.');
        System.assertEquals(1, result.errorMessages.size(), 'Should have one error message.');
        System.assert(result.errorMessages[0].contains('API failed with status code 403'), 'Error message should contain failure details.');
    }

    /**
     * @description Tests that records with no address are processed but do not result in a callout or update.
     */
    @isTest
    static void testGeocodeAccounts_BlankAddress() {
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Blank Address Account') // No address fields
        };
        insert testAccounts;

        Test.startTest();
        AccountProcessorService.GeocodeAccountsResult result = AccountProcessorService.geocodeAccounts(testAccounts);
        Test.stopTest();

        System.assertEquals(1, result.recordsProcessed, 'Should have processed one record.');
        System.assertEquals(0, result.recordsFailed, 'Should have zero failures.');
        System.assertEquals(0, result.accountsToUpdate.size(), 'No accounts should be ready for update.');
        System.assertEquals(0, Limits.getCallouts(), 'No callouts should be made for blank addresses.');
    }
}