public class Mocker implements System.StubProvider {
    private MockRegistry registry;
    public Type assertionClass = Mocker.AssertionBuilder.class;

    private StubContext stubContext = new StubContext();

    public Mocker() {
        this.registry = new MockRegistry();
    }

    public Object mock(String className) {
        return mock(Type.forName(className));
    }

    public Object mock(Type classType) {
        return Test.createStub(classType, this);
    }

    public class StubException extends Exception {
    }

    /**
     * @description Stubs a method on an object
     */
    public MockedMethod stub(Object stubbedObject, String methodName) {
        MockedMethod onMethodCall = new MockedMethod(stubbedObject, methodName);
        this.registry.put((IMockedMethod) onMethodCall);
        return onMethodCall;
    }

    public MockedMethod stub(
        Object stubbedObject,
        String methodName,
        Map<String, Object> args
    ) {
        MockedMethod onMethodCall = new MockedMethod(
            stubbedObject,
            methodName,
            args
        );
        this.registry.put((IMockedMethod) onMethodCall);
        return onMethodCall;
    }

    /**
     * @description Alias for stub
     */
    public MockedMethod patch(Object stubbedObject, String methodName) {
        return this.stub(stubbedObject, methodName);
    }

    public MockedMethod stub(Object methodCall) {
        if (!this.stubContext.isStubbing) {
            throw new StubException(
                'Cannot stub dynamically outside of stubbing block'
            );
        }
        return (MockedMethod) this.stubContext.popMethod();
    }

    private class StubContext {
        Boolean isStubbing = false;
        Boolean isAsserting = false;

        IMockedMethod methodCall;
        Map<String, Object> assertArgs;

        private void start() {
            this.isStubbing = true;
        }

        private void stop() {
            this.isStubbing = false;
        }

        private void startAssert() {
            this.isAsserting = true;
        }

        private void stopAssert() {
            this.isAsserting = false;
        }

        private IMockedMethod popMethod() {
            IMockedMethod methodCall = this.methodCall;
            this.methodCall = null;
            return methodCall;
        }

        private Map<String, Object> popArgs() {
            Map<String, Object> args = this.assertArgs;
            this.assertArgs = null;
            return args;
        }
    }

    public void startStubbing() {
        this.stubContext.start();
    }

    public void stopStubbing() {
        this.stubContext.stop();
    }

    public void startAsserting() {
        this.stubContext.startAssert();
    }

    public void stopAsserting() {
        this.stubContext.stopAssert();
    }

    private class MockRegistry {
        Map<Object, IMockedMethod> methodHooks;

        public MockRegistry() {
            this.methodHooks = new Map<Object, IMockedMethod>();
        }

        public IMockedMethod get(Object stubbedObject, String methodName) {
            String key = Mocker.generateKey(stubbedObject, methodName);
            return this.methodHooks.get(key);
        }

        /**
         * @description Gets a stubbed method from the registry. Will try to return the arg specific method.
         * If it does not exist, it will return the deafult no-arg stubbed method.
         */
        public IMockedMethod get(
            Object stubbedObject,
            String methodName,
            Map<String, Object> args
        ) {
            String key = Mocker.generateKey(stubbedObject, methodName, args);

            if (!this.methodHooks.containsKey(key)) {
                return this.methodHooks.get(
                    Mocker.generateKey(stubbedObject, methodName)
                );
            }

            return this.methodHooks.get(key);
        }

        /**
         * @description Adds a stubbed method to the registry. If the registry does not contain a default no-arg key, it will add one.
         */
        public void put(IMockedMethod methodCall) {
            this.methodHooks.put(methodCall.key(), methodCall);

            String noArgKey = Mocker.generateKey(
                methodCall.getStubbedObject(),
                methodCall.getMethodName()
            );
            if (methodHooks.containsKey(noArgKey)) {
                return;
            }

            this.methodHooks.put(noArgKey, methodCall);
        }
    }

    public interface IMockedMethod extends Callable {
        String getMethodName();
        Object getStubbedObject();
        Map<String, Object> getStubbedArgs();
        List<Map<String, Object>> getCallHistory();
        String key();

