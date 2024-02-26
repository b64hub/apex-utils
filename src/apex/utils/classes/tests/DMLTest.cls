@IsTest
public class DMLTest {
    @IsTest
    static void testDoInsert() {
        Account a = new Account(Name = 'Test Account');
        Database.DMLOptions options = new Database.DMLOptions();
        options.DuplicateRuleHeader.AllowSave = true;
        IDML dml = new DML().allowPartial();

        Test.startTest();
        dml.doInsert(a);
        Test.stopTest();

        Account result = [SELECT Id, Name FROM Account WHERE Id = :a.Id];

        System.assertEquals('Test Account', result.Name);
    }

    @IsTest
    static void testDoInsertError() {
        Account acc = new Account(Name = 'Test Account');
        IDML dml = new DML();

        Test.startTest();
        try {
            dml.doInsert(acc);
            dml.doInsert(acc);
            Assert.isTrue(false);
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Insert failed'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testDoUpdate() {
        Account a = new Account(Name = 'Test Account');
        IDML dml = new DML();
        dml.doInsert(a);

        a.Name = 'Updated Account';

        Test.startTest();
        dml.doUpdate(a);
        Test.stopTest();

        Account result = [SELECT Id, Name FROM Account WHERE Id = :a.Id];

        System.assertEquals('Updated Account', result.Name);
    }

    @IsTest
    static void testDoUpdateError() {
        Account acc = new Account(Name = 'Test Account');
        IDML dml = new DML();

        Test.startTest();
        try {
            dml.doUpdate(acc);
            Assert.isTrue(false);
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Update failed'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testDoDelete() {
        Account a = new Account(Name = 'Test Account');
        IDML dml = new DML();
        dml.doInsert(a);

        Test.startTest();
        dml.doDelete(a);
        Test.stopTest();

        List<Account> result = [SELECT Id, Name FROM Account WHERE Id = :a.Id];

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testDoDeleteError() {
        Account acc = new Account(
            Name = 'Test Account',
            Id = TestFactory.generateMockId('Account')
        );
        IDML dml = new DML();

        Test.startTest();
        try {
            dml.doDelete(acc);
            Assert.isTrue(false);
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Delete failed'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testDoUpsert() {
        Account a = new Account(Name = 'Test Account');
        IDML dml = new DML();

        Test.startTest();
        dml.doUpsert(a);
        Test.stopTest();

        Account result = [SELECT Id, Name FROM Account WHERE Id = :a.Id];

        System.assertEquals('Test Account', result.Name);
    }

    @IsTest
    static void testDoUpsertError() {
        Account acc = new Account(
            Name = 'Test Account',
            Id = TestFactory.generateMockId('Account')
        );
        IDML dml = new DML();

        Test.startTest();
        try {
            dml.doUpsert(acc);
            Assert.isTrue(false);
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Upsert failed'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testDoUndelete() {
        Account a = new Account(Name = 'Test Account');
        IDML dml = new DML();
        dml.doInsert(a);

        Test.startTest();
        dml.doDelete(a);
        dml.doUndelete(a);
        Test.stopTest();

        List<Account> result = [SELECT Id, Name FROM Account WHERE Id = :a.Id];

        System.assertEquals(1, result.size());
    }

    @IsTest
    static void testDoHardDelete() {
        Account a = new Account(Name = 'Test Account');
        IDML dml = new DML();
        dml.doInsert(a);

        Test.startTest();
        dml.doDelete(a);
        dml.doHardDelete(a);
        try {
            dml.doUndelete(a);
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Undelete failed'));
        }
        Test.stopTest();

        List<Account> result = [SELECT Id, Name FROM Account WHERE Id = :a.Id];

        System.assertEquals(0, result.size());
    }
}
