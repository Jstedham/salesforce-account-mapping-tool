public with sharing class GeocodingService {
    private GeocodingService() {

    }

    public class GeocodeResponse {
        public Double latitude;
        public Double longitude;
    }

    public static GeocodeResponse getCoordinates(String address) {
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
            }
        } else {
            System.debug('Geocoding callout failed. Status: ' +
            response.getStatus() +
            ' Status Code: ' +
            response.getStatusCode());
        }
    } catch (System.CalloutException e) {
        System.debug('Callout error: ' + e.getMessage());
    }
        return null;
    }

    private class RadarResponseParser {
        public List<AddressWrapper> addresses;

    }

    private class AddressWrapper {
            public Double latitude;
            public Double longitude;
        }

}