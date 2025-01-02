public abstract class SObjectSelector {
    public String sObjectType;
    public List<String> defaultFields;

    System.AccessLevel accessLevel = System.AccessLevel.SYSTEM_MODE;

    @TestVisible
    protected QueryBuilder builder;

    public SObjectSelector(String sObjectType) {
        this.sObjectType = sObjectType;
        this.defaultFields = new List<String>{ 'Id' };
    }

    public SObjectSelector(String sObjectType, List<String> fields) {
        this.sObjectType = sObjectType;
        this.defaultFields = fields;
    }

    public SObjectSelector(ISchemaSObject schema) {
        this.sObjectType = schema.getQuerySObject();
        this.defaultFields = schema.getQueryFields();
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

    public String getQuery() {
        return this.builder.getQuery().toString();
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
