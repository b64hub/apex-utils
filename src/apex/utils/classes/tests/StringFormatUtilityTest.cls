@isTest
public with sharing class StringFormatUtilityTest {
    @isTest
    static void testFormatString() {
        String testString = '<p>This is a <b>formatted</b> string.</p>';

        Test.startTest();
        String result = StringFormatUtility.stripHtmlTags(testString);
        Test.stopTest();

        String expected = 'This is a formatted string.';
        System.assertEquals(expected, result);
    }

    @isTest
    static void testConvertUserName() {
        Profile admin = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
        ];

        User testUser = new User(
            IsActive = true,
            FirstName = 'Wholesale',
            LastName = 'User1',
            Username = 'wholesaleUser1@telenor.no',
            Email = 'wholesaleUser1@telenor.no',
            CommunityNickname = 'wUser1',
            Alias = 'wUser1',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'no_NO',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = admin.Id,
            UserRoleId = null
        );

        insert testUser;

        String nickName = 'wUser1';
        String expected = 'Wholesale User1';

        Test.startTest();
        String result = StringFormatUtility.convertNickNameToUserName(nickName);
        Test.stopTest();

        System.assertEquals(expected, result);
    }

    @isTest
    static void testGetInitials() {
        String testName = 'John Doe';

        Test.startTest();
        String result = StringFormatUtility.getInitials(testName);
        Test.stopTest();

        String expected = 'JD';
        System.assertEquals(expected, result);
    }

    @isTest
    static void testBlankGetInitials() {
        String testName = 'John';

        Test.startTest();
        String result = StringFormatUtility.getInitials(testName);
        Test.stopTest();

        String expected = '';
        System.assertEquals(expected, result);
    }

    @IsTest
    static void testNameConcat() {
        String firstName = 'Michael';
        String lastName = 'Scott';

        Assert.areEqual(
            'Michael Scott',
            StringFormatUtility.nameConcat(firstName, lastName)
        );
        Assert.areEqual(
            'Michael',
            StringFormatUtility.nameConcat(firstName, null)
        );
        Assert.areEqual(
            'Scott',
            StringFormatUtility.nameConcat(null, lastName)
        );
    }

    @isTest
    static void testCamelCaseAllWords() {
        Assert.areEqual(
            'Lol_Ol_Q',
            StringFormatUtility.camelCaseAllWords('lol_ol_q', '_')
        );
    }

    @isTest
    static void ifNullReplaceWithEmpty() {
        String inputNotNull = '13';
        Assert.areEqual(
            inputNotNull,
            StringFormatUtility.ifNullReplaceWithEmpty(inputNotNull)
        );

        String inputNull = null;
        Assert.areEqual(
            '',
            StringFormatUtility.ifNullReplaceWithEmpty(inputNull)
        );
    }

    @isTest
    static void ifNullReplaceWith() {
        Assert.areEqual(
            'init',
            StringFormatUtility.ifNullReplaceWith(null, 'init')
        );
        Assert.areEqual(
            'tested',
            StringFormatUtility.ifNullReplaceWith('tested', 'replace')
        );
    }
}
