public class FilterBuilder {
    public Node root;
    List<SObject> records;

    private static Map<String, String> FILTER_SHORTHANDS = new Map<String, String>{
        'eq' => 'FilterBuilder.Equals',
        '==' => 'FilterBuilder.Equals',
        'ne' => 'FilterBuilder.NotEquals',
        '!=' => 'FilterBuilder.NotEquals',
        'lt' => 'FilterBuilder.LessThan',
        '<' => 'FilterBuilder.LessThan',
        'gt' => 'FilterBuilder.GreaterThan',
        '>' => 'FilterBuilder.GreaterThan',
        'lte' => 'FilterBuilder.LessThanOrEq',
        '<=' => 'FilterBuilder.LessThanOrEq',
        'gte' => 'FilterBuilder.GreaterThanOrEq',
        '>=' => 'FilterBuilder.GreaterThanOrEq',
        'contains' => 'FilterBuilder.Contains',
        'isset' => 'FilterBuilder.IsSet',
        'notset' => 'FilterBuilder.NotSet',
        'isnew' => 'FilterBuilder.IsNew',
        'isupdated' => 'FilterBuilder.IsUpdated',
        'isdeleted' => 'FilterBuilder.IsDeleted',
        'ischanged' => 'FilterBuilder.IsChanged'
    };

    private static Map<String, LogicalOperator> LOGICAL_SHORTHANDS = new Map<String, LogicalOperator>{
        'and' => LogicalOperator.op_AND,
        'or' => LogicalOperator.op_OR,
        'not' => LogicalOperator.op_NOT,
        'xor' => LogicalOperator.op_XOR,
        'nand' => LogicalOperator.op_NAND
    };

    public class FilterException extends Exception {
    }

    public static List<SObject> fastFilter(
        List<SObject> records,
        IFilter filter
    ) {
        return FilterBuilder.newBuilder(records).andFilter(filter).apply();
    }

    public static FilterBuilder newBuilder(List<SObject> records) {
        FilterBuilder builder = new FilterBuilder();
        builder.setRecords(records);
        return builder;
    }

    public FilterBuilder setRecords(List<SObject> records) {
        this.records = records.clone();
        return this;
    }

    public Node getFilter() {
        return root;
    }

    public FilterBuilder andFilter(IFilter filter) {
        return this.addFilter(LogicalOperator.op_AND, filter);
    }

    public FilterBuilder orFilter(IFilter filter) {
        return this.addFilter(LogicalOperator.op_OR, filter);
    }

    public FilterBuilder notFilter() {
        return this.addFilter(LogicalOperator.op_NOT, null);
    }

    public FilterBuilder xorFilter(IFilter filter) {
        return this.addFilter(LogicalOperator.op_XOR, filter);
    }

    public FilterBuilder nandFilter(IFilter filter) {
        return this.addFilter(LogicalOperator.op_NAND, filter);
    }

    public FilterBuilder addFilter(String shorthandOperator, IFilter filter) {
        return this.addFilter(
            this.logicalFromShorthand(shorthandOperator),
            filter
        );
    }

    public FilterBuilder addFilter(LogicalOperator operator, IFilter filter) {
        return this.addNode(operator, new Node(filter));
    }

    public FilterBuilder addNode(LogicalOperator operator, Node node) {
        if (root == null) {
            root = node;
        } else {
            root = new Node(operator, root, node);
        }
        return this;
    }

    public FilterBuilder addFilter(
        String field,
        String shorthandFilter,
        Object value
    ) {
        IFilter filter = this.filterFromShorthand(shorthandFilter);
        filter.setField(field);
        filter.setValue(value);
        return this.andFilter(filter);
    }

    public FilterBuilder addFilter(
        String shorthandOperator,
        String field,
        String shorthandFilter,
        Object value
    ) {
        IFilter filter = this.filterFromShorthand(shorthandFilter);
        filter.setField(field);
        filter.setValue(value);
        return this.addFilter(
            this.logicalFromShorthand(shorthandOperator),
            filter
        );
    }

