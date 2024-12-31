public virtual class RecordCollection {
    public List<SObject> records;

    @TestVisible
    protected Map<String, Object> attributes = new Map<String, Object>();

    public class TypeException extends Exception {}

    public RecordCollection(List<SObject> records) {
        if (records.getSObjectType() == null) {
            throw new TypeException('List must have a defined sObjectType');
        }

        this.records = records;
    }

    public void add(SObject record) {
        if (record.getSObjectType() == null || record.getSObjectType() != this.getSObjectType()) {
            throw new TypeException('Can only add record of same sObjectType. Tried adding record of ' + 
                record.getSObjectType() + 
                ' to list of ' + 
                this.getSObjectType()
            );
        }

        this.records.add(record);
    }

    public void add(List<SObject> records) {
        if (records.getSObjectType() == null || records.getSObjectType() != this.getSObjectType()) {
            throw new TypeException('Can only add list of same sObjectType. Tried adding list of ' + 
                records.getSObjectType() + 
                ' to list of ' + 
                this.getSObjectType()
            );
        }

        this.records.addAll(records);
    }

    public void add(RecordCollection collection) {
        if (collection.getSObjectType() != this.getSObjectType()) {
            throw new TypeException('Can only add collection of same sObjectType. Tried adding collection of ' + 
                collection.getSObjectType() + 
                ' to collection of ' + 
                this.getSObjectType()
            );
        }

        this.records.addAll(collection.getRecords());
    }

    public List<SObject> getRecords() {
        return this.records;
    }

    public Schema.SObjectType getSObjectType() {
        return this.records.getSObjectType();
    }

    public Map<String, Schema.RecordTypeInfo> getRecordTypeInfos() {
        return this.getSObjectType()
            .getDescribe()
            .getRecordTypeInfosByDeveloperName();
    }

    public void setFields(Map<String, Object> fields) {
        for (SObject record : this.records) {
            for (String key : fields.keySet()) {
                record.put(key, fields.get(key));
            }
        }
    }

    public void setField(String field, Object value) {
        for (SObject record : this.records) {
            record.put(field, value);
        }
    }

    public List<SObject> setField(
        Map<String, Object> fields,
        FilterBuilder.IFilter filter
    ) {
        List<SObject> changedRecords = new List<SObject>();
        for (SObject record : FilterBuilder.fastFilter(this.records, filter)) {
            for (String key : fields.keySet()) {
                record.put(key, fields.get(key));
            }
            changedRecords.add(record);
        }
        return changedRecords;
    }

    public List<Object> getValues(String field) {
        List<Object> values = new List<Object>();
        for (SObject record : this.records) {
            values.add(record.get(field));
        }
        return values;
    }

    public List<Id> getIds() {
        return new List<Id>(new Map<Id, SObject>(this.records).keySet());
    }

    public Map<Object, List<SObject>> segmentOnField(String field) {
        Map<Object, List<SObject>> recordsByFieldValue = new Map<Object, List<SObject>>();
        for (SObject record : this.records) {
            Object fieldValue = record.get(field);

            if (!recordsByFieldValue.containsKey(fieldValue)) {
                recordsByFieldValue.put(fieldValue, new List<SObject>());
            }

            recordsByFieldValue.get(fieldValue).add(record);
        }

        return recordsByFieldValue;
    }


    public class AttributeException extends Exception {
        String attribute;

        public AttributeException(String attribute, String message) {
            super(message);
            this.attribute = attribute;
        }
    }

    public void addAttribute(String key, Object value) {
        this.attributes.put(key, value);
    }

    public Object getAttribute(String key) {
        Object attribute = this.attributes.get(key);
        if (attribute == null) {
            throw new AttributeException(key, 'Attribute not found: ' + key);
        }
        return attribute;
    }

    public void removeAttribute(String key) {
        this.attributes.remove(key);
    }

    public void clearAttributes() {
        this.attributes.clear();
    }

    public void extractAttributes(String field) {
        this.attributes.put(field, this.getValues(field));
    }

}
