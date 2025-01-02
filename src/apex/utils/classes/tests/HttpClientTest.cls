@IsTest
public class HttpClientTest {
    public static final String CALLOUT_JSON =
        '{"timeout":120000,' +
        '"method":"GET",' +
        '"headers":{"Content-Type":"application/json"},' +
        '"endpoint":"https://www.example.com",' +
        '"body":"{\\"test\\": \\"hello\\"}"}';

    public static final String ASYNC_CALLOUT_JSON =
        '{"timeout":120000,' +
        '"method":"GET",' +
        '"headers":{"Content-Type":"application/json"},' +
        '"endpoint":"https://www.example.com",' +
        '"body":"{\\"test\\": \\"hello\\"}",' +
        '"callbackClass":"HttpClient"}';

    @IsTest
    static void testCreateUrl() {
        HttpClient.Url url = new HttpClient.Url('https://www.example.com');
        url.setPath('/path');
        url.setParam('test', '5');
        url.setParams(new Map<String, String>{ 'test2' => 'hello' });

        Assert.areEqual(
            'https://www.example.com/path?test=5&test2=hello',
            url.toString()
        );
    }

    public class TestJsonBody {
        public String test = 'hello';
        public Integer num = 5;
        public String empty;
    }

    @IsTest
    static void testCreateRequest() {
        HttpRequest request = new HttpClient.RequestBuilder()
            .setEndpoint(new HttpClient.Url('https://www.example.com'))
            .setJSONBody(new TestJsonBody())
            .getRequest();

        Assert.areEqual('https://www.example.com', request.getEndpoint());
        Assert.areEqual(
            JSON.serializePretty(new TestJsonBody(), true),
            request.getBody()
        );
        Assert.areEqual('application/json', request.getHeader('Content-Type'));
    }

    @IsTest
    static void testRequestToJson() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://www.example.com');
        request.setBody('{"test": "hello"}');

        HttpClient.RequestBuilder builder = new HttpClient.RequestBuilder(
            request
        );
        String requestJson = builder.setContentType('json').toJson();

