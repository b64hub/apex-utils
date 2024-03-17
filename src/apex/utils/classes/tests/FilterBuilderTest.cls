@IsTest
public class FilterBuilderTest {
    @IsTest
    static void testSimpleEquals() {
        List<Account> accounts = (List<Account>) new TestFactory('Account')
            .createRecords(10)
            .setField('Name', new List<String>{ 'Dunder Mifflin', 'Staples' })
            .getRecords();

        Test.startTest();
        FilterBuilder builder = FilterBuilder.newBuilder(accounts);
        builder.andFilter(new FilterBuilder.Equals('Name', 'Dunder Mifflin'));

        List<Account> filteredAccounts = builder.apply();
        Test.stopTest();

        Assert.isTrue(filteredAccounts.size() == 5);
        Assert.isTrue(accounts.size() == 10);
        Assert.areEqual('Dunder Mifflin', filteredAccounts.get(0).Name);
    }

    @IsTest
    static void testAndOrCombination() {
        List<Account> accounts = (List<Account>) new TestFactory('Account')
            .createRecords(15)
            .setField(
                'Name',
                new List<String>{
                    'Dunder Mifflin',
                    'Staples',
                    'Michael Scott Paper Company'
                }
            )
            .setField('Type', new List<String>{ 'Paper', 'Office Supplies' })
            .getRecords();

        Test.startTest();
        FilterBuilder filterBuilder = FilterBuilder.newBuilder(accounts);
        filterBuilder.andFilter(
            new FilterBuilder.Equals('Name', 'Dunder Mifflin')
        );
        filterBuilder.orFilter(
            new FilterBuilder.Equals('Type', 'Office Supplies')
        );

        List<Account> filteredAccounts = filterBuilder.apply();
        Test.stopTest();

        Assert.isTrue(filteredAccounts.size() == 10);
        Assert.areEqual('Dunder Mifflin', filteredAccounts.get(0).Name);
        Assert.areEqual('Office Supplies', filteredAccounts.get(9).Type);
    }

    @IsTest
    static void testShorthandCombination() {
        List<Contact> contacts = (List<Contact>) new TestFactory('Contact')
            .createRecords(100)
            .setField('FirstName', new List<String>{ 'Michael', 'Dwight' })
            .setField(
                'Birthdate',
                new List<Date>{
                    Date.newInstance(1962, 8, 16),
                    Date.newInstance(1966, 1, 20)
                }
            )
            .setField(
                'Email',
                new List<String>{
                    'michael@dundermifflin.com',
                    'dwight@dundermifflin.com'
                }
            )
            .getRecords();

        Contact con = new Contact();

        Test.startTest();
        FilterBuilder filterBuilder = FilterBuilder.newBuilder(contacts);
        filterBuilder
            .addFilter('FirstName', 'isset', true)
            .addFilter('and', 'Birthdate', 'lt', Date.newInstance(1965, 1, 1));

        List<Contact> filteredContacts = filterBuilder.apply();
        Test.stopTest();

        Assert.isTrue(filteredContacts.size() == 50);
        Assert.areEqual('Michael', filteredContacts.get(0).FirstName);
    }

    @IsTest
    static void testInitNodes() {
        Account acc = new Account();
        acc.Name = 'Dunder Mifflin';
        acc.Type = 'Paper';

        FilterBuilder.Node andNode = FilterBuilder.andNode(
            new FilterBuilder.Equals('Name', 'Dunder Mifflin'),
            new FilterBuilder.Equals('Type', 'Paper')
        );
        FilterBuilder.Node orNode = FilterBuilder.orNode(
            new FilterBuilder.Equals('Name', 'Dunder Mifflin'),
            new FilterBuilder.Equals('Type', 'Paper')
        );
        FilterBuilder.Node notNode = FilterBuilder.notNode(
            new FilterBuilder.Equals('Name', 'Dunder Mifflin')
        );
        FilterBuilder.Node xorNode = FilterBuilder.xorNode(
            new FilterBuilder.Equals('Name', 'Dunder Mifflin'),
            new FilterBuilder.Equals('Type', 'Paper')
        );
        FilterBuilder.Node nandNode = FilterBuilder.nandNode(
            new FilterBuilder.Equals('Name', 'Dunder Mifflin'),
            new FilterBuilder.Equals('Type', 'Paper')
        );

        Assert.isTrue(andNode.apply(acc));
        Assert.isTrue(orNode.apply(acc));
        Assert.isFalse(notNode.apply(acc));
        Assert.isFalse(xorNode.apply(acc));
        Assert.isFalse(nandNode.apply(acc));
    }

