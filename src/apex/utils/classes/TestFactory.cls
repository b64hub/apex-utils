@IsTest
@SuppressWarnings('PMD.ExcessivePublicCount')
public class TestFactory {
    public static MockIdGenerator mockIdGenerator = new MockIdGenerator();
    String sObjectType;
    public List<SObject> records;

    Schema.DescribeSObjectResult sObjectDescribe;

    public TestFactory(String sObjectType) {
        this.sObjectType = sObjectType;
        this.getDescribe();
        this.records = (List<SObject>) Type.forName('List<' + sObjectType + '>')
            .newInstance();
    }

    public TestFactory(Schema.SObjectType sObjectType) {
        this.sObjectDescribe = sObjectType.getDescribe(
            SObjectDescribeOptions.DEFERRED
        );
        this.sObjectType = this.getDescribe().getName();
        this.records = (List<SObject>) Type.forName(
                'List<' + this.sObjectType + '>'
            )
            .newInstance();
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
            return TestFactory.generateMockId(this.sObjectType);
        }
    }

    public class RecordTypeTemplate implements ITemplate {
        String sObjectType;
        String recordTypeName;

        public RecordTypeTemplate(String sObjectType, String recordTypeName) {
            this.sObjectType = sObjectType;
            this.recordTypeName = recordTypeName;
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

    public class JSONSerialize implements ITemplate {
        List<Object> objects;
        Integer counter;

        public JSONSerialize(List<Object> objects) {
            this.objects = objects;
            counter = 0;
        }

        public Object build() {
            counter++;
            return JSON.serialize(
                this.objects[Math.mod(counter - 1, objects.size())]
            );
        }
    }

    public List<SObject> getRecords() {
        return records;
    }

    public List<Id> getIds() {
        return new List<Id>(new Map<Id, SObject>(this.records).keySet());
    }

    public Schema.DescribeSObjectResult getDescribe() {
        if (this.sObjectDescribe == null) {
            try {
                this.sObjectDescribe = ((SObject) Type.forName(this.sObjectType)
                        .newInstance())
                    .getSObjectType()
                    .getDescribe(SObjectDescribeOptions.DEFERRED);
            } catch (Exception e) {
                throw new IllegalArgumentException(
                    'Invalid SObjectType: ' +
                        this.sObjectType +
                        '. Please ensure it is a valid SObject type.'
                );
            }
        }
        return this.sObjectDescribe;
    }

    public TestFactory createRecords(Integer numRecords) {
        for (Integer i = 0; i < numRecords; i++) {
            SObject sObj = this.getDescribe().getSObjectType().newSObject();
            records.add(sObj);
        }

        return this;
    }

    /**
     * @description set the given field to the given value for all records
     *
     * @param fieldName
     * @param value
     */
    public TestFactory setField(String fieldName, Object value) {
        if (value instanceof Iterable<Object>) {
            return this.setField(fieldName, (Iterable<Object>) value);
        } else {
            for (SObject sObj : records) {
                sObj.put(fieldName, value);
            }
            return this;
        }
    }

    /**
     * @description set the given field to the given value for all records
     *
     * @param field
     * @param value
     */
    public TestFactory setField(Schema.SObjectField field, Object value) {
        return this.setField(field.getDescribe().getName(), value);
    }

    /**
     * @description Uses a round-robin approach to set the given field to the given values for all records
     * if the number of values is less than the number of records, the values will be repeated
     *
     * @param fieldName
     * @param values
     */
    public TestFactory setField(String fieldName, Iterable<Object> values) {
        Iterator<Object> it = values.iterator();

        if (!it.hasNext()) {
            return this;
        }

        for (SObject record : this.records) {
            if (!it.hasNext()) {
                it = values.iterator();
            }
            record.put(fieldName, it.next());
        }
        return this;
    }

    public TestFactory setField(
        Schema.SObjectField field,
        Iterable<Object> values
    ) {
        return this.setField(field.getDescribe().getName(), values);
    }

    /**
     * @description set the given field to the value generated by the given template for all records
     *
     * @param fieldName
     * @param template
     */
    public TestFactory setField(String fieldName, ITemplate template) {
        for (SObject sObj : records) {
            sObj.put(fieldName, template.build());
        }
        return this;
    }

    public TestFactory setField(Schema.SObjectField field, ITemplate template) {
        return this.setField(field.getDescribe().getName(), template);
    }

    /**
     * @description DEPRECATED - kept for backwards compatibility use setField(String fieldName, ITemplate template) instead
     */
    public TestFactory setFieldFromTemplate(
        String fieldName,
        ITemplate template
    ) {
        for (SObject sObj : records) {
            sObj.put(fieldName, template.build());
        }
        return this;
    }

    /**
     * @description puts an SObject into the given field for all records
     *
     * @example setSObject('Account', account)
     * @param fieldName
     * @param record
     */
    public TestFactory setSObject(String fieldName, SObject record) {
        for (SObject sObj : records) {
            sObj.putSObject(fieldName, record);
        }
        return this;
    }

    /**
     * @description Uses a round-robin approach to assign the given SObjects to the given field for all records
     * if the number of values is less than the number of records, the values will be repeated
     *
     * @param fieldName
     * @param relatedRecords
     */
    public TestFactory setSObjects(
        String fieldName,
        List<SObject> relatedRecords
    ) {
        if (relatedRecords.isEmpty()) {
            return this;
        }

        for (Integer i = 0; i < records.size(); i++) {
            SObject sObj = records[i];
            sObj.putSObject(
                fieldName,
                relatedRecords[Math.mod(i, relatedRecords.size())]
            );
        }
        return this;
    }

    /**
     * @description RelationshipMatrix is a helper class to create related records. Useful for line items and junction objects
     *
     * @example
     * ```mermaid
     * graph TD
     * A[Account] -->|1| B[Contact]
     * A -->|2| C[Contact]
     *
     * ```
     * List<PriceBookEntries> priceBookEntries = (List<PriceBookEntry>) new TestFactory('PriceBookEntry') // PBE 1, PBE 2, PBE 3
     * List<Opportunity> opportunities = (List<Opportunity>) new TestFactory('Opportunity') // Opp 1, Opp 2
     *
     * // Will create the same price book entries for each opportunity
     * RelationshipMatrix matrix = new RelationshipMatrix(opportunities, priceBookEntries);
     * List<OpportunityLineItems> opportunityLineItems = (List<OpportunityLineItems>) new TestFactory('OpportunityLineItem')
     *   .createRecords(opportunities.size() * priceBookEntries.size())
     *   .setMatrix(matrix)
     *
     */
    public class RelationshipMatrix extends Matrix {
        public override void populate(SObject sObj) {
            sObj.putSObject(this.columnField(), (SObject) this.nextColumn());
            sObj.putSObject(this.rowField(), (SObject) this.nextRow());
        }
    }

    public class FieldMatrix extends Matrix {
        public override void populate(SObject sObj) {
            sObj.put(this.columnField(), this.nextColumn());
            sObj.put(this.rowField(), this.nextRow());
        }
    }

    public abstract class Matrix {
        List<Object> columns;
        List<Object> rows;

        String rowField;
        String columnField;

        Integer rowIndex = 0;
        Integer columnIndex = 0;

        public Matrix setColumn(String field, List<Object> values) {
            this.columnField = field;
            this.columns = values;
            return this;
        }

        public Matrix setRow(String field, List<Object> values) {
            this.rowField = field;
            this.rows = values;
            return this;
        }

        String rowField() {
            return this.rowField;
        }

        String columnField() {
            return this.columnField;
        }

        public List<Object> getRows() {
            return rows;
        }

        public List<Object> getColumns() {
            return columns;
        }

        public Integer size() {
            return rows.size() * columns.size();
        }

        public Object nextRow() {
            Object row = rows[rowIndex];
            rowIndex++;
            if (rowIndex >= rows.size()) {
                rowIndex = 0;
                columnIndex++;
            }
            return row;
        }

        public Object nextColumn() {
            if (columnIndex >= columns.size()) {
                columnIndex = 0;
            }
            return columns[columnIndex];
        }

        public abstract void populate(SObject sObj);
    }

    public TestFactory setMatrix(Matrix matrix) {
        for (Integer i = 0; i < records.size(); i++) {
            matrix.populate(records[i]);
        }
        return this;
    }

    /**
     * @description add mock ids to all records, ensures uniqueness for all records globally
     */
    public TestFactory addMockIds() {
        this.setField('Id', new TestFactory.IdTemplate(this.sObjectType));
        return this;
    }

    /**
     * Set the RecordTypeId field for all records to the given record type name.
     * @param recordTypeName
     */
    public TestFactory setRecordType(String recordTypeName) {
        this.setField(
            'RecordTypeId',
            new TestFactory.RecordTypeTemplate(this.sObjectType, recordTypeName)
        );
        return this;
    }

    /**
     * @description add a related record to all records
     *
     * @param relationshipName
     * @param parent
     */
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
     * @description Recalculate all formulas on all records
     */
    public TestFactory recalculateFormulas() {
        Formula.recalculateFormulas(records);
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
        @SuppressWarnings('PMD.FieldNamingConventions')
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