        Assert.areEqual(CALLOUT_JSON, requestJson);
    }

    @IsTest
    static void testRequestFromJson() {
        HttpRequest request = new HttpClient.RequestBuilder()
            .fromJson(CALLOUT_JSON)
            .getRequest();

        Assert.areEqual('GET', request.getMethod());
        Assert.areEqual('https://www.example.com', request.getEndpoint());
        Assert.areEqual('{"test": "hello"}', request.getBody());
        Assert.areEqual('application/json', request.getHeader('Content-Type'));
    }

    @IsTest
    static void testConfigFromJson() {
        HttpClient.CalloutConfig config = (HttpClient.CalloutConfig) new HttpClient.JSONConfigParser()
            .fromJson(CALLOUT_JSON, HttpClient.CalloutConfig.class);

        Assert.areEqual('GET', config.method);
        Assert.areEqual('https://www.example.com', config.endpoint);
        Assert.areEqual('{"test": "hello"}', config.body);
        Assert.areEqual('application/json', config.headers.get('Content-Type'));
        Assert.areEqual(120000, config.timeout);

        HttpClient.AsyncCalloutConfig asyncConfig = (HttpClient.AsyncCalloutConfig) new HttpClient.JSONConfigParser()
            .fromJson(ASYNC_CALLOUT_JSON, HttpClient.AsyncCalloutConfig.class);

        Assert.areEqual('GET', asyncConfig.method);
        Assert.areEqual('https://www.example.com', asyncConfig.endpoint);
        Assert.areEqual('{"test": "hello"}', asyncConfig.body);
        Assert.areEqual(
            'application/json',
            asyncConfig.headers.get('Content-Type')
        );
        Assert.areEqual(120000, asyncConfig.timeout);
        Assert.areEqual('HttpClient', asyncConfig.callbackClass);
    }

    @IsTest
    static void testConfigToJson() {
        HttpClient.CalloutConfig config = new HttpClient.CalloutConfig();

        config.method = 'GET';
        config.endpoint = 'https://www.example.com';
        config.body = '{"test": "hello"}';
        config.headers.put('Content-Type', 'application/json');
        config.timeout = 120000;

        Assert.areEqual(
            CALLOUT_JSON,
            new HttpClient.JsonConfigParser().toJson(config)
        );

        HttpClient.AsyncCalloutConfig asyncConfig = new HttpClient.AsyncCalloutConfig();

        asyncConfig.method = 'GET';
        asyncConfig.endpoint = 'https://www.example.com';
        asyncConfig.body = '{"test": "hello"}';
        asyncConfig.headers.put('Content-Type', 'application/json');
        asyncConfig.timeout = 120000;
        asyncConfig.callbackClass = 'HttpClient';

        Assert.areEqual(
            ASYNC_CALLOUT_JSON,
            new HttpClient.JsonConfigParser().toJson(asyncConfig)
        );
    }

    public class MockHttpResponse implements HttpCalloutMock {
        Boolean hasResponded = false;
        HttpRequest inputRequest;

        public HttpResponse respond(HttpRequest request) {
            this.inputRequest = request;

            HttpResponse response = new HttpResponse();
            response.setBody('{"test": "hello"}');
            response.setStatusCode(200);
            this.hasResponded = true;

            return response;
        }
    }

    @IsTest
    static void testGet() {
        HttpRequest request = new HttpRequest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        HttpClient client = new HttpClient();
        HttpResponse response = client.get(request);
        Test.stopTest();

        Assert.areEqual('GET', request.getMethod());
        Assert.areEqual('{"test": "hello"}', response.getBody());
        Assert.areEqual(200, response.getStatusCode());
    }

    @IsTest
    static void testPost() {
        HttpRequest request = new HttpRequest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        HttpClient client = new HttpClient();
        HttpResponse response = client.post(request);
        Test.stopTest();

        Assert.areEqual('POST', request.getMethod());
        Assert.areEqual('{"test": "hello"}', response.getBody());
        Assert.areEqual(200, response.getStatusCode());
    }

    @IsTest
    static void testPut() {
        HttpRequest request = new HttpRequest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        HttpClient client = new HttpClient();
        HttpResponse response = client.put(request);
        Test.stopTest();

        Assert.areEqual('PUT', request.getMethod());
        Assert.areEqual('{"test": "hello"}', response.getBody());
        Assert.areEqual(200, response.getStatusCode());
    }

    @IsTest
    static void testHandleResponseException() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);

        HttpClient client = new HttpClient();
        client.setStatusCodes(new List<Integer>{ 200, 201 });

        Test.startTest();
        try {
            client.callback(response);
            Assert.isTrue(false);
        } catch (CalloutException e) {
            Assert.areEqual(
                'Callout failed with status code 400',
                e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testHandleResponseSuccess() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);

        HttpClient client = new HttpClient();
        client.setStatusCodes(new List<Integer>{ 200, 201 });

        Test.startTest();
        client.callback(response);
        Test.stopTest();
    }

    @IsTest
    static void testAsyncCalloutFuture() {
        MockHttpResponse responder = new MockHttpResponse();
        Test.setMock(HttpCalloutMock.class, responder);

        String asyncConfigJson = '{"method":"GET","endpoint":"https://www.example.com"}';
        Test.startTest();
        HttpClient.asyncCallout(asyncConfigJson);
        Test.stopTest();

        Assert.isTrue(responder.hasResponded);
        Assert.areEqual(
            responder.inputRequest.getEndpoint(),
            'https://www.example.com'
        );
        Assert.areEqual(responder.inputRequest.getMethod(), 'GET');
    }

    public class MockCallback implements IHttpClient.Callback {
        Boolean called = false;
        public void callback(HttpResponse response) {
            this.called = true;
        }
    }

    @IsTest
    static void testAsyncCallout() {
        MockCallback mockCallback = new MockCallback();
        TypeFactory.setMock('HttpClient', mockCallback);

        HttpClient.AsyncCalloutConfig config = new HttpClient.AsyncCalloutConfig();
        config.method = 'GET';
        config.endpoint = 'https://www.example.com';
        config.headers = new Map<String, String>{
            'Content-Type' => 'application/json',
            'Accept' => '*/*'
        };
        config.body = '{"test": "hello"}';
        config.callbackClass = 'HttpClient';

        MockHttpResponse responder = new MockHttpResponse();
        Test.setMock(HttpCalloutMock.class, responder);

        Test.startTest();
        HttpClient client = new HttpClient();
        client.doAsyncCallout(new HttpClient.JSONConfigParser().toJson(config));
        Test.stopTest();

        Assert.isTrue(responder.hasResponded);
        Assert.isTrue(mockCallback.called);
    }

    @IsTest
    static void testRetry() {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://www.example.com');

        MockHttpResponse responder = new MockHttpResponse();
        Test.setMock(HttpCalloutMock.class, responder);

        HttpClient client = new HttpClient();
        Test.startTest();
        client.retry(request);
        Test.stopTest();

        Assert.areEqual(
            responder.inputRequest.getMethod(),
            request.getMethod()
        );
        Assert.areEqual(
            responder.inputRequest.getEndpoint(),
            request.getEndpoint()
        );
    }
}
