/**
 * @description An invocable Apex class that allows a Flow to initiate an
 * asynchronous geocoding job for a list of Account records.
 * @author Jason Stedham
 */
public with sharing class AccountGeocodingInvocable {
    /**
     * @description Invocable Action for Flows to start the geocoding process for a list of accounts.
     * @param requests A list of Account record Ids passed from a Flow.
     */
    @InvocableMethod(label='Enqueue Geocoding for Accounts' description='Takes a list of Account Ids and starts an asynchronous job to add geocoding information.')
    public static void enqueueGeocodingForFlow(List<List<String>> requests) {

        List<Id> allAccountIds = new List<Id>();

        // Flows pass a list of requests. We need to iterate through them
        // and collect all the Ids into a single list.
        if (requests != null && !requests.isEmpty()) {
            for (List<String> accountIdStrings : requests) {
                for(String strId : accountIdStrings){
                    allAccountIds.add((Id)strId);
                }
            }
        }
        // Call the helper method with the flattened list of Ids
        if(!allAccountIds.isEmpty()){
             enqueueGeocodingJob(allAccountIds);
        }
    }

    /**
     * @description A private helper method that enqueues the queueable job to perform the geocoding callouts.
     * @param accountIds A list of Account record Ids to be processed.
     */
    private static void enqueueGeocodingJob(List<Id> accountIds){
        // Enqueue the Queueable job to process the accounts
        if (accountIds != null && !accountIds.isEmpty()) {
            try{
                System.enqueueJob(new AccountGeocodingQueueable(accountIds));
            } catch (Exception e) {
                // Throw a custom exception that the flow can handle
                throw new GeocodingInvocableException('Failed to start the geocoding job. Reason: ' + e.getMessage());
            }
        }
    }

    /**
    * @description Custom exception class for the invocable action.
    */
    public class GeocodingInvocableException extends Exception {}
}