        Object call(String stubbedMethodName, Map<String, Object> args);
    }

    public class ReturnHook implements Callable {
        Object returnValue;

        public ReturnHook(Object returnValue) {
            this.returnValue = returnValue;
        }

        public Object call(String stubbedMethodName, Map<String, Object> args) {
            return this.returnValue;
        }
    }

    public class ExceptionHook implements Callable {
        Exception error;

        public ExceptionHook(Exception error) {
            this.error = error;
        }

        public Object call(String stubbedMethodName, Map<String, Object> args) {
            throw this.error;
        }
    }

    public virtual class MockedMethod implements IMockedMethod {
        Object stubbedObject;
        String stubbedMethodName;
        Map<String, Object> stubbedArgs;
        Type returnType;
        List<Type> listOfParamTypes;

        Callable hook;

        List<Map<String, Object>> callArgs;

        public MockedMethod(Object stubbedObject, String stubbedMethodName) {
            this.stubbedObject = stubbedObject;
            this.stubbedMethodName = stubbedMethodName;

            this.callArgs = new List<Map<String, Object>>();
        }

        public MockedMethod(
            Object stubbedObject,
            String stubbedMethodName,
            Map<String, Object> args
        ) {
            this(stubbedObject, stubbedMethodName);
            this.stubbedArgs = args;
        }

        public Object getStubbedObject() {
            return this.stubbedObject;
        }

        public String getMethodName() {
            return this.stubbedMethodName;
        }

        public Map<String, Object> getStubbedArgs() {
            return this.stubbedArgs;
        }

        public Map<String, Object> getArgs() {
            return this.callArgs.get(this.callArgs.size() - 1);
        }

        public List<Map<String, Object>> getCallHistory() {
            return this.callArgs;
        }

        public Integer getCalls() {
            return this.callArgs.size();
        }

        public Object call(String stubbedMethodName, Map<String, Object> args) {
            this.callArgs.add(args);

            if (this.hook == null) {
                return null;
            }

            return this.hook.call(stubbedMethodName, args);
        }

        public void thenReturn(Object returnValue) {
            this.thenCall(new ReturnHook(returnValue));
        }

        public void thenThrow(Exception error) {
            this.thenCall(new ExceptionHook(error));
        }

        public void thenCall(Callable hook) {
            this.hook = hook;
        }

        public String key() {
            return Mocker.generateKey(
                this.stubbedObject,
                this.stubbedMethodName,
                this.stubbedArgs
            );
        }
    }

    /**
     * @description System.StubProvider interface method
     *
     * @param stubbedObject - the object the method was stubbed on
     * @param stubbedMethodName - the name of the method that was stubbed
     * @param returnType - the return type of the method
     * @param listOfParamTypes - the types of the parameters of the method
     * @param listOfParamNames - the names of the parameters of the method
     * @param listOfArgs - the arguments the method was called with
     */
    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        if (this.stubContext.isStubbing) {
            return this.handleStub(
                stubbedObject,
                stubbedMethodName,
                returnType,
                listOfParamTypes,
                listOfParamNames,
                listOfArgs
            );
        }

        if (this.stubContext.isAsserting) {
            return this.handleAssert(
                stubbedObject,
                stubbedMethodName,
                returnType,
                listOfParamTypes,
                listOfParamNames,
                listOfArgs
            );
        }

