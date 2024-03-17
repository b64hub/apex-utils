@IsTest
public class QueryBuilderTest {
    @IsTest
    static void testQueryBuilder() {
        QueryBuilder qb = new QueryBuilder('Account')
            .selectFields(new List<String>{ 'Id', 'Name' })
            .addFilter('Name = "Dunder Mifflin"')
            .sortBy('Name ASC')
            .setLimit(10);

        Assert.areEqual(
            'SELECT Id, Name FROM Account WHERE Name = "Dunder Mifflin" ORDER BY Name ASC LIMIT 10',
            qb.toString()
        );
    }

    @IsTest
    static void testConditionBuilder() {
        QueryBuilder.ConditionBuilder builder = new QueryBuilder.ConditionBuilder();

        builder.andWith(
            new QueryBuilder.Condition('Name').matches('"Michael%"')
        );
        builder.andWith(
            new QueryBuilder.Condition('Title').equals('"Regional Manager"')
        );
        builder.orWith(
            new QueryBuilder.Condition('Title')
                .notEquals('"Assistant to the Regional Manager"')
        );
        builder.andWith(new QueryBuilder.Condition('Age').greaterThan(40));
        builder.andWith('MailingCity = "Scranton"');

        Assert.areEqual(
            'Name LIKE "Michael%" AND Title = "Regional Manager" OR Title != "Assistant to the Regional Manager" AND Age > 40 AND MailingCity = "Scranton"',
            builder.toString()
        );
    }

    @IsTest
    static void testQueryWithCondition() {
        QueryBuilder.ConditionBuilder builder = new QueryBuilder.ConditionBuilder();

        builder.andWith(
            new QueryBuilder.Condition('Name').matches('"Michael%"')
        );
        builder.orWith(
            new QueryBuilder.Condition('Title').equals('"Regional Manager"')
        );
        builder.andWith(new QueryBuilder.Condition('Age').lessThan(60));

        QueryBuilder subQuery = new QueryBuilder('Account__r')
            .selectFields(new List<String>{ 'Id', 'Name' })
            .addFilter('Name = "Dunder Mifflin"');

        QueryBuilder qb = new QueryBuilder(Contact.getSObjectType())
            .selectField('Id')
            .addFilter(builder)
            .addSubQuery(subQuery.getQuery())
            .sortBy('Name ASC')
            .setLimit(10);

        Assert.areEqual(
            'SELECT Id, (SELECT Id, Name FROM Account__r WHERE Name = "Dunder Mifflin") FROM Contact WHERE Name LIKE "Michael%" OR Title = "Regional Manager" AND Age < 60 ORDER BY Name ASC LIMIT 10',
            qb.toString()
        );
    }
}
