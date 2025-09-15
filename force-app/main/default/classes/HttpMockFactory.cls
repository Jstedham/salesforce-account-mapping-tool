/**
 * @description A centralized factory for creating HTTPCalloutMock instances for all callouts within the org. This utlity provides both specific, named mocks for common scenarios and a generic mock for testing edge cases.
 * @author Jason Stedham
 * @date 2025-09-11
 */

@isTest
public with sharing class HttpMockFactory {
    
    // -- The Core Mocking Engine ---
    // This configurable mock is the single implementation used by all factory methods.
    private class ConfigurableMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final String responseBody;

        private ConfigurableMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.responseBody);
            res.setStatusCode(this.statusCode);
            return res;
        }
    }

    private class ExceptionThrowingMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException('Unable to send request');
        }
    }

    /**
     * @description A generic factory method for creating a mock for any scenario.
     * @param statusCode The HTTP status code for the response.
     * @param body The string body of the response.
     * @return A fully configured HttpCalloutMock instance.
     */
    public static HttpCalloutMock createGenericMock(Integer statusCode, String body) {
        return new ConfigurableMock(statusCode, body);
    }

    

    /*
    =============================================================================
    --- Geocoding Service Mocks
    --- Mocks used for testing callouts from the GeocodingService class.
    =============================================================================
    */

    /**
     * @description A mock that provides a fake SUCCESSFUL response with valid coordinates.
     * Simulates a 200 OK status code.
     */
    public static HttpCalloutMock createGeocodingSuccessMock() {
        return new ConfigurableMock(200,'{"addresses":[{"latitude":40.7486, "longitude":-73.9856}]}');
    }

    /**
     * @description A mock that provides a fake FAILURE response from the API.
     * Simulates a 403 Forbidden status code.
     */
    public static HttpCalloutMock createGeocodingFailureMock() {
        return new ConfigurableMock(403, '{"meta":{"code":403,"message":"Forbidden"}}');
    }

    /**
     * @description A mock that simulates a successful (200) API response that contains an empty
     * list of addresses, representing a valid query with no results found.
     */
    public static HttpCalloutMock createGeocodingEmptyResultMock() {
        return new ConfigurableMock(200, '{"addresses":[]}'); // Successful call, but no data
    }

    /**
     * @description A mock that simulates a System.CalloutException, representing a
     * network failure where the request could not be sent.
     */
    public static HttpCalloutMock createGeocodingNetworkFailureMock() {
        return new ExceptionThrowingMock();
    }

}