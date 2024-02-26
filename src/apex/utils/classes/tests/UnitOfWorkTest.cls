@IsTest
public class UnitOfWorkTest {
    @IsTest
    static void testRegisterNew() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doUpsert').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        Test.startTest();
        UnitOfWork uow = new UnitOfWork();
        Account a = new Account();
        a.Name = 'Dunder Mifflin';
        uow.registerNew(a);
        uow.save();
        Test.stopTest();

        Assert.areEqual(uow.transactions.get('Account').records[0], a);
        mocker.assertCalled(mockDml, 'doUpsert', 1);
    }

    @IsTest
    static void testRegisterUpdate() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doUpsert').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        Test.startTest();
        UnitOfWork uow = new UnitOfWork();
        Account a = new Account();
        a.Name = 'Dunder Mifflin';
        uow.registerUpdate(a);
        uow.save();
        Test.stopTest();

        Assert.areEqual(uow.transactions.get('Account').records[0], a);
        mocker.assertCalled(mockDml, 'doUpsert', 1);
    }

    @IsTest
    static void testRegisterDelete() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doDelete').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        Test.startTest();
        UnitOfWork uow = new UnitOfWork();
        Account a = new Account();
        a.Name = 'Dunder Mifflin';
        uow.registerDelete(a);
        uow.save();
        Test.stopTest();

        Assert.areEqual(uow.transactions.get('Account').records[0], a);
        mocker.assertCalled(mockDml, 'doDelete', 1);
    }

    public class MockUpsert implements Callable {
        public Object call(String methodName, Map<String, Object> args) {
            List<SObject> records = (List<SObject>) args.get('records');
            if (methodName == 'doUpsert') {
                for (SObject record : records) {
                    record.Id = TestFactory.generateMockId(
                        record.getSObjectType().getDescribe().getName()
                    );
                }
            }
            return records;
        }
    }

    @IsTest
    static void testResolveRelationship() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doUpsert').thenCall(new MockUpsert());

        TypeFactory.setMock('DML', mockDml);

        UnitOfWork uow = new UnitOfWork();

        Account a = new Account();
        a.Name = 'Dunder Mifflin';
        uow.registerNew(a);

        Contact c = new Contact();
        c.FirstName = 'Michael';
        c.LastName = 'Scott';
        c.Account = a;
        uow.registerNew(c, 'AccountId', a);

        Test.startTest();
        uow.save();

        Test.stopTest();

        Assert.areEqual(c.AccountId, a.Id);
        mocker.assertCalled(mockDml, 'doUpsert', 2);
    }
}
