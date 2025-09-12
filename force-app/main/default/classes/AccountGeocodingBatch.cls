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
        List<Account> accountsToUpdate = new List<Account>();

        for(Account acc : scope) {
            recordsProcessed++;
            String fullAddress = buildAddressString(acc);

            if (String.isNotBlank(fullAddress)) {
                try {
                    GeocodingService.GeocodeResponse response = GeocodingService.getCoordinates(fullAddress);

                    if (response != null) {
                        acc.BillingLatitude = response.latitude;
                        acc.BillingLongitude = response.longitude;
                        accountsToUpdate.add(acc);
                    }
                } catch (Exception e) {
                    recordsFailed++;
                    errorMessages.add('Failed to geocode Account: ' + acc.Name + ' (Id: ' + acc.Id + '). Reason: ' + e.getMessage());
                }
            } else {
                recordsFailed++;
                errorMessages.add(
                    'Skipped Account: ' + acc.Name + ' (Id: ' + acc.Id + ') due to a blank address.'
                );
        }
    } 

    // Update accounts after processing
    if(!accountsToUpdate.isEmpty()) {
        Database.update(accountsToUpdate, false);
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

    /**
     * @description A helper method to construct a single, clean address string for the GeocodingService from an Account's billing address fields, handling any null values.
     * @param acc The Account record.
     * @return A formatted address string that the GeocodingService expects.
     */
    private String buildAddressString(Account acc) {
        List<String> addressParts = new List<String>();
        if (String.isNotBlank(acc.BillingStreet)) addressParts.add(acc.BillingStreet);
        if (String.isNotBlank(acc.BillingCity)) addressParts.add(acc.BillingCity);
        if (String.isNotBlank(acc.BillingState)) addressParts.add(acc.BillingState);
        if (String.isNotBlank(acc.BillingPostalCode)) addressParts.add(acc.BillingPostalCode);
        if (String.isNotBlank(acc.BillingCountry)) addressParts.add(acc.BillingCountry);

        return String.join(addressParts, ', ');
    }
}