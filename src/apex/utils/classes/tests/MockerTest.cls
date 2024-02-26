@IsTest
public class MockerTest {
    public MockerTest() {
    }

    public String myMethod() {
        return 'Hello World';
    }

    @IsTest
    static void testMock() {
        Mocker mocker = new Mocker();
        MockerTest mock = (MockerTest) mocker.mock('MockerTest');

        String hello = mock.myMethod();
        Assert.areEqual(null, hello);

        mocker.patch(mock, 'myMethod').thenReturn('Hello Mock');
        hello = mock.myMethod();
        Assert.areEqual('Hello Mock', hello);
        mocker.assertCalled(mock, 'myMethod', 1);
    }

    public class MockedException extends Exception {
    }

    @IsTest
    static void testMockThrow() {
        Mocker mocker = new Mocker();
        MockerTest mock = (MockerTest) mocker.mock('MockerTest');

        mocker.patch(mock, 'myMethod')
            .thenThrow(new MockedException('Mocked Exception'));
        try {
            String hello = mock.myMethod();
            Assert.isTrue(false, 'Exception not thrown');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Mocked Exception'));
        }
        mocker.assertCalled(mock, 'myMethod');
    }

    public class MyHook implements Callable {
        public Object call(String stubbedMethodName, Map<String, Object> args) {
            return 'Hello Hook';
        }
    }

    @IsTest
    static void testMockCall() {
        Mocker mocker = new Mocker();
        MockerTest mock = (MockerTest) mocker.mock('MockerTest');

        String hello = mock.myMethod();
        Assert.areEqual(null, hello);

        mocker.patch(mock, 'myMethod').thenCall(new MyHook());
        hello = mock.myMethod();
        Assert.areEqual('Hello Hook', hello);
        mocker.assertCalled(mock, 'myMethod', 1);
    }
}
