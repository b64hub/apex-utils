public virtual class RecordCollection {
    public List<SObject> records;
    public String sObjectType;

    @TestVisible
    protected Map<String, Object> attributes = new Map<String, Object>();

    public RecordCollection(String sObjectType, List<SObject> records) {
        this.records = records;
        this.sObjectType = sObjectType;
    }

    public RecordCollection() {
        this(null, new List<SObject>());
    }

    public RecordCollection(List<SObject> records) {
        this(records.get(0)?.getSObjectType().getDescribe().getName(), records);
    }

    public RecordCollection(String sObjectType) {
        this(sObjectType, new List<SObject>());
    }

    public void addRecords(List<SObject> records) {
        this.records.addAll(records);
    }

    public List<SObject> getRecords() {
        return this.records;
    }

    public String getSObjectType() {
        return this.sObjectType;
    }

    public Map<String, Schema.RecordTypeInfo> getRecordTypeInfos() {
        return Schema.getGlobalDescribe()
            .get(this.sObjectType)
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