    public class FastFilter extends FilterBuilder.Filter {
        public override Boolean apply(SObject record) {
            Account acc = (Account) record;
            return acc.Name == 'Dunder Mifflin' ||
                acc.Name == 'Staples' &&
                acc.Type == 'Office Supplies';
        }
    }

    @IsTest
    static void testPerformance() {
        List<Account> accounts = (List<Account>) new TestFactory('Account')
            .createRecords(100)
            .setField('Name', new List<String>{ 'Dunder Mifflin', 'Staples' })
            .setField(
                'Type',
                new List<String>{ 'Paper', 'Office Supplies', 'Printers' }
            )
            .getRecords();

        Test.startTest();

        FilterBuilder builder = FilterBuilder.newBuilder(accounts);
        builder.andFilter(new FilterBuilder.Equals('Type', 'Office Supplies'));
        builder.addFilter(
            'and',
            new FilterBuilder.Equals('Name', 'Dunder Mifflin')
        );
        builder.orFilter(new FilterBuilder.Equals('Name', 'Staples'));

        Datetime tic = System.now();
        List<Account> filteredAccounts = builder.apply();
        Datetime tac = System.now();
        System.debug('Filter time: ' + (tac.getTime() - tic.getTime()));

        Datetime tic2 = System.now();
        List<Account> filteredAccounts2 = new List<Account>();
        for (Account acc : accounts) {
            if (
                acc.Name == 'Dunder Mifflin' ||
                acc.Name == 'Staples' &&
                acc.Type == 'Office Supplies'
            ) {
                filteredAccounts2.add(acc);
            }
        }
        Datetime tac2 = System.now();
        System.debug('For loop time: ' + (tac2.getTime() - tic2.getTime()));

        Datetime tic3 = System.now();
        List<Account> filteredAccounts3 = FilterBuilder.fastFilter(
            accounts,
            new FastFilter()
        );
        Datetime tac3 = System.now();
        System.debug('Fast filter time: ' + (tac3.getTime() - tic3.getTime()));

        Test.stopTest();

        System.debug('Filtered Accounts: ' + filteredAccounts.size());
        System.debug('Filtered Accounts 2: ' + filteredAccounts2.size());
        System.debug('Filtered Accounts 3: ' + filteredAccounts3.size());
        System.debug('Original Accounts: ' + accounts.size());

        // Assert.areEqual(filteredAccounts.size(), filteredAccounts2.size());
    }

    @IsTest
    static void testNot() {
        TestFactory tfOld = new TestFactory('Account')
            .createRecords(10)
            .setField('Name', new List<String>{ 'Dunder Mifflin', 'Staples' })
            .setField('Type', new List<String>{ 'Paper', 'Office Supplies' })
            .addMockIds();

        TestFactory tfNew = tfOld.copy()
            .setField(
                'Name',
                new List<String>{ 'Dunder Mifflin Sabre', 'Staples' }
            );

        Map<Id, Account> oldAccounts = new Map<Id, Account>(
            (List<Account>) tfOld.getRecords()
        );
        List<Account> newAccounts = (List<Account>) tfNew.getRecords();

        Test.startTest();
        FilterBuilder builder = FilterBuilder.newBuilder(newAccounts);
        builder.andFilter(new FilterBuilder.IsChanged('Name', oldAccounts));

        List<Account> nameChange = builder.apply();

        Assert.areEqual(5, nameChange.size());
        Assert.areEqual('Dunder Mifflin Sabre', nameChange.get(0).Name);

        builder.notFilter();

        List<Account> noChange = builder.apply();

        Assert.areEqual(5, noChange.size());
        Assert.areEqual('Staples', noChange.get(0).Name);
        Test.stopTest();
    }

    @IsTest
    static void testXor() {
        TestFactory tfOld = new TestFactory('Account')
            .createRecords(10)
            .setField('Name', new List<String>{ 'Dunder Mifflin', 'Staples' })
            .setField('Type', new List<String>{ 'Paper', 'Office Supplies' })
            .addMockIds();

        TestFactory tfNew = tfOld.copy()
            .setField(
                'Name',
                new List<String>{ 'Dunder Mifflin Sabre', 'Staples Inc.' }
            )
            .setField('BillingCity', new List<String>{ 'Scranton', null });

        Map<Id, Account> oldAccounts = new Map<Id, Account>(
            (List<Account>) tfOld.getRecords()
        );
        List<Account> newAccounts = (List<Account>) tfNew.getRecords();

        Test.startTest();
        FilterBuilder builder = FilterBuilder.newBuilder(newAccounts);
        builder.addFilter(
            'and',
            new FilterBuilder.IsNew('BillingCity', oldAccounts)
        );

        List<Account> isNew = builder.apply();

        Assert.areEqual(5, isNew.size());
        Assert.areEqual('Dunder Mifflin Sabre', isNew.get(0).Name);

        builder.xorFilter(new FilterBuilder.IsUpdated('Name', oldAccounts));

        List<Account> isUpdated = builder.apply();

        Assert.areEqual(5, isUpdated.size());
        Assert.areEqual('Staples Inc.', isUpdated.get(0).Name);
        Test.stopTest();
    }