        return this.handleCall(
            stubbedObject,
            stubbedMethodName,
            returnType,
            listOfParamTypes,
            listOfParamNames,
            listOfArgs
        );
    }

    private Object handleStub(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        Map<String, Object> args = Mocker.zipArgs(listOfParamNames, listOfArgs);
        this.stubContext.methodCall = this.stub(
            stubbedObject,
            stubbedMethodName,
            args
        );
        return null;
    }

    private Object handleAssert(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        Map<String, Object> args = Mocker.zipArgs(listOfParamNames, listOfArgs);
        this.stubContext.methodCall = this.registry.get(
            stubbedObject,
            stubbedMethodName,
            args
        );
        this.stubContext.assertArgs = args;
        return null;
    }

    private Object handleCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        Map<String, Object> args = Mocker.zipArgs(listOfParamNames, listOfArgs);

        Callable methodCall = (Callable) this.registry.get(
            stubbedObject,
            stubbedMethodName,
            args
        );

        if (methodCall == null) {
            return null;
        }

        return methodCall.call(stubbedMethodName, args);
    }

    public AssertionBuilder assert(Object methodCall) {
        if (!this.stubContext.isAsserting) {
            throw new StubException(
                'Cannot assert dynamically outside of asserting block'
            );
        }
        IMockedMethod contextMethod = (IMockedMethod) this.stubContext.popMethod();
        Map<String, Object> assertArgs = this.stubContext.popArgs();

        if (assertArgs == null || assertArgs.isEmpty()) {
            return new AssertionBuilder().begin(contextMethod);
        }

        return new AssertionBuilder().begin(contextMethod).withArgs(assertArgs);
    }

    /**
     * @description entry point for asserting method calls
     *
     * @param stubbedObject - the object the method was stubbed on
     * @param stubbedMethodName - the name of the method that was stubbed
     */
    public AssertionBuilder assertMethodCalled(
        Object stubbedObject,
        String stubbedMethodName
    ) {
        IMockedMethod methodCall = (IMockedMethod) this.registry.get(
            stubbedObject,
            stubbedMethodName
        );
        if (methodCall == null) {
            Assert.isTrue(
                false,
                'Method ' +
                    stubbedMethodName +
                    ' not stubbed on ' +
                    String.valueOf(stubbedObject)
            );
        }

        return new AssertionBuilder().begin(methodCall);
    }

    /**
     * @description DEPRECATED - kept for backwards compatibility, use methodCalled and AssertionBuilder methods instead
     */
    public void assertCalled(Object stubbedObject, String stubbedMethodName) {
        this.assertMethodCalled(stubbedObject, stubbedMethodName).verify();
    }

    /**
     * @description DEPRECATED - kept for backwards compatibility, use methodCalled and AssertionBuilder methods instead
     */
    public void assertCalled(
        Object stubbedObject,
        String stubbedMethodName,
        Integer times
    ) {
        this.assertMethodCalled(stubbedObject, stubbedMethodName)
            .times(times)
            .verify();
    }

    /**
     * @description DEPRECATED - kept for backwards compatibility, use methodCalled and AssertionBuilder methods instead
     */
    public void assertCalled(
        Object stubbedObject,
        String stubbedMethodName,
        Integer times,
        Map<String, Object> args
    ) {
        if (args == null) {
            this.assertMethodCalled(stubbedObject, stubbedMethodName)
                .times(times)
                .verify();
            return;
        }

        if (times == null) {
            this.assertMethodCalled(stubbedObject, stubbedMethodName)
                .withArgs(args)
                .verify();
            return;
        }

        this.assertMethodCalled(stubbedObject, stubbedMethodName)
            .withArgs(args)
            .times(times)
            .verify();
    }

    private static Map<String, Object> zipArgs(
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        Map<String, Object> args = new Map<String, Object>();

        for (Integer i = 0; i < listOfParamNames.size(); i++) {
            args.put(listOfParamNames.get(i), listOfArgs.get(i));
        }

        return args;
    }

    private static String generateKey(
        Object stubbedObject,
        String stubbedMethodName
    ) {
        return String.valueOf(System.hashCode(stubbedObject)) +
            '.' +
            stubbedMethodName;
    }

    private static String generateKey(
        Object stubbedObject,
        String stubbedMethodName,
        Map<String, Object> args
    ) {
        if (args == null || args.isEmpty()) {
            return generateKey(stubbedObject, stubbedMethodName);
        }

        return String.valueOf(System.hashCode(stubbedObject)) +
            '.' +
            stubbedMethodName +
            '(' +
            String.valueOf(System.hashCode(args)) +
            ')';
    }
}
