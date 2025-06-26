@SuppressWarnings('PMD.ExcessivePublicCount')
public class QueryBuilder {
    private Query query;
    public Config config = new Config();

    Map<String, Object> bindVariables = new Map<String, Object>();

    public class Config {
        public String defaultChain = 'AND';
    }

    public QueryBuilder(Schema.SObjectType sObjectType) {
        this.query = new Query(
            sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getName()
        );
        this.query.filterChain = this.config.defaultChain;
    }

    public QueryBuilder(String sObjectType) {
        this.query = new Query(sObjectType);
    }

    public virtual class Query implements IQuery {
        public String sObjectType;
        public Set<String> fields;
        public List<IQuery> subQueries;
        public List<ICondition> filters;

        public String sortBy;
        public String limitClause;

        public String filterChain = 'AND';

        public Query(String sObjectType) {
            this.sObjectType = sObjectType;
            this.fields = new Set<String>();
            this.subQueries = new List<Query>();
            this.filters = new List<ICondition>();
            this.sortBy = null;
            this.limitClause = null;
        }

        private String resolveFilter() {
            if (filters.size() == 1) {
                return this.filters[0].toString();
            }

            String filter = '';

            for (ICondition condition : filters) {
                filter +=
                    '(' +
                    condition.toString() +
                    ') ' +
                    this.filterChain +
                    ' ';
            }

            return filter.removeEnd(' ' + this.filterChain + ' ');
        }

        public override String toString() {
            String queryString = '';
            queryString += 'SELECT ' + String.join(fields, ', ');

            if (subQueries.size() > 0) {
                for (IQuery subQuery : subQueries) {
                    queryString += ', (' + subQuery.toString() + ')';
                }
            }

            queryString += ' FROM ' + sObjectType;

            if (!this.filters.isEmpty()) {
                queryString += ' WHERE ' + this.resolveFilter();
            }

            if (sortBy != null) {
                queryString += ' ORDER BY ' + sortBy;
            }

            if (limitClause != null) {
                queryString += ' LIMIT ' + limitClause;
            }

            return String.escapeSingleQuotes(queryString);
        }
    }

    public interface ICondition {
        String toString();
    }

    public virtual class Condition implements ICondition {
        public String expression;

        public String field;
        public String operator;
        public Object value;

        public Condition(String expression) {
            if (expression.containsWhitespace()) {
                this.expression = expression;
            } else {
                this.field = expression;
            }
        }

        public Condition(Schema.SObjectField field) {
            this.field = field.getDescribe().getName();
        }

        public String equals(Object value) {
            this.operator = '=';
            return this.setValue(value);
        }

        public String notEquals(Object value) {
            this.operator = '!=';
            return this.setValue(value);
        }

        public String greaterThan(Object value) {
            this.operator = '>';
            return this.setValue(value);
        }

        public String lessThan(Object value) {
            this.operator = '<';
            return this.setValue(value);
        }

        public String isIn(Object value) {
            this.operator = 'IN';
            return this.setValue(value);
        }

        public String matches(Object value) {
            this.operator = 'LIKE';
            return this.setValue(value);
        }

        public String inSubQuery(IQuery subQuery) {
            this.operator = 'IN';
            return this.setValue('( ' + subQuery.toString() + ' )');
        }

        private String setValue(Object value) {
            this.value = value;
            this.expression =
                this.field +
                ' ' +
                this.operator +
                ' ' +
                String.valueOf(value);
            return this.expression;
        }

        public virtual override String toString() {
            return this.expression;
        }
    }

    public class ConditionNode implements ICondition {
        ICondition condition;
        String logical;

        public ConditionNode left;
        public ConditionNode right;

        public ConditionNode(ICondition condition) {
            this.condition = condition;
        }

        public ConditionNode(String expression) {
            this.condition = new Condition(expression);
        }

        public ConditionNode(
            String logical,
            ConditionNode left,
            ConditionNode right
        ) {
            this.setLogical(logical);
            this.left = left;
            this.right = right;
        }

        public void setLogical(String logical) {
            this.logical = logical;
        }

        public override String toString() {
            if (this.condition != null) {
                return this.condition.toString();
            }
            if (this.logical != null) {
                return this.left.toString() +
                    ' ' +
                    this.logical +
                    ' ' +
                    this.right.toString();
            }
            return '';
        }
    }

    public class ConditionBuilder implements ICondition {
        ConditionNode root;

        public ConditionBuilder addNode(String logical, ConditionNode node) {
            if (this.root == null) {
                this.root = node;
            } else {
                this.root = new ConditionNode(logical, this.root, node);
            }
            return this;
        }

        public ConditionBuilder andWith(ICondition condition) {
            return this.addNode('AND', new ConditionNode(condition));
        }

        public ConditionBuilder andWith(String condition) {
            return this.addNode(
                'AND',
                new ConditionNode(new Condition(condition))
            );
        }

        public ConditionBuilder orWith(ICondition condition) {
            return this.addNode('OR', new ConditionNode(condition));
        }

        public ConditionBuilder orWith(String condition) {
            return this.addNode(
                'OR',
                new ConditionNode(new Condition(condition))
            );
        }

        public override String toString() {
            return this.root.toString();
        }
    }

    public QueryBuilder selectFields(List<String> fields) {
        this.query.fields.addAll(fields);
        return this;
    }

    public QueryBuilder selectFields(List<Schema.SObjectField> fields) {
        for (Schema.SObjectField field : fields) {
            this.query.fields.add(field.getDescribe().getName());
        }
        return this;
    }

    public QueryBuilder selectField(String field) {
        this.query.fields.add(field);
        return this;
    }

    public QueryBuilder selectField(Schema.SObjectField field) {
        this.query.fields.add(field.getDescribe().getName());
        return this;
    }

    public QueryBuilder addFilter(String condition) {
        this.query.filters.add(new Condition(condition));
        return this;
    }

    public QueryBuilder addFilter(ICondition condition) {
        this.query.filters.add(condition);
        return this;
    }

    public QueryBuilder addSubQuery(IQuery query) {
        this.query.subQueries.add(query);
        return this;
    }

    public QueryBuilder addSubQuery(String relationShipName, Query query) {
        query.sObjectType = relationShipName;
        return this.addSubQuery(query);
    }

    public QueryBuilder addSubQuery(
        String relationShipName,
        List<String> fields
    ) {
        Query subQuery = new Query(relationShipName);
        subQuery.fields.addAll(fields);
        return this.addSubQuery(subQuery);
    }

    public QueryBuilder addParentFields(String relationShipName, Query query) {
        for (String field : query.fields) {
            this.query.fields.add(relationShipName + '.' + field);
        }
        return this;
    }

    public QueryBuilder addParentFields(
        String relationShipName,
        List<String> fields
    ) {
        for (String field : fields) {
            this.query.fields.add(relationShipName + '.' + field);
        }
        return this;
    }

    public QueryBuilder sortBy(String field) {
        this.query.sortBy = field;
        return this;
    }

    public QueryBuilder setLimit(Integer recordLimit) {
        this.query.limitClause = String.valueOf(recordLimit);
        return this;
    }

    public IQuery getQuery() {
        return this.query;
    }

    public QueryBuilder setVariable(String variable, Object value) {
        this.bindVariables.put(variable, value);
        return this;
    }

    public Map<String, Object> getVariables() {
        return this.bindVariables;
    }

    public override String toString() {
        return String.escapeSingleQuotes(this.query.toString());
    }
}
