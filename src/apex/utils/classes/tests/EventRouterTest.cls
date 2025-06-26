/**
 * Test class for EventRouter
 *
 * Since we don't have standard event objects in the utility package,
 * we use Account and Contact objects for testing the routing functionality
 */
@IsTest
public class EventRouterTest {
    /**
     * Test segmentation functionality
     */
    @IsTest
    static void testSegmentation() {
        // Create test data
        List<SObject> testEvents = createMixedEvents(10, 15);

        // Create router with test segmentation
        EventRouter router = new EventRouter(new TestSegmentation());

        // Test segmentation
        Map<String, List<SObject>> segmentedEvents = router.segment(testEvents);

        // Verify segmentation results
        Assert.areEqual(
            2,
            segmentedEvents.size(),
            'Should have two event types'
        );
        Assert.isTrue(
            segmentedEvents.containsKey('Account'),
            'Should have Account segment'
        );
        Assert.isTrue(
            segmentedEvents.containsKey('Contact'),
            'Should have Contact segment'
        );
        Assert.areEqual(
            10,
            segmentedEvents.get('Account').size(),
            'Should have 10 Account events'
        );
        Assert.areEqual(
            15,
            segmentedEvents.get('Contact').size(),
            'Should have 15 Contact events'
        );
    }

    /**
     * Test deduplication functionality
     */
    @IsTest
    static void testDeduplication() {
        TestFactory accountFactory = new TestFactory('Account')
            .createRecords(5)
            .addMockIds()
            .setField('Name', 'Test Account');

        List<Account> accounts = (List<Account>) accountFactory.getRecords();

        List<Account> duplicateAccounts = (List<Account>) accountFactory.copy()
            .setField('Name', 'Duplicate Account')
            .getRecords();

        List<SObject> mixedEvents = new List<SObject>();
        mixedEvents.addAll(accounts);
        mixedEvents.addAll(duplicateAccounts);

        // Create router
        EventRouter router = new EventRouter(new TestSegmentation());

        // Set deduplicator
        router.setDeduplicator(new TestDeduplicator());

        // Test deduplication
        List<SObject> dedupedEvents = router.deduplicate(mixedEvents);

        // Verify deduplication results
        Assert.areEqual(
            5,
            dedupedEvents.size(),
            'Should have 5 deduplicated events'
        );
    }

    /**
     * Test handler invocation
     */
    @IsTest
    static void testHandlerInvocation() {
        // Create test data
        List<SObject> testEvents = createMixedEvents(10, 15);

        // Create test handlers
        TestHandler accountHandler = new TestHandler();
        TestHandler contactHandler = new TestHandler();

        // Create router
        EventRouter router = new EventRouter(new TestSegmentation());

        // Add handlers
        router.addHandler('Account', accountHandler);
        router.addHandler('Contact', contactHandler);

        // Test routing
        Map<String, List<SObject>> segmentedEvents = router.segment(testEvents);
        router.route(segmentedEvents);

        // Verify handler invocation
        Assert.areEqual(
            1,
            accountHandler.handledCount,
            'Account handler should be called once'
        );
        Assert.areEqual(
            10,
            accountHandler.processedEvents,
            'Account handler should process 10 events'
        );
        Assert.areEqual(
            1,
            contactHandler.handledCount,
            'Contact handler should be called once'
        );
        Assert.areEqual(
            15,
            contactHandler.processedEvents,
            'Contact handler should process 15 events'
        );
    }

    /**
     * Test the full process flow
     */
    @IsTest
    static void testFullProcess() {
        // Create test data with duplicates
        TestFactory accountFactory = new TestFactory('Account')
            .createRecords(10)
            .addMockIds()
            .setField(
                'Name',
                new TestFactory.StringTemplate('Test Account {{i}}')
            );

        TestFactory contactFactory = new TestFactory('Contact')
            .createRecords(15)
            .addMockIds()
            .setField(
                'LastName',
                new TestFactory.StringTemplate('Test Contact {{i}}')
            );

        List<Account> accounts = (List<Account>) accountFactory.getRecords();
        List<Contact> contacts = (List<Contact>) contactFactory.getRecords();

        // Add duplicates (with same IDs)
        List<Account> dupAccounts = (List<Account>) accountFactory.copy()
            .getRecords();
        List<Contact> dupContacts = (List<Contact>) contactFactory.copy()
            .getRecords();

        List<SObject> allEvents = new List<SObject>();
        allEvents.addAll(accounts);
        allEvents.addAll(dupAccounts);
        allEvents.addAll(contacts);
        allEvents.addAll(dupContacts);

        // Create test handlers
        TestHandler accountHandler = new TestHandler();
        TestHandler contactHandler = new TestHandler();

        // Create router
        EventRouter router = new EventRouter(new TestSegmentation());

        // Set deduplicator
        router.setDeduplicator(new TestDeduplicator());

        // Add handlers
        router.addHandler('Account', accountHandler);
        router.addHandler('Contact', contactHandler);

        // Run the full process
        router.process(allEvents);

        // Verify handler invocation (after deduplication)
        Assert.areEqual(
            1,
            accountHandler.handledCount,
            'Account handler should be called once'
        );
        Assert.areEqual(
            10,
            accountHandler.processedEvents,
            'Account handler should process 10 events after deduplication'
        );
        Assert.areEqual(
            1,
            contactHandler.handledCount,
            'Contact handler should be called once'
        );
        Assert.areEqual(
            15,
            contactHandler.processedEvents,
            'Contact handler should process 15 events after deduplication'
        );
    }

