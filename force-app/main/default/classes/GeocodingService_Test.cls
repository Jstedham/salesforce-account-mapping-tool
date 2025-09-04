@isTest
private class GeocodingService_Test {
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

    private class GeocodingMock_Failure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String fakeJsonBody = '{"meta":{"code":404, "message":"Address Not Found"}}';
            res.setBody(fakeJsonBody);

            res.setStatusCode(404);
            return res;
        }
    }

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
    static void testGetCoordinates_Failure() {
        Test.setMock(HttpCalloutMock.class, new GeocodingMock_Failure());

        Test.startTest();
        GeocodingService.GeocodeResponse result = GeocodingService.getCoordinates('An invalid address');
        Test.stopTest();
        
        System.assertEquals(null, result, 'The result should be null on a failed callout.');
    }
}