    @IsTest
    static void testNand() {
        TestFactory tf = new TestFactory('Account')
            .createRecords(15)
            .setField('Name', new List<String>{ 'Dunder Mifflin', 'Staples' })
            .setField(
                'Type',
                new List<String>{ 'Paper', 'Office Supplies', 'Printers' }
            )
            .addMockIds();

        List<Account> accounts = (List<Account>) tf.getRecords();

        Test.startTest();
        FilterBuilder builder = FilterBuilder.newBuilder(accounts);
        builder.andFilter(new FilterBuilder.Equals('Name', 'Dunder Mifflin'));
        builder.nandFilter(new FilterBuilder.Equals('Type', 'Paper'));

        List<Account> nand = builder.apply();

        Assert.areEqual(12, nand.size());
        Assert.areEqual('Staples', nand.get(0).Name);
        Assert.areEqual('Office Supplies', nand.get(0).Type);
        Test.stopTest();
    }

    @IsTest
    static void testFilters() {
        Contact con = new Contact();
        con.FirstName = 'Michael';
        con.LastName = 'Scott';
        con.Birthdate = Date.newInstance(1962, 8, 16);
        con.Email = 'michael@dundermifflin.com';
        con.Phone = '1234567890';
        con.Id = TestFactory.generateMockId('Contact');

        Contact oldContact = new Contact();
        oldContact.FirstName = 'Michael J.';
        oldContact.LastName = 'Scott';
        oldContact.AssistantName = 'Dwight';
        oldContact.Birthdate = Date.newInstance(1962, 8, 16);
        oldContact.Email = 'worldsbestboss@dundermifflin.com';
        oldContact.Phone = null;
        oldContact.Id = con.Id;

        Map<Id, Contact> oldMap = new Map<Id, Contact>{ con.Id => oldContact };

        Test.startTest();
        FilterBuilder.LessThan lt = new FilterBuilder.LessThan(
            'Birthdate',
            Date.newInstance(1965, 1, 1)
        );
        FilterBuilder.GreaterThan gt = new FilterBuilder.GreaterThan(
            'Birthdate',
            Date.newInstance(1965, 1, 1)
        );
        FilterBuilder.LessThanOrEq lte = new FilterBuilder.LessThanOrEq(
            'Birthdate',
            Date.newInstance(1965, 1, 1)
        );
        FilterBuilder.GreaterThanOrEq gte = new FilterBuilder.GreaterThanOrEq(
            'Birthdate',
            Date.newInstance(1965, 1, 1)
        );
        FilterBuilder.Contains cont = new FilterBuilder.Contains(
            'Email',
            new List<String>{
                'michael@dundermifflin.com',
                'dwight@dundermifflin.com'
            }
        );

        FilterBuilder.IsChanged isChanged = new FilterBuilder.IsChanged(
            'FirstName',
            oldMap
        );
        FilterBuilder.IsNew isNew = new FilterBuilder.IsNew('Phone', oldMap);
        FilterBuilder.IsDeleted isDeleted = new FilterBuilder.IsDeleted(
            'AssistantName',
            oldMap
        );
        FilterBuilder.IsUpdated isUpdated = new FilterBuilder.IsUpdated(
            'Email',
            oldMap
        );
        FilterBuilder.IsSet isSet = new FilterBuilder.IsSet('LastName', true);
        Test.stopTest();

        Assert.isTrue(lt.apply(con));
        Assert.isFalse(gt.apply(con));
        Assert.isTrue(lte.apply(con));
        Assert.isFalse(gte.apply(con));
        Assert.isTrue(cont.apply(con));

        Assert.isTrue(isChanged.apply(con));
        Assert.isTrue(isNew.apply(con));
        Assert.isTrue(isDeleted.apply(con));
        Assert.isTrue(isUpdated.apply(con));
        Assert.isTrue(isSet.apply(con));
    }
}
