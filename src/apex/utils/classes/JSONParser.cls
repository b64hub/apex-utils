public class JSONParser implements IParser {
    IMapper mapper;

    private JSONParser() {
    }

    public static JSONParser newParser(IMapper mapper) {
        JSONParser parser = new JSONParser();
        parser.mapper = mapper;
        return parser;
    }

    public Object parse(String data) {
        Map<String, Object> source = (Map<String, Object>) JSON.deserializeUntyped(
            data
        );
        return this.mapper.mapToTarget(source);
    }

    public class MapperException extends Exception {
    }

    public interface IMapper {
        SObject mapToTarget(Map<String, Object> source);
    }

    public virtual class SObjectMapper implements IMapper {
        public SObject target;
        public Map<String, Object> source;
        public Map<String, String> mapping;

        private Pattern indexPattern = Pattern.compile('\\[(\\d+)\\]');
        private Boolean skipNulls = true;

        public SObjectMapper(SObjectType target) {
            this.target = target.newSObject();
            this.source = source;
            this.mapping = mapping;
        }

        public void configure(Map<String, String> mapping) {
            this.mapping = mapping;
        }

        public SObject mapToTarget(Map<String, Object> source) {
            for (String path : mapping.keySet()) {
                List<String> pathList = path.split('\\.');

                if (pathList.size() == 0) {
                    pathList.add(path);
                }

                Object value = this.traverse(pathList, source);

                target.put(mapping.get(path), value);
            }
            return target;
        }

        private Object traverse(List<String> path, Map<String, Object> source) {
            if (path.size() == 1) {
                return source.get(path[0]);
            }

            String key = path.remove(0);
            Matcher match = this.indexPattern.matcher(key);

            if (match.find()) {
                Integer index = Integer.valueOf(match.group(1));
                source = (Map<String, Object>) ((List<Object>) source.get(
                    key.replace('[' + index + ']', '')
                ))[index];
            } else {
                source = (Map<String, Object>) source.get(key);
            }

            return this.traverse(path, source);
        }
    }
}
