@isTest
private class AsyncHttpClientTest {
    static Integer callbackCounter = 0;

    @TestSetup
    static void disableLogging() {
        LoggerSettings__c settings = new LoggerSettings__c();
        settings.IsEnabled__c = false;

        insert settings;
    }

    public class MockHttpResponse implements HttpCalloutMock {
        HttpRequest expectedRequest;
        Map<String, String> expectedHeaders;
        private Integer statusCode;

        public MockHttpResponse(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);

            if (this.expectedRequest != null) {
                this.asyncAssert(req);
            }

            return res;
        }

        public void asyncAssert(HTTPRequest actualRequest) {
            Assert.areEqual(
                this.expectedRequest.getEndpoint(),
                actualRequest.getEndpoint(),
                'Endpoint should be preserved'
            );
            Assert.areEqual(
                this.expectedRequest.getMethod(),
                actualRequest.getMethod(),
                'Method should be preserved'
            );
            Assert.areEqual(
                this.expectedRequest.getBody(),
                actualRequest.getBody(),
                'Body should be preserved'
            );
            for (String headerName : this.expectedHeaders.keySet()) {
                Assert.areEqual(
                    this.expectedRequest.getHeader(headerName),
                    actualRequest.getHeader(headerName),
                    'Header ' + headerName + ' should be preserved'
                );
            }
        }

        public void expect(
            HTTPRequest expectedRequest,
            Map<String, String> expectedHeaders
        ) {
            this.expectedRequest = expectedRequest;
            this.expectedHeaders = expectedHeaders;
        }
    }

    @isTest
    static void testCallout() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://example.com');
        request.setMethod('GET');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200));

        Test.startTest();
        AsyncHttpClient.asyncCallout(request);
        Assert.areEqual(
            1,
            Limits.getQueueableJobs(),
            'Callout should be enqueued'
        );
        Test.stopTest();
    }

    public class TestCallback implements IHttpClient.Callback {
        Integer statusCode;
        String responseBody;
        Map<String, String> responseHeaders = new Map<String, String>();

        public void callback(HttpResponse response) {
            AsyncHttpClientTest.callbackCounter++;
            this.statusCode = response.getStatusCode();

            if (statusCode == 200) {
                this.responseBody = response.getBody();
            } else if (statusCode == 500) {
                throw new CalloutException('Callout failed');
            }
        }
    }

    @isTest
    static void testCalloutWithCallback() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://example.com');
        request.setMethod('GET');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200));

        AsyncHttpClientTest.callbackCounter = 0;
        Test.startTest();
        AsyncHttpClient.asyncCallout(request, new TestCallback());
        Assert.areEqual(
            1,
            Limits.getQueueableJobs(),
            'Callout should be enqueued'
        );
        Test.stopTest();

        Assert.areEqual(
            1,
            AsyncHttpClientTest.callbackCounter,
            'Callback should be called once'
        );
    }

    @isTest
    static void testRequestPreservation() {
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer token'
        };

        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://example.com');
        request.setMethod('POST');
        request.setBody('{"key": "value"}');
        for (String headerName : headers.keySet()) {
            request.setHeader(headerName, headers.get(headerName));
        }

        MockHttpResponse mock = new MockHttpResponse(200);
        mock.expect(request, headers);

        Test.setMock(HttpCalloutMock.class, mock);

        AsyncHttpClientTest.callbackCounter = 0;
        Test.startTest();

        AsyncHttpClient.Request asyncRequest = new AsyncHttpClient.Request(
            request
        );
        asyncRequest.setHeaders(headers);

        new AsyncHttpClient()
            .setCallback(new TestCallback())
            .callout(asyncRequest);

        Assert.areEqual(
            1,
            Limits.getQueueableJobs(),
            'Callout should be enqueued'
        );
        Test.stopTest();

        Assert.areEqual(
            1,
            AsyncHttpClientTest.callbackCounter,
            'Callback should be called once'
        );
    }

    @isTest
    static void testBackoff() {
        AsyncHttpClient.Backoff backoff = new AsyncHttpClient.Backoff();

        backoff.setDelay(1);
        Assert.areEqual(1, backoff.initialDelay, 'Initial delay should be 1');

        backoff.setStrategy(AsyncHttpClient.BackoffStrategy.LINEAR);
        Assert.areEqual(
            AsyncHttpClient.BackoffStrategy.LINEAR,
            backoff.strategy,
            'Strategy should be linear'
        );

        backoff.setMaxRetries(5);
        Assert.areEqual(5, backoff.maxRetries, 'Max retries should be 5');

        AsyncHttpClient client = new AsyncHttpClient();
        client.setBackoff(backoff);
        Assert.areEqual(backoff, client.backoff, 'Backoff should be set');
    }

    @isTest
    static void testRetry() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://example.com');
        request.setMethod('GET');

        MockHttpResponse mock = new MockHttpResponse(500);
        Test.setMock(HttpCalloutMock.class, mock);

        AsyncHttpClientTest.callbackCounter = 0;
        Test.startTest();

        AsyncHttpClient.Request asyncRequest = new AsyncHttpClient.Request(
            request
        );

        AsyncHttpClient.Backoff backoff = new AsyncHttpClient.Backoff();
        backoff.setDelay(1);
        backoff.setStrategy(AsyncHttpClient.BackoffStrategy.LINEAR);
        backoff.setMaxRetries(3);

        AsyncHttpClient client = new AsyncHttpClient();
        client.setBackoff(backoff);
        client.setCallback(new TestCallback());
        client.callout(asyncRequest);

        Assert.areEqual(
            1,
            Limits.getQueueableJobs(),
            'Callout should be enqueued'
        );
        Test.stopTest();

        Assert.areEqual(
            4,
            AsyncHttpClientTest.callbackCounter,
            'Callback should be called 4 times'
        );
    }
}
