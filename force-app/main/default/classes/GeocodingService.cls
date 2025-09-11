/**
 * @description A reusable utility class for making geocoding callouts to the Radar API.
 * This service is designed to be called from LWC or other Apex classes to convert
 * a string address into geographic coordinates (latitude and longitude).
 * @author Jason Stedham
 * @date 2025-09-08
 */
public with sharing class GeocodingService {

    // A private constructor prevents this class from ever being instantiated,
    // enforcing its use as a static utility class.
    @TestVisible
    private GeocodingService() {

    }

    /**
     * @description A Data Transfer Object (DTO) that represents the successful
     * result of a geocoding callout. This is the object returned to the caller.
     */
    public class GeocodeResponse {
        @AuraEnabled public Double latitude;
        @AuraEnabled public Double longitude;
    }
    
    // Custom exception for this service
    public class GeocodingException extends Exception {}

    /**
     * @description Performs a geocoding callout to the Radar API to convert a physical address string
     * into geographic coordinates.
     * @param address The physical address to geocode (e.g., '20 W 34th St, New York, NY').
     * @return A 'GeocodeResponse' object containing the latitude and longitude of the first address match.
     * @throws GeocodingException if input address is null or blank, for network errors, non-200 HTTP status codes, or if the API finds no matching address.
     */

    public static GeocodeResponse getCoordinates(String address) {
        if(String.isBlank(address)) {
            throw new GeocodingException('Address cannot be blank. Please provide a valid address.');
        }

        String encodedAddress = EncodingUtil.urlEncode(address, 'UTF-8');

        HttpRequest request = new HttpRequest();

        String endpoint = 'callout:Radar_IO_API_Geocode_Forwarding_NamedCred?query=' + encodedAddress;
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setTimeout(10000);

        Http http = new Http();

    try {
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            RadarResponseParser parsedResponse = (RadarResponseParser) JSON.deserialize(response.getBody(), RadarResponseParser.class);

            if(parsedResponse != null && !parsedResponse.addresses.isEmpty()) {
                GeocodeResponse res = new GeocodeResponse();
                res.latitude = parsedResponse.addresses[0].latitude;
                res.longitude = parsedResponse.addresses[0].longitude;
                System.debug('SUCCESS: ' + res);
                return res;
            } else {
                throw new GeocodingException('The API returned a successful response, but no address was found for the query.');
            }
        } else {
            String errorMessage = 'The Geocoding API failed with status code ' + response.getStatusCode() + '. Response: ' + response.getBody();
            throw new GeocodingException(errorMessage);
        }
    } catch (System.CalloutException e) {
            throw new GeocodingException('A network error occurred: ' + e.getMessage());
    }
}

// --- Private Inner Classes (Internal Implementation Details) ---

    /**
     * @description Internal DTO for deserializing the JSON response from the Radar API.
     * Its structure mirrors the API's JSON. It is kept private to encapsulate
     * the implementation details of the service call.
     */
    @TestVisible
    private class RadarResponseParser {
        public List<AddressWrapper> addresses;

    }

    /**
     * @description Represents the nested address object within the Radar API's JSON response.
     */
    @TestVisible
    private class AddressWrapper {
            public Double latitude;
            public Double longitude;
        }

}