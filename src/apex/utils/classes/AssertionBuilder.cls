public virtual class AssertionBuilder {
    Mocker.IMockedMethod methodCall;

    Map<String, Object> assertArgs;
    Integer argSpecificTimes;
    Integer totalTimes;

    Boolean minimum = false;
    Boolean maximum = false;

    public AssertionBuilder() {
    }

    public AssertionBuilder(Mocker.IMockedMethod methodCall) {
        this.begin(methodCall);
    }

    /**
     * Begins the assertion building process
     */
    public AssertionBuilder begin(Mocker.IMockedMethod methodCall) {
        this.methodCall = methodCall;
        return this;
    }

    /**
     * @description Asserts the method was called with the supplied args and the number of times with the specific args
     *
     * @param args - the args the method was called with
     */
    public AssertionBuilder withArgs(Map<String, Object> args) {
        this.assertArgs = args;
        this.argSpecificTimes = 0;

        for (Map<String, Object> callArgs : this.methodCall.getCallHistory()) {
            if (AssertionBuilder.compareArgs(args, callArgs)) {
                this.argSpecificTimes++;
            }
        }

        return this;
    }

    /**
     * @description Compares the args to see if they are the same
     * args can be complex objects, and due to some obsucrities in the apex langugae
     * the hashcode can be different for the same object (and differences if in debug mode or not!!),
     * so we attempt to serialize the object and compare the serialized values
     */
    private static Boolean compareArgs(
        Map<String, Object> referenceArgs,
        Map<String, Object> checkArgs
    ) {
        if (referenceArgs == checkArgs) {
            return true;
        }

        if (System.hashCode(referenceArgs) == System.hashCode(checkArgs)) {
            return true;
        }

        try {
            if (JSON.serialize(referenceArgs) == JSON.serialize(checkArgs)) {
                return true;
            }
        } catch (System.JSONException e) {
        }

        return false;
    }

    /**
     * @description shorthand for withArgs for single arg methods
     *
     * @param arg - the arg the method was called with
     * @param value - the value the method was called with
     */
    public AssertionBuilder withArgs(String arg, Object value) {
        return this.withArgs(new Map<String, Object>{ arg => value });
    }

    /**
     * @description Asserts the total number of times the method was called
     * if withArgs is also called, it will assert the number of times the method was called with the supplied args
     *
     * @param times - the number of times the method should have been called
     */
    public AssertionBuilder times(Integer times) {
        this.totalTimes = times;
        return this;
    }

    /**
     * @description Asserts the method was called once
     */
    public AssertionBuilder once() {
        return this.times(1);
    }

    public AssertionBuilder never() {
        return this.times(0);
    }

    public AssertionBuilder atLeast(Integer times) {
        return this.min().times(times);
    }

    public AssertionBuilder atMost(Integer times) {
        return this.max().times(times);
    }

    public AssertionBuilder max() {
        if (maximum) {
            return this;
        }

        this.minimum = true;
        return this;
    }

    public AssertionBuilder min() {
        if (minimum) {
            return this;
        }

        this.maximum = true;
        return this;
    }

    /**
     * @description Finalizes and verifies the assertions set
     */
    public virtual void verify() {
        if (this.assertArgs != null && this.totalTimes != null) {
            String message =
                'Method ' +
                this.methodCall.getMethodName() +
                ' was called ' +
                this.argSpecificTimes +
                ' times with the supplied args';

            if (minimum) {
                Assert.isTrue(
                    this.argSpecificTimes >= this.totalTimes,
                    message
                );
                return;
            }

            if (maximum) {
                Assert.isTrue(
                    this.argSpecificTimes <= this.totalTimes,
                    message
                );
                return;
            }

            Assert.isTrue(this.argSpecificTimes == this.totalTimes, message);
            return;
        }

        if (this.assertArgs != null && this.totalTimes == null) {
            String message =
                'Method ' +
                this.methodCall.getMethodName() +
                ' was called ' +
                this.argSpecificTimes +
                ' times with the supplied args';
            Assert.isTrue(this.argSpecificTimes > 0, message);
            return;
        }

        if (this.totalTimes != null && this.assertArgs == null) {
            String message =
                'Method ' +
                this.methodCall.getMethodName() +
                ' was called ' +
                this.methodCall.getCallHistory().size() +
                ' times';
            if (minimum) {
                Assert.isTrue(
                    this.methodCall.getCallHistory().size() >= this.totalTimes,
                    message
                );
                return;
            }

            if (maximum) {
                Assert.isTrue(
                    this.methodCall.getCallHistory().size() <= this.totalTimes,
                    message
                );
                return;
            }

            Assert.isTrue(
                this.methodCall.getCallHistory().size() == this.totalTimes,
                message
            );
            return;
        }

        Assert.isTrue(
            this.methodCall.getCallHistory().size() > 0,
            'Method ' + this.methodCall.getMethodName() + ' was never called'
        );
        return;
    }

    /**
     * @description Alias for verify
     */
    public virtual void assert() {
        this.verify();
    }
}
