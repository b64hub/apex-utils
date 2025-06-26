public class SObjectDescriber {
    Schema.SObjectType sObjectType;
    Schema.DescribeSObjectResult sObjectDescribe;
    static Map<String, Schema.SObjectType> globalDescribe;

    public SObjectDescriber(Schema.SObjectType sObjectType) {
        this.sObjectType = sObjectType;
        this.sObjectDescribe = this.sObjectType.getDescribe(
            SObjectDescribeOptions.DEFERRED
        );
    }

    public SObjectDescriber(String sObjectType) {
        this(getGlobalDescribe().get(sObjectType));
    }

    public SObjectDescriber(SObject record) {
        this(record.getSObjectType());
    }

    public static Map<String, Schema.SObjectType> getGlobalDescribe() {
        if (globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
        }
        return globalDescribe;
    }

    public Schema.DescribeFieldResult getLookupField(String parentObject) {
        Map<String, Schema.SObjectField> fieldDescriptions = this.sObjectDescribe.fields.getMap();

        for (String apiName : fieldDescriptions.keySet()) {
            Schema.DescribeFieldResult fieldDescription = fieldDescriptions.get(
                    apiName
                )
                .getDescribe();

            if (isLookupTo(fieldDescription, parentObject)) {
                return fieldDescription;
            }
        }

        return null;
    }

    public Boolean hasField(String fieldName) {
        return this.sObjectDescribe.fields.getMap().containsKey(fieldName);
    }

    public static Boolean isLookupTo(
        Schema.DescribeFieldResult fieldDescription,
        String parentObject
    ) {
        return (isReferenceField(fieldDescription) &&
        fieldDescription.getReferenceTo()
            .get(0)
            .getDescribe()
            .getName()
            .equalsIgnoreCase(parentObject));
    }

    public static Boolean isReferenceField(
        Schema.DescribeFieldResult fieldDescription
    ) {
        return (fieldDescription.getType()
            .name()
            .equalsIgnoreCase('REFERENCE') &&
        fieldDescription.getRelationshipName() != null &&
        !fieldDescription.getReferenceTo().isEmpty());
    }

    public Schema.SObjectField getSObjectFieldByApiName(String fieldApiName) {
        if (!this.sObjectDescribe.fields.getMap().containsKey(fieldApiName)) {
            throw new SObjectFieldNotFoundException(
                'Did not find SObjectField for api name: ' + fieldApiName
            );
        }

        return this.sObjectDescribe.fields.getMap().get(fieldApiName);
    }

    public class SObjectFieldNotFoundException extends Exception {
    }
}
