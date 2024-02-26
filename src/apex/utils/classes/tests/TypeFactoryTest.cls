@IsTest
public class TypeFactoryTest {
    public TypeFactoryTest() {
    }

    public interface IHello {
        String hello();
    }

    class MyClass implements IHello {
        public String hello() {
            return 'hello';
        }
    }

    class MyMockClass implements IHello {
        public String hello() {
            return 'hello mock';
        }
    }

    @IsTest
    static void testGetSetMock() {
        Test.startTest();

        TypeFactory.setMock('MyClass', new MyMockClass());
        Object mockInstance = TypeFactory.getMock('MyClass');

        Test.stopTest();

        Assert.isTrue(
            mockInstance instanceof MyMockClass,
            'Mock instance is not of type MyMockClass'
        );
    }

    @IsTest
    static void testNewInstance() {
        Test.startTest();
        Object clsInstance = TypeFactory.newInstance('TypeFactoryTest');
        TypeFactory.setMock('TypeFactoryTest', new MyMockClass());
        Object mockInstance = TypeFactory.newInstance(TypeFactoryTest.class);
        Test.stopTest();

        Assert.isTrue(clsInstance instanceof TypeFactoryTest);
        Assert.isTrue(mockInstance instanceof MyMockClass);
    }
}
