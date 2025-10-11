/**
 * @description A queueable Apex job that geocodes a small batch of Account records asynchronously.
 * It is designed for user-initiated requests, such as from a Flow, where the number of
 * records is limited. This job should process no more than 10 accounts at a time to
 * respect external API rate limits.
 * @author Jason Stedham
 */
public class AccountGeocodingQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> accountIds;

        /**
         * @description Constructor for the queueable job.
         * @param accountIds The list of Account Ids that this job will process.
         */
        public AccountGeocodingQueueable(List<Id> accountIds) {
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