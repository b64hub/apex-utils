public interface IDML {
    SObject doInsert(SObject record);
    List<SObject> doInsert(List<SObject> records);
    SObject doUpdate(SObject record);
    List<SObject> doUpdate(List<SObject> records);
    SObject doUpsert(SObject record);
    List<SObject> doUpsert(List<SObject> records);
    List<SObject> doUpsert(
        List<SObject> records,
        Schema.SObjectField externalIDField
    );
    SObject doUndelete(SObject record);
    List<SObject> doUndelete(List<SObject> records);

    void doDelete(SObject record);
    void doDelete(List<SObject> records);
    void doHardDelete(SObject record);
    void doHardDelete(List<SObject> records);

    void doPublish(List<SObject> events);
}
