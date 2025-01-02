@IsTest
public class SObjectSelectorTest {
    public class TestAccountSelector extends SObjectSelector {
        public TestAccountSelector() {
            super('Account', new List<String>{ 'Name', 'Id' });
        }
    }

    @IsTest
    static void testGetWhere() {
        List<Account> testAccounts = (List<Account>) new TestFactory('Account')
            .createRecords(3)
            .setField(
                'Name',
                new TestFactory.StringTemplate('Test Account {{i}}')
            )
            .getRecords();

        insert testAccounts;

        Test.startTest();
        TestAccountSelector selector = new TestAccountSelector();
        List<SObject> accounts = selector.getWhere('Name', 'Test Account 1');
        Test.stopTest();

        Assert.areEqual(1, accounts.size());
    }

    @IsTest
    static void testGetWhereIdIn() {
        TestFactory accountFactory = new TestFactory('Account')
            .createRecords(3)
            .setField(
                'Name',
                new TestFactory.StringTemplate('Test Account {{i}}')
            );

        insert accountFactory.getRecords();

        Test.startTest();
        TestAccountSelector selector = new TestAccountSelector();
        List<SObject> accounts = selector.getWhereIdIn(
            new Set<Id>(accountFactory.getIds())
        );
        Test.stopTest();

        Assert.areEqual(3, accounts.size());
    }

    @IsTest
    static void testGetWhereIn() {
        List<Account> testAccounts = (List<Account>) new TestFactory('Account')
            .createRecords(3)
            .setField(
                'Name',
                new TestFactory.StringTemplate('Test Account {{i}}')
            )
            .getRecords();

        insert testAccounts;

        Test.startTest();
        TestAccountSelector selector = new TestAccountSelector();
        List<SObject> accounts = selector.getWhereIn(
            'Name',
            new List<String>{ 'Test Account 1', 'Test Account 2' }
        );
        Test.stopTest();

        Assert.areEqual(2, accounts.size());
    }
}
