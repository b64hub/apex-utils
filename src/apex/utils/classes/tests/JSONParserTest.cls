@IsTest
public class JSONParserTest {
    public static final String TEST_JSON =
        '{' +
        '   "firstName": "John",' +
        '   "lastName": "Doe",' +
        '   "age": 30,' +
        '   "address": {' +
        '       "street": "123 Main St",' +
        '       "city": "Springfield",' +
        '       "state": "IL",' +
        '       "postalCode": "12345"' +
        '   },' +
        '   "phoneNumbers": [' +
        '       {' +
        '           "type": "home",' +
        '           "number": "555-555-5555"' +
        '       },' +
        '       {' +
        '           "type": "mobile",' +
        '           "number": "555-555-5556"' +
        '       }' +
        '   ]' +
        '}';

    @IsTest
    static void testParse() {
        JSONParser.SObjectMapper mapper = new JSONParser.SObjectMapper(
            Contact.getSObjectType()
        );
        mapper.configure(
            new Map<String, String>{
                'firstName' => 'FirstName',
                'lastName' => 'LastName',
                'salutation' => 'Salutation',
                'address.street' => 'MailingStreet',
                'address.city' => 'MailingCity',
                'address.state' => 'MailingState',
                'address.postalCode' => 'MailingPostalCode',
                'phoneNumbers[0].number' => 'Phone',
                'phoneNumbers[1].number' => 'MobilePhone'
            }
        );

        JSONParser parser = JSONParser.newParser(mapper);

        Test.startTest();
        Contact target = (Contact) parser.parse(TEST_JSON);
        Test.stopTest();

        Assert.areEqual('John', target.FirstName);
        Assert.areEqual('Doe', target.LastName);
        Assert.areEqual(null, target.Salutation);
        Assert.areEqual('123 Main St', target.MailingStreet);
        Assert.areEqual('Springfield', target.MailingCity);
        Assert.areEqual('IL', target.MailingState);
        Assert.areEqual('12345', target.MailingPostalCode);
        Assert.areEqual('555-555-5555', target.Phone);
        Assert.areEqual('555-555-5556', target.MobilePhone);
    }
}
