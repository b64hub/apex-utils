public abstract class SObjectDomain {
    public List<SObject> records;
    public String sObjectType;

    public SObjectDomain(String sObjectType, List<SObject> records) {
        this.records = records;
        this.sObjectType = sObjectType;
    }

    public SObjectDomain() {
        this(null, new List<SObject>());
    }

    public SObjectDomain(List<SObject> records) {
        this(records.get(0)?.getSObjectType().getDescribe().getName(), records);
    }

    public SObjectDomain(String sObjectType) {
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
}
