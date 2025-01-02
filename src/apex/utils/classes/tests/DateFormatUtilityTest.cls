@isTest
public class DateFormatUtilityTest {
    @isTest
    static void testFormatDateTime() {
        DateTime testDateTime = DateTime.newInstance(2022, 3, 15, 10, 30, 0);

        Test.startTest();
        String result = DateFormatUtility.formatDateTimetoString(testDateTime);
        Test.stopTest();

        String expected = '15 Mar 2022 10:30';
        Assert.areEqual(expected, result);
    }

    @isTest
    static void testParseDateFromString() {
        String testDateString = '2022-04-20T16:20:00.000Z';

        Test.startTest();
        DateTime result = DateFormatUtility.parseDateTimeFromString(
            testDateString
        );
        Test.stopTest();

        DateTime expected = DateTime.newInstanceGmt(2022, 4, 20, 16, 20, 0);
        Assert.areEqual(expected, result, 'Date should be parsed correctly');
    }

    @IsTest
    static void testFormatDate() {
        Date testDate = Date.newInstance(2022, 3, 15);

        Test.startTest();
        String result = DateFormatUtility.formatDateToString(
            testDate,
            'yyyy-MM-dd'
        );
        Test.stopTest();

        Assert.areEqual('2022-03-15', result);
    }

    @IsTest
    static void testParseDateFromStringFormat() {
        String testDateString = '20.04.2022';

        Test.startTest();
        Date result = DateFormatUtility.parseDateFromString(
            testDateString,
            'dd.MM.yyyy'
        );
        Test.stopTest();

        Date expected = Date.newInstance(2022, 4, 20);
        Assert.areEqual(expected, result);
    }
}
