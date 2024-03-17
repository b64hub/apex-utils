@IsTest
public class UnitOfWorkTest {
    @IsTest
    static void testRegisterSingleNew() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doInsert').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        Test.startTest();
        UnitOfWork uow = new UnitOfWork();
        Account a = new Account();
        a.Name = 'Dunder Mifflin';
        UnitOfWork.DmlTransaction trx = (UnitOfWork.DmlTransaction) uow.registerNew(
            a
        );
        uow.save();
        Test.stopTest();

        Assert.areEqual(trx.getRecords().get(0), a);
        Assert.isTrue(uow.transactions.isEmpty());
        mocker.assertCalled(mockDml, 'doInsert', 1);
    }

    @IsTest
    static void testRegisteSingleUpdate() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doUpdate').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        Test.startTest();
        UnitOfWork uow = new UnitOfWork();
        Account a = new Account();
        a.Name = 'Dunder Mifflin';
        UnitOfWork.DmlTransaction trx = (UnitOfWork.DmlTransaction) uow.registerUpdate(
            a
        );
        uow.save();
        Test.stopTest();

        Assert.areEqual(trx.getRecords().get(0), a);
        Assert.isTrue(uow.transactions.isEmpty());
        mocker.assertCalled(mockDml, 'doUpdate', 1);
    }

    @IsTest
    static void testRegisterSingleDelete() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doDelete').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        Test.startTest();
        UnitOfWork uow = new UnitOfWork();
        Account a = new Account();
        a.Name = 'Dunder Mifflin';
        UnitOfWork.DmlTransaction trx = (UnitOfWork.DmlTransaction) uow.registerDelete(
            a
        );
        uow.save();
        Test.stopTest();

        Assert.areEqual(trx.getRecords().get(0), a);
        Assert.isTrue(uow.transactions.isEmpty());
        mocker.assertCalled(mockDml, 'doDelete', 1);
    }

    @IsTest
    static void testRegisterSingleUpsert() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doUpsert').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        Test.startTest();
        UnitOfWork uow = new UnitOfWork();
        Account a = new Account();
        a.Name = 'Dunder Mifflin';
        UnitOfWork.DmlTransaction trx = (UnitOfWork.DmlTransaction) uow.registerNew(
            a,
            Account.Name
        );
        uow.save();
        Test.stopTest();

        Assert.areEqual(trx.getRecords().get(0), a);
        Assert.isTrue(uow.transactions.isEmpty());
        mocker.assertCalled(mockDml, 'doUpsert', 1);
    }

    public class MockUpsert implements Callable {
        public Object call(String methodName, Map<String, Object> args) {
            List<SObject> records = (List<SObject>) args.get('records');
            if (methodName == 'doUpsert' || methodName == 'doInsert') {
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
    static void testResolveSingleRelationship() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doInsert').thenCall(new MockUpsert());

        TypeFactory.setMock('DML', mockDml);

        UnitOfWork uow = new UnitOfWork();

        Account a = new Account();
        a.Name = 'Dunder Mifflin';

        Contact c = new Contact();
        c.FirstName = 'Michael';
        c.LastName = 'Scott';
        c.Account = a;

        Test.startTest();
        uow.registerNew(a);
        uow.registerNew(c, 'AccountId', a);
        uow.save();

        Test.stopTest();

        Assert.areEqual(c.AccountId, a.Id);
        mocker.assertCalled(mockDml, 'doInsert', 2);
    }

    @IsTest
    static void testResolveSingleRelationshipUpsert() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doInsert').thenCall(new MockUpsert());
        mocker.patch(mockDml, 'doUpsert').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        UnitOfWork uow = new UnitOfWork();

        Account a = new Account();
        a.Name = 'Dunder Mifflin';

        Contact c = new Contact();
        c.FirstName = 'Michael';
        c.LastName = 'Scott';
        c.Account = a;

        Test.startTest();
        uow.registerNew(a);
        uow.registerNew(c, 'AccountId', a, Contact.Id);
        uow.save();
        Test.stopTest();

        Assert.areEqual(c.AccountId, a.Id);
        mocker.assertCalled(mockDml, 'doInsert', 1);
        mocker.assertCalled(mockDml, 'doUpsert', 1);
    }

    @IsTest
    static void testRegisterMultiple() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doInsert').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        Test.startTest();
        UnitOfWork uow = new UnitOfWork();
        List<Account> accounts = (List<Account>) new TestFactory('Account')
            .createRecords(6)
            .setField('Name', 'Dunder Mifflin')
            .getRecords();

        uow.registerNew(accounts.get(0));
        UnitOfWork.DmlTransaction trx_1 = uow.registerNew(accounts.get(1));

        uow.registerUpdate(accounts.get(2));
        UnitOfWork.DmlTransaction trx_2 = uow.registerUpdate(accounts.get(3));

        uow.registerDelete(accounts.get(4));
        uow.registerDelete(accounts.get(5));

        Test.stopTest();

        Assert.isTrue(uow.transactions.size() == 3);
        Assert.areEqual(10, trx_1.getOrder());
        Assert.areEqual(
            new List<Account>{ accounts.get(0), accounts.get(1) },
            trx_1.getRecords()
        );
        Assert.areEqual(20, trx_2.getOrder());
    }

    @IsTest
    static void testSObjectOrder() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');

        UnitOfWork.TransactionControls controls = new UnitOfWork.TransactionControls();
        controls.sObjectOrder = new List<String>{ 'Account', 'Contact' };

        UnitOfWork uow = new UnitOfWork(mockDml, controls);
        Account account = (Account) new TestFactory('Account')
            .createRecords(1)
            .setField('Name', 'Dunder Mifflin')
            .getRecords()
            .get(0);

        Contact contact = (Contact) new TestFactory('Contact')
            .createRecords(1)
            .setField('FirstName', 'Michael')
            .setField('LastName', 'Scott')
            .getRecords()
            .get(0);

        Test.startTest();
        uow.registerNew(contact, 'AccountId', account);
        uow.registerUpdate(account);
        List<String> sortedKeys = uow.sortTransactions();
        Test.stopTest();

        Assert.areEqual(
            'UnitOfWork.UpdateTransaction(Account)',
            sortedKeys.get(0)
        );
        Assert.areEqual(
            'UnitOfWork.InsertTransaction(Contact)',
            sortedKeys.get(1)
        );
    }

    public class CustomTestTransaction extends UnitOfWork.TransactionUnit {
        public String myProp;

        public CustomTestTransaction(List<SObject> records) {
            super(records);
        }

        public override void execute(IDML dmlHandler) {
            this.myProp = 'custom insert';
            dmlHandler.doInsert(this.records);
        }
    }

    @IsTest
    static void testAddCustomTransaction() {
        Mocker mocker = new Mocker();
        DML mockDml = (DML) mocker.mock('DML');
        mocker.patch(mockDml, 'doInsert').thenReturn(null);

        TypeFactory.setMock('DML', mockDml);

        UnitOfWork uow = new UnitOfWork();
        Account a = new Account();
        a.Name = 'Dunder Mifflin';

        Test.startTest();
        UnitOfWork.ITransaction customTransaction = (UnitOfWork.ITransaction) new UnitOfWorkTest.CustomTestTransaction(
            new List<SObject>{ a }
        );
        uow.addTransaction(customTransaction, 'MyCustomTransaction');

        Assert.areEqual(
            'MyCustomTransaction(Account)',
            new List<String>(uow.transactions.keySet()).get(0)
        );

        uow.save();
        Test.stopTest();

        Assert.isTrue(uow.transactions.isEmpty());
        Assert.areEqual(
            'custom insert',
            ((UnitOfWorkTest.CustomTestTransaction) customTransaction).myProp
        );

        mocker.assertCalled(mockDml, 'doInsert', 1);
    }
}
