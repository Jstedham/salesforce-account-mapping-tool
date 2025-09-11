@isTest
private class GeocodingService_Test {

    //////////////// --- MOCK CLASSES --- ///////////////////////

    /**
     * @description A mock that provides a fake SUCCESSFUL response with valid coordinates.
     * Simulates a 200 OK status code.
     */
    private class GeocodingMock_Success implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String fakeJsonBody = '{"addresses":[{"latitude":40.7486, "longitude":-73.9856}]}';
            res.setBody(fakeJsonBody);

            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * @description A mock that provides a fake FAILURE response from the API.
     * Simulates a 403 Forbidden status code.
     */
    private class GeocodingMock_Failure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String fakeJsonBody = '{"meta":{"code":403,"message":"Forbidden"}}';
            res.setBody(fakeJsonBody);

            res.setStatusCode(403); // Simulate a "Forbidden" error
            return res;
        }
    }

    /**
     * @description A mock that simulates a successful (200) API response that contains an empty
     * list of addresses, representing a valid query with no results found.
     */
    private class GeocodingMock_EmptyResult implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"addresses":[]}'); // Successful call, but no data
            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * @description A mock that simulates a System.CalloutException, representing a
     * network failure where the request could not be sent.
     */
    private class GeocodingMock_Callout_NetworkFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException('Unable to send request');
        }
    }

    ///////////////// --- TEST METHODS --- /////////////////////////

    /**
     * @description Tests private constructor is correctly instantiating.
     */
    @isTest
    static void testPrivateConstructor() {
        Test.startTest();
        GeocodingService instance = new GeocodingService();
        Test.stopTest();

        System.assertNotEquals(null, instance, 
            'An instance should be created successfully within a test context.');
    }

    /**
     * @description Tests the success scenario where the API returns a 200 status code
     * and a valid address payload. Verifies that the latitude and longitude are parsed correctly.
     */
    @isTest
    static void testGetCoordinates_Success() {
        Test.setMock(HttpCalloutMock.class, new GeocodingMock_Success());

        Test.startTest();
        GeocodingService.GeocodeResponse result = GeocodingService.getCoordinates('20 W 34th St, New York, NY');
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null on a successful callout.');
        System.assertEquals(40.7486, result.latitude, 'The latitude should match the value from the mock response.');
        System.assertEquals(-73.9856, result.longitude, 'The longitude should match the value from the mock response.');

    }

    /**
     * @description Verifies that the service correctly handles a non-200 HTTP status code from the
     * API by throwing a GeocodingException with a message containing the error code.
     */
    @isTest
    static void testGetCoordinates_ApiFailure() {
        Test.setMock(HttpCalloutMock.class, new GeocodingMock_Failure());
        Exception caughtException = null;

        Test.startTest();
        try {
            GeocodingService.getCoordinates('An invalid address');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();
        
        System.assertNotEquals(null, caughtException, 'An exception should have been thrown.');
        
        System.assert(
            caughtException instanceof GeocodingService.GeocodingException,
            'The thrown exception should be our custom GeocodingException type.'
        );
        
        System.assert(
            caughtException.getMessage().contains('API failed with status code 403'),
            'The error message should contain the status code from the mock.'
        );
    }

    /**
     * @description Verifies that the service throws a GeocodingException when the API returns
     * a 200 OK status but the response body contains no address data.
     */
    @isTest
    static void testGetCoordinates_EmptyResult() {
        Test.setMock(HttpCalloutMock.class, new GeocodingMock_EmptyResult());
        Exception caughtException = null;

        Test.startTest();
        try {
            GeocodingService.getCoordinates('An address that does not exist');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();
        
        System.assertNotEquals(null, caughtException, 'An exception should have been thrown.');
        
        System.assert(
            caughtException instanceof GeocodingService.GeocodingException,
            'The thrown exception should be our custom GeocodingException type.'
        );
        
        System.assert(
            caughtException.getMessage().contains('no address was found'),
            'The error message should indicate that no address was found.'
        );
    }

    /**
     * @description Verifies that passing a null or blank address string correctly triggers
     * an AuraHandledException, preventing a callout from being made.
     */
    @isTest
    static void testGetCoordinates_BlankAddress_ThrowsException() {
        Exception caughtException = null;
        try {
            Test.startTest();
            GeocodingService.getCoordinates('');
            Test.stopTest();
        } catch (Exception e) {
            caughtException = e;
        }

        System.assertNotEquals(null, caughtException, 'An exception should have been thrown.');
        System.assert(
            caughtException instanceof GeocodingService.GeocodingException,
            'The thrown exception should be our custom GeocodingException type.'
        );
        System.assertEquals('Address cannot be blank. Please provide a valid address.', caughtException.getMessage());
    }

    /**
     * @description Verifies that a System.CalloutException (e.g., a network error)
     * is caught and re-thrown as a custom GeocodingException.
     */
    @isTest
    static void testGetCoordinates_NetworkError() {
        Test.setMock(HttpCalloutMock.class, new GeocodingMock_Callout_NetworkFailure());
        Exception caughtException = null;

        Test.startTest();
        
        try {
            GeocodingService.getCoordinates('20 W 34th St, New York, NY');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'An exception should have been thrown.');

        System.assert(
            caughtException instanceof GeocodingService.GeocodingException,
            'The thrown exception should be our custom GeocodingException type.'
        );

        System.assert(
            caughtException.getMessage().contains('A network error occurred'),
            'The error message should indicate a network error.'
        );
    }
}