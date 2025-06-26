public abstract class SObjectSelector {
    public String sObjectType;
    public List<String> defaultFields;

    System.AccessLevel accessLevel = System.AccessLevel.SYSTEM_MODE;

    @TestVisible
    protected QueryBuilder builder;

    public SObjectSelector(String sObjectType, List<String> fields) {
        this.sObjectType = sObjectType;
        this.defaultFields = fields;

        this.builder = new QueryBuilder(this.sObjectType)
            .selectFields(this.defaultFields);
    }

    public SObjectSelector(
        Schema.SObjectType sObjectType,
        List<String> fields
    ) {
        this(sObjectType.getDescribe().getName(), fields);
    }

    public SObjectSelector(
        Schema.SObjectType sObjectType,
        List<Schema.SObjectField> fields
    ) {
        this.sObjectType = sObjectType.getDescribe().getName();

        this.defaultFields = new List<String>();
        for (Schema.SObjectField field : fields) {
            this.defaultFields.add(field.getDescribe().getName());
        }

        this.builder = new QueryBuilder(this.sObjectType)
            .selectFields(this.defaultFields);
    }

    public SObjectSelector(String sObjectType) {
        this(sObjectType, new List<String>{ 'Id' });
    }

    public SObjectSelector(ISchemaSObject schema) {
        this(schema.getQuerySObject(), schema.getQueryFields());
    }

    public class QueryException extends Exception {
        String query;

        public QueryException(String message, String query) {
            this.setMessage(message);
            this.query = query;
        }
    }

    public System.AccessLevel getAccessLevel() {
        return this.accessLevel;
    }

    public String getQueryString() {
        return this.builder.toString();
    }

    public QueryBuilder.Query getQuery() {
        return (QueryBuilder.Query) this.builder.getQuery();
    }

    /**
     * @deprecated use specific implementations in selectors
     */
    public virtual List<SObject> getWhere(String field, Object value) {
        QueryBuilder builder = new QueryBuilder(this.sObjectType)
            .selectFields(this.defaultFields)
            .addFilter(new QueryBuilder.Condition(field).equals(':value'));

        return Database.query(builder.toString());
    }

    /**
     * @deprecated use the pattern in `byIds` instead
     */
    public virtual List<SObject> getWhereIdIn(Set<Id> ids) {
        QueryBuilder builder = new QueryBuilder(this.sObjectType)
            .selectFields(this.defaultFields)
            .addFilter(new QueryBuilder.Condition('Id').isIn(':ids'));

        return Database.query(builder.toString());
    }

    public virtual SObjectSelector byIds(Set<Id> ids) {
        this.builder.addFilter('Id IN :ids');
        this.builder.setVariable('ids', ids);
        return this;
    }

    /**
     * @deprecated use specific implementations in selectors
     */
    public virtual List<SObject> getWhereIn(String field, List<Object> values) {
        QueryBuilder builder = new QueryBuilder(this.sObjectType)
            .selectFields(this.defaultFields)
            .addFilter(new QueryBuilder.Condition(field).isIn(':values'));

        return Database.query(builder.toString());
    }

    public virtual List<SObject> query() {
        return Database.queryWithBinds(
            this.builder.getQuery().toString(),
            this.builder.getVariables(),
            this.getAccessLevel()
        );
    }

    /**
     * Future implementation
     */
    // public virtual List<List<SObject>> search() {
    //     return Search.find(this.getQuery(), this.getAccessLevel())
    // }
}