    /**
     * Test empty event list
     */
    @IsTest
    static void testEmptyEvents() {
        // Create router with empty events
        EventRouter router = new EventRouter(new TestSegmentation());

        // Add handler
        router.addHandler('Account', new TestHandler());

        // Run process with empty list
        router.process(new List<SObject>());

        // No exceptions should be thrown
        Assert.areEqual(
            true,
            true,
            'Process should complete without exceptions'
        );
    }

    /**
     * Test missing handler
     */
    @IsTest
    static void testMissingHandler() {
        // Create test data
        List<SObject> testEvents = createMixedEvents(5, 5);

        // Create router
        EventRouter router = new EventRouter(new TestSegmentation());

        // Add handler only for Account
        TestHandler accountHandler = new TestHandler();
        router.addHandler('Account', accountHandler);

        // Set deduplicator
        router.setDeduplicator(new TestDeduplicator());

        // Run process
        router.process(testEvents);

        // Verify the Account handler was called, but no Contact handler
        Assert.areEqual(
            1,
            accountHandler.handledCount,
            'Account handler should be called once'
        );
        Assert.areEqual(
            5,
            accountHandler.processedEvents,
            'Account handler should process 5 events'
        );
    }

    /**
     * Test exception handling in handler
     */
    @IsTest
    static void testHandlerException() {
        // Create test data
        TestFactory accountFactory = new TestFactory('Account')
            .createRecords(5)
            .addMockIds()
            .setField(
                'Name',
                new TestFactory.StringTemplate('Test Account {{i}}')
            );

        List<SObject> testEvents = accountFactory.getRecords();

        // Create router
        EventRouter router = new EventRouter(new TestSegmentation());

        // Add handler that throws exception
        router.addHandler('Account', new ExceptionHandler());

        // Set deduplicator
        router.setDeduplicator(new TestDeduplicator());

        // Run process - should not throw exception to caller
        router.process(testEvents);

        // If we reach here, no exception was propagated
        Assert.isTrue(true, 'Process should handle exceptions gracefully');
    }

    /**
     * Test routing table setter
     */
    @IsTest
    static void testRoutingTableSetter() {
        // Create test data
        List<SObject> testEvents = createMixedEvents(5, 5);

        // Create router
        EventRouter router = new EventRouter(new TestSegmentation());

        // Create handlers
        TestHandler accountHandler = new TestHandler();
        TestHandler contactHandler = new TestHandler();

        // Create routing table
        Map<String, IEventHandler> routingTable = new Map<String, IEventHandler>{
            'Account' => accountHandler,
            'Contact' => contactHandler
        };

        // Set routing table
        router.setRoutingTable(routingTable);

        // Set deduplicator
        router.setDeduplicator(new TestDeduplicator());

        // Run process
        router.process(testEvents);

        // Verify handlers were called
        Assert.areEqual(
            1,
            accountHandler.handledCount,
            'Account handler should be called once'
        );
        Assert.areEqual(
            5,
            accountHandler.processedEvents,
            'Account handler should process 5 events'
        );
        Assert.areEqual(
            1,
            contactHandler.handledCount,
            'Contact handler should be called once'
        );
        Assert.areEqual(
            5,
            contactHandler.processedEvents,
            'Contact handler should process 5 events'
        );
    }

    // ==================== Helper methods and classes ====================

    /**
     * Create a mix of Account and Contact records
     */
    private static List<SObject> createMixedEvents(
        Integer numAccounts,
        Integer numContacts
    ) {
        List<SObject> results = new List<SObject>();

        // Create accounts with TestFactory
        TestFactory accountFactory = new TestFactory('Account')
            .createRecords(numAccounts)
            .addMockIds()
            .setField(
                'Name',
                new TestFactory.StringTemplate('Test Account {{i}}')
            );

        // Create contacts with TestFactory
        TestFactory contactFactory = new TestFactory('Contact')
            .createRecords(numContacts)
            .addMockIds()
            .setField(
                'LastName',
                new TestFactory.StringTemplate('Test Contact {{i}}')
            );

        // Add accounts and contacts to results
        results.addAll(accountFactory.getRecords());
        results.addAll(contactFactory.getRecords());

        return results;
    }

    /**
     * Test segmentation implementation
     */
    public class TestSegmentation implements EventRouter.ISegmentation {
        public String getRoutingKey(SObject event) {
            return event.getSObjectType().getDescribe().getName();
        }
    }

    /**
     * Test deduplicator implementation
     */
    public class TestDeduplicator implements EventRouter.IDeduplicator {
        public List<SObject> deduplicate(List<SObject> events) {
            Map<Id, SObject> uniqueEvents = new Map<Id, SObject>();

            for (SObject event : events) {
                uniqueEvents.put((Id) event.get('Id'), event);
            }

            return uniqueEvents.values();
        }
    }

    /**
     * Test event handler implementation
     */
    public class TestHandler implements IEventHandler {
        public Integer handledCount = 0;
        public Integer processedEvents = 0;

        public void handle(List<SObject> events) {
            handledCount++;
            processedEvents += events.size();
        }
    }

    /**
     * Exception throwing handler for testing error handling
     */
    public class ExceptionHandler implements IEventHandler {
        public void handle(List<SObject> events) {
            throw new CustomException('Test exception');
        }
    }

    public class CustomException extends Exception {
    }
}
