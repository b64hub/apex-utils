public class EventRouter {
    private ISegmentation segmentation;
    private IDeduplicator deduplicator;
    private Map<String, IEventHandler> routingTable = new Map<String, IEventHandler>{};

    /**
     * Constructor for EventRouter
     *
     * @param events The list of events to route
     * @param segmentation The segmentation strategy
     * @param deduplicator The deduplication strategy
     */
    public EventRouter(ISegmentation segmentation) {
        this.segmentation = segmentation;
    }

    /**
     * Sets the routing table to use for routing events
     *
     * @param routingTable Map of event type to event handler
     */
    public void setRoutingTable(Map<String, IEventHandler> routingTable) {
        this.routingTable = routingTable;
    }

    /**
     * Add a handler for a specific event type
     *
     * @param eventType The event type
     * @param handler The event handler
     */
    public void addHandler(String eventType, IEventHandler handler) {
        this.routingTable.put(eventType, handler);
    }

    public void setDeduplicator(IDeduplicator deduplicator) {
        this.deduplicator = deduplicator;
    }

    /**
     * Interface for segmenting events into groups
     */
    public interface ISegmentation {
        String getRoutingKey(SObject event);
    }

    /**
     * Interface for deduplicating events
     */
    public interface IDeduplicator {
        List<SObject> deduplicate(List<SObject> events);
    }

    /**
     * Segments events based on the segmentation strategy
     *
     * @return Map of event types to lists of events
     */
    public Map<String, List<SObject>> segment(List<SObject> events) {
        Map<String, List<SObject>> segmentedEvents = new Map<String, List<SObject>>();

        for (SObject event : events) {
            String segmentKey = this.segmentation.getRoutingKey(event);

            if (String.isBlank(segmentKey)) {
                continue;
            }

            if (!segmentedEvents.containsKey(segmentKey)) {
                segmentedEvents.put(segmentKey, new List<SObject>());
            }

            segmentedEvents.get(segmentKey).add(event);
        }

        return segmentedEvents;
    }

    public class DeduplicationException extends Exception {
    }

    public List<SObject> deduplicate(List<SObject> events) {
        if (events == null || events.isEmpty()) {
            throw new DeduplicationException('No events to deduplicate');
        }

        if (events.size() == 1 || this.deduplicator == null) {
            return events;
        }

        return deduplicator.deduplicate(events);
    }

    public void route(Map<String, List<SObject>> segmentedEvents) {
        for (String eventType : segmentedEvents.keySet()) {
            List<SObject> segmentEvents = segmentedEvents.get(eventType);

            IEventHandler handler = this.routingTable.get(eventType);
            if (handler == null) {
                continue;
            }

            try {
                handler.handle(segmentEvents);
            } catch (Exception e) {
                Logger.error(
                    'Error executing handler for event type ' +
                        eventType +
                        ': ' +
                        e.getMessage()
                );
            }
        }
    }

    public class RoutingException extends Exception {
    }

    /**
     * Main method that processes all events through deduplication, segmentation, and routing
     */
    public void process(List<SObject> events) {
        if (routingTable.isEmpty()) {
            throw new RoutingException('No handlers configured');
        }

        if (events.isEmpty()) {
            return;
        }

        List<SObject> dedupedEvents = this.deduplicate(events);
        Map<String, List<SObject>> segmentedEvents = this.segment(
            dedupedEvents
        );
        this.route(segmentedEvents);
    }
}
