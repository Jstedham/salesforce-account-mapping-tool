/**
 * @description A controller for Lightning Web Components to invoke actions on Account records.
 * @author Jason Stedham
 * @date 2025-09-19
 */
public with sharing class AccountActionsController {
    
    /**
     * @description Receives a list of Account Ids from an LWC that need to be enriched with geocode information and enqueues a queueable job to perform the geocoding callouts.
     * @param accountIds A list of Account record Ids to be processed.
     */
    @AuraEnabled
    public static void enqueueGeocodingJob(List<Id> accountIds){
        // Enqueue the Queueable job to process the accounts
        if (accountIds != null && !accountIds.isEmpty()) {
            System.enqueueJob(new GeocodeAccountsQueueable(accountIds));
        }
    }

    /**
     * @description A queueable job that processes a list of Accounts to add geocoding information. This runs asynchronously to handle the callouts.
     */
    // A Queueable inner class to handle the callouts
    public class GeocodeAccountsQueueable implements Queueable, Database.AllowsCallouts {
        private List<Id> accountIds;

        /**
         * @description Constructor for the queueable job.
         * @param accountIds The list of Account Ids that this job will process.
         */
        public GeocodeAccountsQueueable(List<Id> accountIds) {
            this.accountIds = accountIds;
        }

        /**
         * @description The main execution logic for the job. It queries the accounts, delegates to the AccountProcessorService, and updates the records.
         * @param context The context for the queueable job.
         */
        public void execute(QueueableContext context) {

        if (this.accountIds != null && !this.accountIds.isEmpty()) {
            // Query the accounts to be processed
            List<Account> accountsToProcess = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE Id IN :accountIds];

                if(!accountsToProcess.isEmpty()) {
                // Call service to handle the processing
                AccountProcessorService.GeocodeAccountsResult result = AccountProcessorService.geocodeAccounts(accountsToProcess);

                // Update the accounts with Geocode information
                    if (!result.accountsToUpdate.isEmpty()) {
                Database.update(result.accountsToUpdate, false);
                    }
                }
            }
        }
    }
}