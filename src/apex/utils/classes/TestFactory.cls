@IsTest
public class TestFactory {
    public static MockIdGenerator mockIdGenerator = new MockIdGenerator();
    String sObjectType;
    public List<SObject> records = new List<SObject>();

    public TestFactory(String sObjectType) {
        this.sObjectType = sObjectType;
    }

    public class TemplateException extends Exception {
    }

    public interface ITemplate {
        Object build();
    }

    public class StringTemplate implements ITemplate {
        String template;
        Integer count = 0;
        Map<String, Object> params = new Map<String, Object>();
        List<String> reservedKeywords = new List<String>{ 'i', 'random' };

        public StringTemplate(String template) {
            this.template = template;
        }

        public StringTemplate set(String key, Object value) {
            if (reservedKeywords.contains(key)) {
                throw new TestFactory.TemplateException(
                    'Cannot use reserved keyword: ' + key
                );
            }
            params.put(key, value);
            return this;
        }

        public Object build() {
            String result = template;
            if (result.contains('{{i}}')) {
                result = result.replace('{{i}}', this.count());
            }

            if (result.contains('{{random}}')) {
                result = result.replace('{{random}}', this.random());
            }

            for (String key : params.keySet()) {
                result = result.replace(
                    '{{' + key + '}}',
                    String.valueOf(params.get(key))
                );
            }
            return result;
        }

        public String count() {
            return String.valueOf(count++);
        }

        public String random() {
            return String.valueOf(Math.random());
        }
    }

    public class CountTemplate implements ITemplate {
        Integer count = 0;
        Integer interval = 1;

        public CountTemplate() {
        }

        public CountTemplate(Integer count) {
            this.count = count;
        }

        public CountTemplate setInterval(Integer interval) {
            this.interval = interval;
            return this;
        }

        public Object build() {
            count += interval;
            return count;
        }
    }

    public class IdTemplate implements ITemplate {
        String sObjectType;

        public IdTemplate(String sObjectType) {
            this.sObjectType = sObjectType;
        }

        public Object build() {
            return generateMockId(this.sObjectType);
        }
    }

    public class RecordTypeTemplate implements ITemplate {
        String sObjectType;
        String recordTypeName;

        public RecordTypeTemplate(String sObjectType) {
            this.sObjectType = sObjectType;
        }

        public RecordTypeTemplate setRecordType(String recordTypeName) {
            this.recordTypeName = recordTypeName;
            return this;
        }

        public Object build() {
            return ((SObject) Type.forName(this.sObjectType).newInstance())
                .getSObjectType()
                .getDescribe()
                .getRecordTypeInfosByName()
                .get(this.recordTypeName)
                .getRecordTypeId();
        }
    }

    public List<SObject> getRecords() {
        return records;
    }

    public TestFactory createRecords(Integer numRecords) {
        for (Integer i = 0; i < numRecords; i++) {
            SObject sObj = Schema.getGlobalDescribe()
                .get(this.sObjectType)
                .newSObject();
            records.add(sObj);
        }

        return this;
    }

    public TestFactory setField(String fieldName, Object value) {
        for (SObject sObj : records) {
            sObj.put(fieldName, value);
        }
        return this;
    }

    public TestFactory setField(String fieldName, List<Object> values) {
        Integer i = 0;
        for (SObject sObj : records) {
            if (i >= values.size()) {
                i = 0;
            }
            sObj.put(fieldName, values[i]);
            i++;
        }
        return this;
    }

    public TestFactory setFieldFromTemplate(
        String fieldName,
        ITemplate template
    ) {
        for (SObject sObj : records) {
            sObj.put(fieldName, template.build());
        }
        return this;
    }

    public TestFactory setSObject(String fieldName, SObject record) {
        for (SObject sObj : records) {
            sObj.putSObject(fieldName, record);
        }
        return this;
    }

    public TestFactory setSObjects(
        String fieldName,
        List<SObject> relatedRecords
    ) {
        Integer i = 0;
        for (SObject sObj : records) {
            if (i >= relatedRecords.size()) {
                i = 0;
            }
            sObj.putSObject(fieldName, relatedRecords[i]);
            i++;
        }
        return this;
    }

    public TestFactory addMockIds() {
        this.setFieldFromTemplate(
            'Id',
            new TestFactory.IdTemplate(this.sObjectType)
        );
        return this;
    }

    public TestFactory setRecordType(String recordTypeName) {
        this.setFieldFromTemplate(
            'RecordTypeId',
            new TestFactory.RecordTypeTemplate(this.sObjectType)
                .setRecordType(recordTypeName)
        );
        return this;
    }

    public TestFactory addRelated(String relationshipName, SObject parent) {
        if (
            relationshipName.endsWith('__c') || relationshipName.endsWith('Id')
        ) {
            this.setField(relationshipName, parent.get('Id'));
        } else {
            this.setSObject(relationshipName, parent);
        }
        return this;
    }

    /**
     * Create a copy of this factory with the same records.
     */
    public TestFactory copy() {
        TestFactory copyfactory = new TestFactory(this.sObjectType);
        copyfactory.records = records.deepClone(true);
        return copyfactory;
    }

    /**
     * Utility method. Generate a mock Id for the given SObjectType.
     *
     * @param sObjectType
     */
    public static Id generateMockId(String sObjectType) {
        return mockIdGenerator.generate(sObjectType);
    }

    public class MockIdGenerator {
        Integer mockIdCount = 0;
        final String ID_PATTERN = '000000000000';

        public Id generate(String sObjectType) {
            Schema.SObjectType sObjType = Schema.getGlobalDescribe()
                .get(sObjectType);

            mockIdCount++;
            String mockIdPrefix = ID_PATTERN.substring(
                0,
                12 - String.valueOf(mockIdCount).length()
            );

            return Id.valueOf(
                sObjType.getDescribe().getKeyPrefix() +
                    mockIdPrefix +
                    mockIdCount
            );
        }
    }
}
