public class AsyncHttpClient implements Queueable, Database.AllowsCallouts, IHttpClient.Callout {
    IHttpClient.Request asyncRequest;
    IHttpClient.Callback callback;

    public Backoff backoff = new Backoff();
    public String loggerTransactionId;
    public String LOG_TAG;

    public class Backoff {
        public Integer maxRetries = 3;
        public BackoffStrategy strategy = BackoffStrategy.CONSTANT;
        public Integer initialDelay = 0;

        public void setMaxRetries(Integer maxRetries) {
            this.maxRetries = maxRetries;
        }

        public void setStrategy(BackoffStrategy strategy) {
            this.strategy = strategy;
        }

        public void setDelay(Integer delay) {
            this.initialDelay = delay;
        }

        public Integer getStackDepth() {
            return this.maxRetries + 1;
        }

        /**
         * Get delay based on the strategy
         * Delays are in minutes, an exponential backoff strategy would be too aggressive
         *
         * @return Integer - delay in minutes
         */
        private Integer getDelay() {
            if (this.strategy == BackoffStrategy.LINEAR) {
                return AsyncInfo.getMinimumQueueableDelayInMinutes() + 1;
            }

            if (this.strategy == BackoffStrategy.CONSTANT) {
                return AsyncInfo.getMinimumQueueableDelayInMinutes();
            }

            return 0;
        }
    }

    public enum BackoffStrategy {
        LINEAR,
        CONSTANT,
        NONE
    }

    /**
     * @description Serializable request object
     */
    public virtual class Request implements IHttpClient.Request {
        public String method;
        public String endpoint;
        public Map<String, String> headers = new Map<String, String>();
        public String body;
        public Integer timeout = 120000;

        public Request() {
        }

        public Request(HttpRequest request) {
            this.method = request.getMethod();
            this.endpoint = request.getEndpoint();
            this.body = request.getBody();
        }

        public void setHeaders(Map<String, String> headers) {
            this.headers = headers;
        }

        /**
         * @description Writes request properties to an HttpRequest object
         */
        public virtual void toHttpRequest(HttpRequest request) {
            if (this.method != null) {
                request.setMethod(this.method);
            }
            if (this.endpoint != null) {
                request.setEndpoint(this.endpoint);
            }
            if (this.timeout != null) {
                request.setTimeout(this.timeout);
            }
            if (this.body != null) {
                request.setBody(this.body);
            }
            if (this.headers != null) {
                for (String header : this.headers.keySet()) {
                    request.setHeader(header, this.headers.get(header));
                }
            }
        }
    }

    public AsyncHttpClient setCallback(IHttpClient.Callback callback) {
        this.callback = callback;
        return this;
    }

    public AsyncHttpClient setBackoff(Backoff backoff) {
        this.backoff = backoff;
        return this;
    }

    public static void asyncCallout(HttpRequest request) {
        new AsyncHttpClient().callout(new AsyncHttpClient.Request(request));
    }

    public static void asyncCallout(
        HttpRequest request,
        IHttpClient.Callback callback
    ) {
        new AsyncHttpClient()
            .setCallback(callback)
            .callout(new AsyncHttpClient.Request(request));
    }

    public static void asyncCallout(
        HttpRequest request,
        IHttpClient.Callback callback,
        Backoff backoff
    ) {
        new AsyncHttpClient()
            .setBackoff(backoff)
            .setCallback(callback)
            .callout(new AsyncHttpClient.Request(request));
    }

    /**
     * IHttpClient.Callout interface implementation
     * Caveat: Headers are not preserved using this method, use the AsyncHttpClient.Request object instead
     */
    public HttpResponse callout(HttpRequest request) {
        this.asyncRequest = new AsyncHttpClient.Request(request);
        callout();

        return new HttpResponse();
    }

    public void callout(IHttpClient.Request asyncRequest) {
        this.asyncRequest = asyncRequest;
        callout();
    }

    public void callout() {
        this.loggerTransactionId = Logger.getTransactionId();

        AsyncOptions asyncOptions = new AsyncOptions();
        asyncOptions.MaximumQueueableStackDepth = this.backoff.getStackDepth();
        asyncOptions.MinimumQueueableDelayInMinutes = this.backoff.initialDelay;

        System.enqueueJob(this, asyncOptions);
    }

    public void execute(QueueableContext context) {
        Logger.setParentLogTransactionId(this.loggerTransactionId);
        Logger.info(
                'Executing async callout request queueable job id: ' +
                context.getJobId()
            )
            .addTag(LOG_TAG);

        System.debug(
            'AsyncInfo.hasMaxStackDepth: ' + AsyncInfo.hasMaxStackDepth()
        );
        System.debug(
            'AsyncInfo.getCurrentQueueableStackDepth: ' +
            AsyncInfo.getCurrentQueueableStackDepth()
        );
        System.debug(
            'AsyncInfo.getMaximumQueueableStackDepth: ' +
            AsyncInfo.getMaximumQueueableStackDepth()
        );
        System.debug(
            'AsyncInfo.getMinimumQueueableDelayInMinutes: ' +
            AsyncInfo.getMinimumQueueableDelayInMinutes()
        );

        doCallout();
    }

    public void retry() {
        if (
            AsyncInfo.hasMaxStackDepth() &&
            AsyncInfo.getCurrentQueueableStackDepth() >=
            AsyncInfo.getMaximumQueueableStackDepth()
        ) {
            Logger.info(
                    'Max retries reached for request ' + this.backoff.maxRetries
                )
                .addTag(LOG_TAG);
            return;
        }

        AsyncOptions asyncOptions = new AsyncOptions();
        asyncOptions.MinimumQueueableDelayInMinutes = this.backoff.getDelay();

        System.enqueueJob(this, asyncOptions);
    }

    @TestVisible
    private void doCallout() {
        try {
            HttpRequest request = new HttpRequest();
            this.asyncRequest.toHttpRequest(request);

            HttpResponse response = new Http().send(request);
            this.handleResponse(response);
        } catch (Exception e) {
            Logger.error('Error sending HTTP request: ' + e.getMessage())
                .addTag(LOG_TAG);
        }

        Logger.saveLog();
    }

    @TestVisible
    private void handleResponse(HttpResponse response) {
        if (response == null) {
            return;
        }

        if (this.callback == null) {
            Logger.info(
                    'Request executed with status ' +
                        response.getStatusCode() +
                        ', no callback provided.'
                )
                .addTag(LOG_TAG);
            return;
        }

        try {
            callback.callback(response);
        } catch (Exception e) {
            Logger.error('Error executing callback: ' + e.getMessage())
                .addTag(LOG_TAG);
            retry();
        }
    }
}
