@isTest
private class AccountActionsController_Test {
    /**
     * @description Verifies that the enqueueGeocodingJob method successfully enqueues the GeocodeAccountQueueable job.
     */
    @isTest
    static void testEnqueueGeocodingJob_Success() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, BillingStreet = '123 Main St.'));
        }
        insert testAccounts;

        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }

        Test.startTest();
        AccountActionsController.enqueueGeocodingJob(accountIds);
        Test.stopTest();

        //Verify that a queueable job was started
        List<AsyncApexJob> jobs = [SELECT Id, Status, ApexClass.Name FROM AsyncApexJob];

        System.assertEquals(1, jobs.size(), 'A queueable job should have been enqueued');
        
        }

    /**
     * @description Verifies that the method handles an empty list of Ids gracefully and does not enqueue a job.
     */
    @isTest
    static void testEnqueueGeocodingJob_EmptyList() {
        // Create an empty list
        List<Id> accountIds = new List<Id>();

        Test.startTest();
        AccountActionsController.enqueueGeocodingJob(accountIds);
        Test.stopTest();

        // Verify that no jobs were started
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob];
        System.assertEquals(0, jobs.size(), 'No jobs should be enqueued for an empty list.');
    }
}