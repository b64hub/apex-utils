public virtual class HttpClient implements IHttpClient.Callout, IHttpClient.Callback {
    List<Integer> statusCodes = new List<Integer>{ 200 };

    public class InvalidUrlException extends Exception {
    }

    public interface IUrl {
        String toString();
    }

    /**
     * @description URL class
     */
    public virtual class Url implements IUrl {
        String baseUrl;
        String path;
        Map<String, String> params = new Map<String, String>();

        public Url(String baseUrl) {
            this.baseUrl = baseUrl;
        }

        public override String toString() {
            String url = this.baseUrl;

            url += this.getPath();
            url += this.getQueryString();

            return url;
        }

        /**
         * @description Set the path
         * ! validatePath commented out, will throw error on paths from Nova_Proxy_Path__mdt
         */
        public void setPath(String path) {
            // this.validatePath(path);
            this.path = path;
        }

        /**
         * @description Get the path
         * ! Contains fixes for paths from Nova_Proxy_Path__mdt. In the future,
         * this should be removed and instead validated in the validatePath method
         *
         * @return String
         */
        public String getPath() {
            if (this.path == null) {
                return '';
            }

            // Fix paths from Nova_Proxy_Path__mdt
            if (path.substring(0, 1) != '/') {
                this.path = '/' + this.path;
            }

            if (path.substring(path.length() - 1) == '/') {
                this.path = path.substring(0, path.length() - 1);
            }

            return this.path;
        }

        private String getQueryString() {
            if (this.params.isEmpty()) {
                return '';
            }

            String queryString = '?';
            List<String> paramList = new List<String>();
            for (String key : this.params.keySet()) {
                paramList.add(key + '=' + this.params.get(key));
            }
            queryString += String.join(paramList, '&');

            return queryString;
        }

        public Map<String, String> getParams() {
            return this.params;
        }

        public void setParam(String key, String value) {
            this.params.put(key, value);
        }

        public void setParams(Map<String, String> params) {
            this.params.putAll(params);
        }

        /**
         * @description Recieves a list of paths, concats them all and makes sure they make a correct path
         * @param paths
         * @return String
         * @example `['api','method/','/ex/'] => /api/method/ex`
         */
        public String cleanPath(List<String> paths) {
            String clean = '';
            for (String path : paths) {
                clean += fixPath(path);
            }

            if (clean.substring(clean.length() - 1) == '/') {
                clean = clean.substring(0, clean.length() - 1);
            }

            clean = '/' + clean;

            return clean;
        }

        /**
         * @description Fixes a path, by making sure it doesnt start with '/'' and ends with '/'
         * @param path
         * @return String
         */
        public String fixPath(String path) {
            String ret = path;

            if (ret.substring(0, 1) == '/') {
                ret = ret.substring(1);
            }
            if (ret.substring(ret.length() - 1) != '/') {
                ret += '/';
            }
            return ret;
        }

        /**
         * @description Validate the path
         * ! To be implemented in the future, current implementation will break paths from Nova_Proxy_Path__mdt
         * @param path
         */
        protected void validatePath(String path) {
            if (path.substring(0, 1) != '/') {
                throw new InvalidUrlException(
                    'Path must start with a forward slash'
                );
            }

            if (path.substring(path.length() - 1) == '/') {
                throw new InvalidUrlException(
                    'Path must not end with a forward slash'
                );
            }
        }
    }

    public virtual class RequestBuilder {
        public HttpRequest request;
        private List<String> registeredHeaders = new List<String>();

        public RequestBuilder(HttpRequest request) {
            this.request = request;
        }

        public RequestBuilder() {
            this.request = new HttpRequest();
        }

        public virtual RequestBuilder fromConfig(CalloutConfig params) {
            if (params.method != null) {
                this.request.setMethod(params.method);
            }
            if (params.endpoint != null) {
                this.request.setEndpoint(params.endpoint);
            }
            if (params.timeout != null) {
                this.request.setTimeout(params.timeout);
            }
            if (params.body != null) {
                this.request.setBody(params.body);
            }
            if (params.headers != null) {
                this.setHeaders(params.headers);
            }
            return this;
        }

        public RequestBuilder setEndpoint(IUrl url) {
            this.request.setEndpoint(url.toString());
            return this;
        }

        public RequestBuilder setEndpoint(String url) {
            this.request.setEndpoint(url);
            return this;
        }

        public RequestBuilder setHeaders(Map<String, String> headers) {
            for (String key : headers.keySet()) {
                String headerValue = headers.get(key);
                if (headerValue == null) {
                    continue;
                }

                this.request.setHeader(key, headerValue);
                this.registeredHeaders.add(key);
            }

            return this;
        }

        /**
         * @description Serialize an object to JSON and set it as the request body
         * also sets the content type to application/json
         *
         * @param bodyObj
         */
        public RequestBuilder setJSONBody(Object bodyObj) {
            this.setContentType('json');
            this.request.setBody(JSON.serializePretty(bodyObj, true));

            return this;
        }

        /**
         * @description Short-hand support for setting the content type
         *
         * @param contentType
         */
        public RequestBuilder setContentType(String contentType) {
            String contentHeader;
            if (contentType.toLowerCase() == 'json') {
                contentHeader = 'application/json';
            } else if (contentType.toLowerCase() == 'xml') {
                contentHeader = 'application/xml';
            } else if (contentType.toLowerCase() == 'form') {
                contentHeader = 'application/x-www-form-urlencoded';
            } else {
                contentHeader = contentType;
            }

            if (contentHeader == null) {
                throw new InvalidUrlException('Unsupported content type');
            }

            this.request.setHeader('Content-Type', contentHeader);
            this.registeredHeaders.add('Content-Type');
            return this;
        }

        public HttpRequest getRequest() {
            return this.request;
        }

        public virtual String toJson() {
            CalloutConfig config = new CalloutConfig();
            config.method = this.request.getMethod();
            config.endpoint = this.request.getEndpoint();
            config.body = this.request.getBody();
            for (String key : this.registeredHeaders) {
                config.headers.put(key, this.request.getHeader(key));
            }

            return new JSONConfigParser().toJson(config);
        }

        public virtual RequestBuilder fromJson(String configJson) {
            return this.fromConfig(
                new JSONConfigParser()
                    .fromJson(configJson, HttpClient.CalloutConfig.class)
            );
        }
    }

    public HttpResponse get(HttpRequest request) {
        return this.callout('GET', request);
    }

    public HttpResponse post(HttpRequest request) {
        return this.callout('POST', request);
    }

    public HttpResponse put(HttpRequest request) {
        return this.callout('PUT', request);
    }

    public HttpResponse callout(String method, HttpRequest request) {
        request.setMethod(method);
        return this.callout(request);
    }

    public virtual HttpResponse callout(HttpRequest request) {
        Logger.info('Making callout ' + request.toString());
        return new Http().send(request);
    }

    public void setStatusCodes(List<Integer> statusCodes) {
        this.statusCodes = statusCodes;
    }

    public void callback(HttpResponse response) {
        this.handleResponse(response);
    }

    public virtual void handleResponse(HttpResponse response) {
        if (!statusCodes.contains(response.getStatusCode())) {
            throw new CalloutException(
                'Callout failed with status code ' + response.getStatusCode()
            );
        }
    }

    public class JSONConfigParser {
        public CalloutConfig fromJson(String configJson, Type configType) {
            CalloutConfig config = (CalloutConfig) JSON.deserialize(
                configJson,
                configType
            );
            config.headers = this.getHeadersFromJson(configJson);
            return config;
        }

        private Map<String, String> getHeadersFromJson(String configJson) {
            Map<String, Object> sourceHeaders = (Map<String, Object>) ((Map<String, Object>) JSON.deserializeUntyped(
                    configJson
                ))
                .get('headers');

            Map<String, String> headers = new Map<String, String>();
            if (sourceHeaders == null) {
                return headers;
            }

            for (String key : sourceHeaders.keySet()) {
                headers.put(key, String.valueOf(sourceHeaders.get(key)));
            }

            return headers;
        }

        public String toJson(CalloutConfig config) {
            return JSON.serialize(config);
        }
    }

    public virtual class CalloutConfig {
        public String method;
        public String endpoint;
        public Map<String, String> headers = new Map<String, String>();
        public String body;
        public Integer timeout = 120000;
    }

    public class AsyncCalloutConfig extends CalloutConfig {
        public String callbackClass = 'HttpClient';
    }

    @Future(callout=true)
    public static void asyncCallout(String asyncConfigJson) {
        Logger.info('Making async callout ' + asyncConfigJson);
        try {
            ((HttpClient) TypeFactory.newInstance('HttpClient'))
                .doAsyncCallout(asyncConfigJson);
        } catch (Exception e) {
            Logger.error(e.getMessage());
        }
    }

    /**
     * @description Make an async callout
     *
     * @param config
     */
    @TestVisible
    private void doAsyncCallout(String configJson) {
        AsyncCalloutConfig config = (AsyncCalloutConfig) new JSONConfigParser()
            .fromJson(configJson, HttpClient.AsyncCalloutConfig.class);

        System.debug(config);

        HttpRequest request = new HttpClient.RequestBuilder(new HttpRequest())
            .fromConfig(config)
            .getRequest();

        HttpResponse response = new HttpClient().callout(request);

        if (config.callbackClass == null) {
            return;
        }

        IHttpClient.Callback callback = (IHttpClient.Callback) TypeFactory.newInstance(
            config.callbackClass
        );
        callback.callback(response);
    }

    /**
     * @description Retry a callout
     *
     * @param request
     */
    public void retry(HttpRequest request) {
        String asyncConfigJson = new RequestBuilder(request).toJson();
        Logger.info('Retrying callout ' + asyncConfigJson);
        HttpClient.asyncCallout(asyncConfigJson);
    }
}