    public List<SObject> apply() {
        List<SObject> result = new List<SObject>();
        for (SObject record : records) {
            if (root.apply(record)) {
                result.add(record);
            }
        }
        return result;
    }

    private Filter filterFromShorthand(String shorthand) {
        Filter filter = (Filter) TypeFactory.newInstance(
            FILTER_SHORTHANDS.get(shorthand)
        );
        if (filter == null) {
            throw new FilterException('Invalid filter shorthand');
        }
        return filter;
    }

    private LogicalOperator logicalFromShorthand(String shorthand) {
        LogicalOperator operator = LOGICAL_SHORTHANDS.get(shorthand);
        if (operator == null) {
            throw new FilterException('Invalid logical shorthand');
        }
        return operator;
    }

    public static Node andNode(IFilter left, IFilter right) {
        return new Node(
            LogicalOperator.op_AND,
            new Node(left),
            new Node(right)
        );
    }

    public static Node orNode(IFilter left, IFilter right) {
        return new Node(LogicalOperator.op_OR, new Node(left), new Node(right));
    }

    public static Node notNode(IFilter filter) {
        return new Node(LogicalOperator.op_NOT, new Node(filter), null);
    }

    public static Node xorNode(IFilter left, IFilter right) {
        return new Node(
            LogicalOperator.op_XOR,
            new Node(left),
            new Node(right)
        );
    }

    public static Node nandNode(IFilter left, IFilter right) {
        return new Node(
            LogicalOperator.op_NAND,
            new Node(left),
            new Node(right)
        );
    }

    public enum LogicalOperator {
        op_AND,
        op_OR,
        op_NOT,
        op_XOR,
        op_NAND
    }

    public class Node {
        IFilter filter;
        LogicalOperator operator;
        Node left;
        Node right;

        public Node(IFilter filter) {
            this.filter = filter;
        }

        public Node(LogicalOperator operator, Node left, Node right) {
            this.operator = operator;
            this.left = left;
            this.right = right;
        }

        public Boolean apply(SObject record) {
            if (filter != null) {
                return filter.apply(record);
            }
            if (operator != null) {
                switch on operator {
                    when op_AND {
                        return left.apply(record) && right.apply(record);
                    }
                    when op_OR {
                        return left.apply(record) || right.apply(record);
                    }
                    when op_NOT {
                        return !left.apply(record);
                    }
                    when op_XOR {
                        return left.apply(record) ^ right.apply(record);
                    }
                    when op_NAND {
                        return !(left.apply(record) && right.apply(record));
                    }
                }
            }
            return false;
        }
    }

    public interface IFilter {
        Boolean apply(SObject record);
        void setField(String field);
        void setValue(Object value);
    }

    public abstract class Filter implements IFilter {
        String field;
        Object value;

        public Filter() {
        }

        public Filter(String field, Object value) {
            this.setField(field);
            this.setValue(value);
        }

        public void setField(String field) {
            this.field = field;
        }

        public void setValue(Object value) {
            this.value = value;
        }

        public abstract Boolean apply(SObject record);
    }

    public class Equals extends Filter {
        public Equals() {
        }

        public Equals(String field, Object value) {
            super(field, value);
        }

        public override Boolean apply(SObject record) {
            return record.get(field) == value;
        }
    }

    public class NotEquals extends Filter {
        public NotEquals() {
        }

        public NotEquals(String field, Object value) {
            super(field, value);
        }

        public override Boolean apply(SObject record) {
            return record.get(field) != value;
        }
    }

    public class LessThan extends Filter {
        public LessThan() {
        }

        public LessThan(String field, Object value) {
            super(field, value);
        }

