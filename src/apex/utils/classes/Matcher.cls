public class Matcher {

    List<SObject> list1;
    String field1;

    public Matcher(List<SObject> records, String field) {
        this.list1 = records;
        this.field1 = field;
    }


    public class MatchResult {
        SObject record1;
        SObject record2;

        String field1;
        String field2;

        Object matchedValue;
    }


    public List<Result> match(List<SObject> list2, String field2) {
        
        Map<Object, SObject> arrangedRecords1 = arrange(list1, field1);
        Map<Object, SObject> arrangedRecords2 = arrange(list2, field2);

        List<Result> results = new List<Result>();
        for (Object key : arrangedRecords1.keySet()) {
            if (arrangedRecords2.containsKey(key)) {
                Result result = new Result();
                result.record1 = arrangedRecords1.get(key);
                result.record2 = arrangedRecords2.get(key);
                result.field1 = field1;
                result.field2 = field2;
                result.matchedValue = key;
                results.add(result);
            }
        }

        return results;
    }

    public class MathcerException extends Exception {}

    public static Map<Object, SObject> arrange(List<SObject> records, String field) {
        Map<Object, SObject> recordsByField = new Map<Object, SObject>();
        for (SObject record : records) {
            Object key = record.get(field);

            if (recordsByField.containsKey(record.get(key))) {
                throw new MatcherException('Duplicate value found in field ' + key);
            }

            recordsByField.put(key, record);
        }
        return recordsByField;
    }


}