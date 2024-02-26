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
        public List<String> fields;
        public List<IQuery> subQueries;
        public String filter;

        public String sortBy;
        public String limitClause;

        public Query(String sObjectType) {
            this.sObjectType = sObjectType;
            this.fields = new List<String>();
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
        void setLogical(String logical);
        String toString();
    }

    public virtual class Condition implements ICondition {
        public String field;
        public String operator;
        public String value;
        public String logical;

        public ConditionBuilder builder;

        public Condition(String field) {
            this.field = field;
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
            if (this.builder != null) {
                this.builder.add(this.toString());
                return this.builder;
            }
            return this;
        }

        public virtual void setLogical(String logical) {
            this.logical = logical;
        }

        public void setBuilder(ConditionBuilder builder) {
            this.builder = builder;
        }

        public virtual override String toString() {
            String conditionString = '';
            conditionString += this.logical != null ? this.logical + ' ' : '';
            conditionString += field + ' ' + operator + ' ' + value;
            return conditionString;
        }
    }

    public class ConditionBuilder implements ICondition {
        List<String> conditions;
        String logical;

        public ConditionBuilder() {
            this.conditions = new List<String>();
        }

        public virtual void setLogical(String logical) {
            this.logical = logical;
        }

        public ConditionBuilder andWith(ICondition condition) {
            condition.setLogical('AND');
            this.conditions.add(condition.toString());
            return this;
        }

        public Condition andWith(String field) {
            Condition condition = new Condition(field);
            condition.setBuilder(this);
            condition.setLogical('AND');
            return condition;
        }

        public ConditionBuilder orWith(ICondition condition) {
            condition.setLogical('OR');
            this.conditions.add(condition.toString());
            return this;
        }

        public Condition orWith(String field) {
            Condition condition = new Condition(field);
            condition.setBuilder(this);
            condition.setLogical('OR');
            return condition;
        }

        public ConditionBuilder add(ICondition condition) {
            this.conditions.add(condition.toString());
            return this;
        }

        public Condition start(String field) {
            Condition condition = new Condition(field);
            condition.setBuilder(this);
            return condition;
        }

        public ConditionBuilder add(String condition) {
            this.conditions.add(condition);
            return this;
        }

        public override String toString() {
            return String.join(conditions, ' ');
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
