public with sharing class GeocodingService {
    private GeocodingService() {

    }

    public class GeocodeResponse {
        @AuraEnabled public Double latitude;
        @AuraEnabled public Double longitude;
    }

    public class GeocodingException extends Exception {}

    @AuraEnabled(cacheable=false)
    public static GeocodeResponse getCoordinates(String address) {
        if(String.isBlank(address)) {
            AuraHandledException ae = new AuraHandledException('Address cannot be blank. Please provide a valid address.');
            ae.setMessage('Address cannot be blank. Please provide a valid address.');
            throw ae;
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

    @TestVisible
    private class RadarResponseParser {
        public List<AddressWrapper> addresses;

    }

    @TestVisible
    private class AddressWrapper {
            public Double latitude;
            public Double longitude;
        }

}