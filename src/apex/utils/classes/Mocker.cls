public class Mocker implements System.StubProvider {
    private MockRegistry registry;

    public Mocker() {
        this.registry = new MockRegistry();
    }

    public Object mock(String className) {
        return Test.createStub(Type.forName(className), this);
    }

    public MockedMethod patch(Object stubbedObject, String methodName) {
        MockedMethod onMethodCall = new MockedMethod(stubbedObject, methodName);
        this.registry.put((IMockedMethod) onMethodCall);
        return onMethodCall;
    }

    private class MockRegistry {
        Map<Object, IMockedMethod> methodHooks;

        public MockRegistry() {
            this.methodHooks = new Map<Object, IMockedMethod>();
        }

        public IMockedMethod get(Object stubbedObject, String methodName) {
            String key = Mocker.generateKey(stubbedObject, methodName, null);

            if (this.methodHooks.containsKey(key)) {
                return this.methodHooks.get(key);
            }

            return null;
        }

        public void put(IMockedMethod methodCall) {
            this.methodHooks.put(
                Mocker.generateKey(
                    methodCall.getStubbedObject(),
                    methodCall.getMethodName(),
                    methodCall.getArgs()
                ),
                methodCall
            );
        }
    }

    public interface IMockedMethod extends Callable {
        String getMethodName();
        Object getStubbedObject();
        Map<String, Object> getArgs();

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
        Type returnType;
        List<Type> listOfParamTypes;
        List<String> listOfParamNames;
        List<Object> listOfArgs;

        Callable hook;

        Integer callCount;

        public MockedMethod(Object stubbedObject, String stubbedMethodName) {
            this.stubbedObject = stubbedObject;
            this.stubbedMethodName = stubbedMethodName;

            this.callCount = 0;
        }

        public Object getStubbedObject() {
            return this.stubbedObject;
        }

        public String getMethodName() {
            return this.stubbedMethodName;
        }

        public Map<String, Object> getArgs() {
            return null;
        }

        public Object call(String stubbedMethodName, Map<String, Object> args) {
            this.callCount++;
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
    }

    public Object handleMethodCall(
        Object stubbedObject,
        String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        IMockedMethod methodCall = (IMockedMethod) this.registry.get(
            stubbedObject,
            stubbedMethodName
        );

        if (methodCall != null) {
            return methodCall.call(
                stubbedMethodName,
                Mocker.zipArgs(listOfParamNames, listOfArgs)
            );
        }

        return null;
    }

    public void assertCalled(Object stubbedObject, String stubbedMethodName) {
        this.assertCalled(stubbedObject, stubbedMethodName, null);
    }

    public void assertCalled(
        Object stubbedObject,
        String stubbedMethodName,
        Integer times
    ) {
        MockedMethod methodCall = (MockedMethod) this.registry.get(
            stubbedObject,
            stubbedMethodName
        );

        if (methodCall == null) {
            Assert.isTrue(false, 'Method not stubbed');
            return;
        }

        if (times == null) {
            Assert.isTrue(methodCall.callCount > 0, 'Method not called');
        } else {
            Assert.isTrue(
                methodCall.callCount == times,
                'Method called ' + methodCall.callCount + ' times'
            );
        }
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
        String stubbedMethodName,
        Map<String, Object> args
    ) {
        String key =
            String.valueOf(System.hashCode(stubbedObject)) +
            '.' +
            stubbedMethodName;
        if (args != null && args.size() > 0) {
            key += '(';
            for (String argName : args.keySet()) {
                key +=
                    argName +
                    '=' +
                    String.valueOf(System.hashCode(args.get(argName))) +
                    ',';
            }
            key += ')';
        }
        System.debug(key);
        return key;
    }
}
