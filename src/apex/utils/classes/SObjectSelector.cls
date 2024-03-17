public abstract class SObjectSelector {
    public String sObjectType;
    public List<String> defaultFields;

    public SObjectSelector() {
    }

    public SObjectSelector(String sObjectType) {
        this.sObjectType = sObjectType;
        this.defaultFields = new List<String>{ 'Id' };
    }

    public SObjectSelector(String sObjectType, List<String> fields) {
        this.sObjectType = sObjectType;
        this.defaultFields = fields;
    }

    public virtual List<SObject> getWhere(String field, Object value) {
        QueryBuilder builder = new QueryBuilder(this.sObjectType)
            .selectFields(this.defaultFields)
            .addFilter(new QueryBuilder.Condition(field).equals(':value'));

        return Database.query(builder.toString());
    }

    public virtual List<SObject> getWhereIdIn(Set<Id> ids) {
        QueryBuilder builder = new QueryBuilder(this.sObjectType)
            .selectFields(this.defaultFields)
            .addFilter(new QueryBuilder.Condition('Id').isIn(':ids'));

        return Database.query(builder.toString());
    }
}
