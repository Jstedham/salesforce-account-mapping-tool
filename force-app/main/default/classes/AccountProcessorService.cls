/**
 * @description A reusable service class for processing lists of Accounts.
 * @author Jason Stedham
 * @date 2025-09-18
 */
public with sharing class AccountProcessorService {

    /**
     * @description A Data Transfer Object (DTO) that encapsulates the results of the geocoding process, including updated records and processing metrics.
     */
    public class GeocodeAccountsResult {
        @AuraEnabled public Integer recordsProcessed = 0;
        @AuraEnabled public Integer recordsFailed = 0;
        @AuraEnabled public List<String> errorMessages = new List<String>();
        @AuraEnabled public List<Account> accountsToUpdate = new List<Account>();
    }
    
    /**
     * @description Processes a list of accounts to add geocoding information.
     * It iterates through the records, calls the GeocodingService, and updates the records.
     * @param accountsToProcess The list of Account records to process.
     * @return A 'GeocodeAccountsResult' object containing the successfully geocoded accounts and processing metrics.
     */
    public static GeocodeAccountsResult geocodeAccounts(List<Account> accountsToProcess) {
        GeocodeAccountsResult result = new GeocodeAccountsResult();

        for(Account acc : accountsToProcess) {
            result.recordsProcessed++;
            String fullAddress = buildAddressString(acc);

            if (String.isNotBlank(fullAddress)) {
                try {
                    GeocodingService.GeocodeResponse response = GeocodingService.getCoordinates(fullAddress);

                    if (response != null) {
                        acc.BillingLatitude = response.latitude;
                        acc.BillingLongitude = response.longitude;
                        result.accountsToUpdate.add(acc);
                    }
                } catch (Exception e) {
                    result.recordsFailed++;
                    result.errorMessages.add('Failed to geocode Account: ' + acc.Name + ' (Id: ' + acc.Id + '). Reason: ' + e.getMessage());
                }
            }
        }
        return result;
    }

    /**
     * @description A helper method to construct a single, clean address string for the GeocodingService from an Account's billing address fields, handling any null values.
     * @param acc The Account record.
     * @return A formatted address string that the GeocodingService expects.
     */
    private static String buildAddressString(Account acc) {
        List<String> addressParts = new List<String>();
        if (String.isNotBlank(acc.BillingStreet)) addressParts.add(acc.BillingStreet);
        if (String.isNotBlank(acc.BillingCity)) addressParts.add(acc.BillingCity);
        if (String.isNotBlank(acc.BillingState)) addressParts.add(acc.BillingState);
        if (String.isNotBlank(acc.BillingPostalCode)) addressParts.add(acc.BillingPostalCode);
        if (String.isNotBlank(acc.BillingCountry)) addressParts.add(acc.BillingCountry);

        return String.join(addressParts, ', ');
    }
}