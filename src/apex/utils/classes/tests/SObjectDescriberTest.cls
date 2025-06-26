@IsTest
public class SObjectDescriberTest {
    @IsTest
    static void testGetLookupField() {
        SObject record = new Contact();
        Schema.DescribeFieldResult result = new SObjectDescriber(record)
            .getLookupField('Account');

        Assert.areEqual('AccountId', result.getName());
        Assert.areEqual('REFERENCE', result.getType().name());
        Assert.areEqual('Account', result.getRelationshipName());
    }

    @IsTest
    static void testHasField() {
        SObject record = new Contact();
        SObjectDescriber describer = new SObjectDescriber(record);
        Boolean hasField = describer.hasField('Name');

        Assert.isTrue(hasField);
    }

    @IsTest
    static void testGetSObjectFieldByApiName() {
        SObject record = new Contact();
        SObjectDescriber describer = new SObjectDescriber(record);
        SObjectField field = describer.getSObjectFieldByApiName('Name');

        Assert.areEqual(Contact.Name, field);
    }

    @IsTest
    static void testGetSObjectFieldByApiNameFieldNotFound() {
        SObject record = new Contact();
        SObjectDescriber describer = new SObjectDescriber(record);

        try {
            SObjectField field = describer.getSObjectFieldByApiName(
                'NonExistingField'
            );
            Assert.fail(
                'SObjectDescriber.SObjectFieldNotFoundException expected'
            );
        } catch (Exception e) {
            Assert.areEqual(
                'SObjectDescriber.SObjectFieldNotFoundException',
                e.getTypeName()
            );
        }
    }
}
