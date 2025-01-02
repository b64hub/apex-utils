@IsTest
public class TransformerTest {
    public class TestTransformable implements ITransformable {
        public String name = 'Test';
        public String website = 'http://test.com';

        public Object transformTo(Type target) {
            if (target == Account.class) {
                return this.transformToAccount();
            }

            throw new TransformException('Unsupported target type');
        }

        public Account transformToAccount() {
            Account acc = new Account();
            acc.Name = this.name;
            acc.Website = this.website;
            return acc;
        }
    }

    @IsTest
    static void testTransformSimple() {
        TestTransformable source = new TestTransformable();

        Account result = (Account) Transformer.transform(source, Account.class);

        Assert.areEqual('Test', result.Name);
        Assert.areEqual('http://test.com', result.Website);
    }

    @IsTest
    static void testTransformList() {
        List<TestTransformable> source = new List<TestTransformable>{
            new TestTransformable(),
            new TestTransformable()
        };

        List<Account> result = (List<Account>) Transformer.transform(
            source,
            Account.class
        );

        Assert.areEqual(2, result.size());
        Assert.areEqual('Test', result[0].Name);
        Assert.areEqual('http://test.com', result[0].Website);
    }

    @IsTest
    static void testPerformance() {
        List<TransformerTest.TestTransformable> source = new List<TransformerTest.TestTransformable>();
        for (Integer i = 0; i < 1000; i++) {
            source.add(new TransformerTest.TestTransformable());
        }

        DateTime tic = System.now();
        List<Account> result = (List<Account>) Transformer.transform(
            source,
            Account.class
        );
        DateTime toc = System.now();

        System.debug(
            'Elapsed time: ' + (toc.getTime() - tic.getTime()) + ' ms'
        ); // 454 ms

        DateTime tic2 = System.now();
        List<Account> result2 = new List<Account>();
        for (TransformerTest.TestTransformable item : source) {
            result2.add(item.transformToAccount());
        }
        DateTime toc2 = System.now();

        System.debug(
            'Elapsed time: ' + (toc2.getTime() - tic2.getTime()) + ' ms'
        ); // 161 ms

        Assert.areEqual(1000, result.size());
    }
}
