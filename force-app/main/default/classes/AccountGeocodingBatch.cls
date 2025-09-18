/**
 * @description A stateful batch job that finds Accounts missing geolocations,
 * uses the GeocodingService to enrich them, and maintains a summary of successes and failures to be emailed upon completion.
 * @author Jason Stedham
 * @date 2025-09-11
 */
public class AccountGeocodingBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    // Stateful member variables to hold data for the summary email once the batch job is complete.
    private Integer recordsProcessed = 0;
    private Integer recordsFailed = 0;
    private List<String> errorMessages = new List<String>();

    /**
     * @description Gathers the Accounts that have a Billing Street but are missing a Billing Latitude.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, BillingStreet, BillingCity, BillingState,BillingPostalCode, BillingCountry FROM Account WHERE BillingLatitude = NULL AND BillingStreet != NULL';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
    
        AccountProcessorService.GeocodeAccountsResult result = AccountProcessorService.geocodeAccounts(scope);

        // Update stateful variables with the results from the service
        recordsProcessed += result.recordsProcessed;
        recordsFailed += result.recordsFailed;
        errorMessages.addAll(result.errorMessages);

        // Update accounts after processing
        if(!result.accountsToUpdate.isEmpty()) {
        Database.update(result.accountsToUpdate, false);
        }
}
    /**
     * @description Sends a summary email after all batches are processed with the results and any errors that were collected.
     * @param bc The context for the batch job.
     */
    public void finish(Database.BatchableContext bc) {
        // Query for the job's details to find the user who started it
        AsyncApexJob job = [SELECT Id, Status, CreatedById, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

        // Build summary subject and email body:
        String subject = 'Account Geocoding Batch Completed - ' + job.Status;
        List<String> bodyLines = new List<String>();
        bodyLines.add('The Account Geocoding batch job has completed.');
        bodyLines.add(''); //Blank line for spacing
        bodyLines.add('Status: ' + job.Status);
        bodyLines.add('Total Records Processed: ' + recordsProcessed);
        bodyLines.add('Successful Updates: ' + (recordsProcessed - recordsFailed));
        bodyLines.add('Failed Records: ' + recordsFailed);
        bodyLines.add('');

        // If we caught any errors, list them in the email
        if (!errorMessages.isEmpty()) {
            bodyLines.add('---Failure Details ---');
            for (String err : errorMessages) {
                bodyLines.add(err);
            }
        }

        // Send the summary email

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { job.CreatedBy.Email});
        mail.setSubject(subject);
        // Join the email body list into a single string with newline characters
        mail.setPlainTextBody(String.join(bodyLines, '\n'));
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

}