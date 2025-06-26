public class TypeFactory {
    private static Map<String, Object> singletons = new Map<String, Object>();
    @TestVisible
    private static Map<String, Object> mocks = new Map<String, Object>();

    public static void setMock(String className, Object mockInstance) {
        mocks.put(className, mockInstance);
    }

    public static Object getMock(String className) {
        return mocks.get(className);
    }

    public static Object newInstance(String className) {
        Object classInstance;

        if (Test.isRunningTest()) {
            classInstance = TypeFactory.getMock(className);
            if (classInstance != null) {
                return classInstance;
            }
        }

        classInstance = Type.forName(className)?.newInstance();
        return classInstance;
    }

    public static Object newInstance(Type classType) {
        return newInstance(classType.getName());
    }

    public static Object getInstance(String className) {
        Object classInstance;

        if (singletons.containsKey(className)) {
            return singletons.get(className);
        }

        classInstance = newInstance(className);
        singletons.put(className, classInstance);

        return classInstance;
    }

    public static Object getInstance(Type classType) {
        return getInstance(classType.getName());
    }
}
