public with sharing class QueryRunner {

    AccessLevel defaultAccessLevel = AccessLevel.USER_MODE;

    @TestVisible
    private List<SObject> mockResults;

    public QueryRunner() {

    }

    public List<SObject> run(String query) {
        return this.run(query, this.defaultAccessLevel);
    }

    public List<SObject> run(String query, AccessLevel accessLevel) {
        if (this.mockResults != null) {
            return mockResults;
        }

        return Database.query(query, accessLevel);
    }

    public List<SObject> run(String query, Map<String, Object> binds) {
        return this.run(query, binds, this.defaultAccessLevel);
    }

    public List<SObject> run(String query, Map<String, Object> binds, AccessLevel accessLevel) {
        if (this.mockResults != null) {
            return mockResults;
        }

        return Database.queryWithBinds(query, binds, accessLevel);
    }


    public void setDefaultAccessLevel(AccessLevel accessLevel) {
        this.defaultAccessLevel = accessLevel;
    }

    @TestVisible
    private void setMockResults(List<SObject> mockResults) {
        this.mockResults = mockResults;
    }

}