@IsTest
private with sharing class AccountMapperController_Test {
    
    @TestSetup
    static void setup(){
        List<Account> accountsToInsert = new List<Account>();
        // Create 15 accounts with geocoding data to be found by the controller
        for (Integer i = 0; i < 15; i++) {
            accountsToInsert.add(new Account(
                Name = 'Geocoded Account ' + i,
                BillingLatitude = 34.07,
                BillingLongitude = -84.27
            ));
        }

        // Create 5 accounts without geocoding data that should be ignored
        for (Integer i = 0; i < 5; i++) {
            accountsToInsert.add(new Account(Name = 'Non-Geocoded Account ' + i));
        }
        
        insert accountsToInsert;
    }

    @IsTest
    static void testGetAccounts_Success_FirstPage(){
        Test.startTest();
        AccountMapperController.AccountSearchResult result = AccountMapperController.getAccounts(10, 1);
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(10, result.accounts.size(), 'Should return 10 records for the first page.');
        System.assertEquals(15, result.totalRecords, 'Total records should be 15.');
    }

    @IsTest
    static void testGetAccounts_Success_SecondPage() {
        Test.startTest();
        AccountMapperController.AccountSearchResult result = AccountMapperController.getAccounts(10, 2);
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(5, result.accounts.size(), 'Should return the remaining 5 records for the second page.');
        System.assertEquals(15, result.totalRecords, 'Total records should still be 15.');
    }

    @IsTest
    static void testGetAccounts_PageSizeLargerThanTotal() {
        Test.startTest();
        // Request a page size larger than the total number of available records
        AccountMapperController.AccountSearchResult result = AccountMapperController.getAccounts(20, 1);
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(15, result.accounts.size(), 'All 15 geocoded records should be returned');
        System.assertEquals(15, result.totalRecords, 'Total records should be 15');
    }

    @IsTest
    static void testGetAccounts_NoGeocodedAccountsExist(){
        // Delete the accounts created in the setup to test the no records scenario.
        delete [SELECT Id FROM Account];

        Test.startTest();
        AccountMapperController.AccountSearchResult result = AccountMapperController.getAccounts(10, 1);
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(0, result.accounts.size(), 'Account list should be empty when no geocoded accounts exist.');
        System.assertEquals(0, result.totalRecords, 'Total records should be 0.');
    }
}