        public override Boolean apply(SObject record) {
            if (value instanceof Integer) {
                return (Integer) record.get(field) < (Integer) value;
            } else if (value instanceof Double) {
                return (Double) record.get(field) < (Double) value;
            } else if (value instanceof DateTime) {
                return (DateTime) record.get(field) < (Datetime) value;
            }

            return false;
        }
    }

    public class GreaterThan extends Filter {
        public GreaterThan() {
        }

        public GreaterThan(String field, Object value) {
            super(field, value);
        }

        public override Boolean apply(SObject record) {
            if (value instanceof Integer) {
                return (Integer) record.get(field) > (Integer) value;
            } else if (value instanceof Double) {
                return (Double) record.get(field) > (Double) value;
            } else if (value instanceof DateTime) {
                return (DateTime) record.get(field) > (Datetime) value;
            }

            return false;
        }
    }

    public class LessThanOrEq extends Filter {
        public LessThanOrEq() {
        }

        public LessThanOrEq(String field, Object value) {
            super(field, value);
        }

        public override Boolean apply(SObject record) {
            if (value instanceof Integer) {
                return (Integer) record.get(field) <= (Integer) value;
            } else if (value instanceof Double) {
                return (Double) record.get(field) <= (Double) value;
            } else if (value instanceof DateTime) {
                return (DateTime) record.get(field) <= (Datetime) value;
            }

            return false;
        }
    }

    public class GreaterThanOrEq extends Filter {
        public GreaterThanOrEq() {
        }

        public GreaterThanOrEq(String field, Object value) {
            super(field, value);
        }
        public override Boolean apply(SObject record) {
            if (value instanceof Integer) {
                return (Integer) record.get(field) >= (Integer) value;
            } else if (value instanceof Double) {
                return (Double) record.get(field) >= (Double) value;
            } else if (value instanceof DateTime) {
                return (DateTime) record.get(field) >= (Datetime) value;
            }

            return false;
        }
    }

    public class Contains extends Filter {
        public Contains() {
        }

        public Contains(String field, Object value) {
            super(field, value);
        }
        public override Boolean apply(SObject record) {
            return ((List<Object>) value).contains(record.get(field));
        }
    }

    public class IsSet extends Filter {
        public IsSet() {
        }

        public IsSet(String field, Object value) {
            super(field, value);
        }
        public override Boolean apply(SObject record) {
            return record.isSet(field) == Boolean.valueOf(value);
        }
    }

    public class IsNew extends Filter {
        public IsNew() {
        }

        public IsNew(String field, Map<Id, SObject> oldMap) {
            super(field, oldMap);
        }

        public override Boolean apply(SObject record) {
            SObject oldRecord = ((Map<Id, SObject>) this.value).get(record.Id);
            return record.get(field) != null && oldRecord.get(field) == null;
        }
    }

    public class IsUpdated extends Filter {
        public IsUpdated() {
        }

        public IsUpdated(String field, Map<Id, SObject> oldMap) {
            super(field, oldMap);
        }

        public override Boolean apply(SObject record) {
            SObject oldRecord = ((Map<Id, SObject>) this.value).get(record.Id);
            return record.get(field) != oldRecord.get(field) &&
                record.get(field) != null &&
                oldRecord.get(field) != null;
        }
    }

    public class IsDeleted extends Filter {
        public IsDeleted() {
        }

        public IsDeleted(String field, Map<Id, SObject> oldMap) {
            super(field, oldMap);
        }

        public override Boolean apply(SObject record) {
            SObject oldRecord = ((Map<Id, SObject>) this.value).get(record.Id);
            return record.get(field) == null && oldRecord.get(field) != null;
        }
    }

    public class IsChanged extends Filter {
        public IsChanged() {
        }

        public IsChanged(String field, Map<Id, SObject> oldMap) {
            super(field, oldMap);
        }

        public override Boolean apply(SObject record) {
            SObject oldRecord = ((Map<Id, SObject>) this.value).get(record.Id);
            return record.get(field) != oldRecord.get(field);
        }
    }
}
