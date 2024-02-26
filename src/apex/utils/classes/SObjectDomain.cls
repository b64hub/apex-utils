public abstract class SObjectDomain {
    public List<SObject> records;
    public String sObjectType;

    public SObjectDomain(List<SObject> records) {
        this.records = records;
    }
}
