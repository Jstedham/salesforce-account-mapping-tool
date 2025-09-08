@isTest
private class GeocodingService_Test {

    // --- MOCK CLASSES ---

    /**
     * @description A mock that provides a fake SUCCESSFUL response.
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
     * @description A mock that provides a fake FAILURE response.
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

    private class GeocodingMock_EmptyResult implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"addresses":[]}'); // Successful call, but no data
            res.setStatusCode(200);
            return res;
        }
    }

    // --- TEST METHODS ---

    /**
     * @description Tests the success scenario where the API returns a 200 status code.
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
        System.assert(caughtException instanceof AuraHandledException, 'Should be an AuraHandledException.');
        System.assertEquals('Address cannot be blank. Please provide a valid address.', caughtException.getMessage());
    }
}