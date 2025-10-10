@isTest
private class AccountGeocodingInvocable_Test {

    /**
     * @description Verifies that the invocable method successfully enqueues a job
     * when valid Account Ids are passed from a Flow.
     */
    @isTest
    static void testEnqueueGeocodingForFlow_Success() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, BillingStreet = '123 Main St'));
        }
        insert testAccounts;

        // Prepare the nested list structure that Flows use
        List<String> accountIdStrings = new List<String>();
        for (Account acc : testAccounts) {
            accountIdStrings.add(acc.Id);
        }
        List<List<String>> flowRequests = new List<List<String>>{ accountIdStrings };

        // Start the test
        Test.startTest();
        AccountGeocodingInvocable.enqueueGeocodingForFlow(flowRequests);
        Test.stopTest();

        // Verify that one queueable job was started
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'A queueable job should have been enqueued.');
    }

    /**
     * @description Verifies that the invocable method handles an empty list
     * gracefully and does not enqueue a job.
     */
    @isTest
    static void testEnqueueGeocodingForFlow_EmptyList() {
        // Prepare an empty list
        List<List<String>> flowRequests = new List<List<String>>();

        // Start the test
        Test.startTest();
        AccountGeocodingInvocable.enqueueGeocodingForFlow(flowRequests);
        Test.stopTest();

        // Verify that no jobs were started
        System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob], 'No jobs should be enqueued for an empty list.');
    }
}