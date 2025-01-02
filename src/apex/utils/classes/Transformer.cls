public class Transformer {
    public static List<Object> transform(
        List<ITransformable> source,
        Type target
    ) {
        try {
            List<Object> result = (List<Object>) Type.forName(
                    'List<' + target.getName() + '>'
                )
                .newInstance();
            for (ITransformable item : source) {
                result.add(item.transformTo(target));
            }
            return result;
        } catch (Exception e) {
            throw TransformExceptions.errorTransforming(e.getMessage());
        }
    }

    public static Object transform(ITransformable source, Type target) {
        try {
            return source.transformTo(target);
        } catch (Exception e) {
            throw TransformExceptions.errorTransforming(e.getMessage());
        }
    }
}
