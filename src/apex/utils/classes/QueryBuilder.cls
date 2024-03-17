public class QueryBuilder {
    private Query query;

    public QueryBuilder(Schema.SObjectType sObjectType) {
        this.query = new Query(sObjectType.getDescribe().getName());
    }

    public QueryBuilder(String sObjectType) {
        this.query = new Query(sObjectType);
    }

    public virtual class Query implements IQuery {
        public String sObjectType;
        public Set<String> fields;
        public List<IQuery> subQueries;
        public String filter;

        public String sortBy;
        public String limitClause;

        public Query(String sObjectType) {
            this.sObjectType = sObjectType;
            this.fields = new Set<String>();
            this.subQueries = new List<Query>();
            this.filter = null;
            this.sortBy = null;
            this.limitClause = null;
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

            if (filter != null) {
                queryString += ' WHERE ' + filter;
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
        public String field;
        public String operator;
        public String value;
        public String raw;

        public Condition(String field) {
            this.field = field;
        }

        public Condition(String raw, Boolean isRaw) {
            this.raw = raw;
        }

        public ICondition equals(Object value) {
            this.operator = '=';
            return this.setValue(value);
        }

        public ICondition notEquals(Object value) {
            this.operator = '!=';
            return this.setValue(value);
        }

        public ICondition greaterThan(Object value) {
            this.operator = '>';
            return this.setValue(value);
        }

        public ICondition lessThan(Object value) {
            this.operator = '<';
            return this.setValue(value);
        }

        public ICondition isIn(Object value) {
            this.operator = 'IN';
            return this.setValue(value);
        }

        public ICondition matches(Object value) {
            this.operator = 'LIKE';
            return this.setValue(value);
        }

        private ICondition setValue(Object value) {
            this.value = String.valueOf(value);
            return this;
        }

        public virtual override String toString() {
            if (this.raw != null) {
                return this.raw;
            }
            return this.field + ' ' + this.operator + ' ' + this.value;
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

        public ConditionBuilder() {
        }

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
                new ConditionNode(new Condition(condition, true))
            );
        }

        public ConditionBuilder orWith(ICondition condition) {
            return this.addNode('OR', new ConditionNode(condition));
        }

        public ConditionBuilder orWith(String condition) {
            return this.addNode(
                'OR',
                new ConditionNode(new Condition(condition, true))
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

    public QueryBuilder selectField(String field) {
        this.query.fields.add(field);
        return this;
    }

    public QueryBuilder addFilter(String condition) {
        if (this.query.filter == null) {
            this.query.filter = '';
        }
        this.query.filter += condition;
        return this;
    }

    public QueryBuilder addFilter(ICondition condition) {
        return this.addFilter(condition.toString());
    }

    public QueryBuilder addSubQuery(IQuery query) {
        this.query.subQueries.add(query);
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

    public override String toString() {
        return String.escapeSingleQuotes(this.query.toString());
    }
}
