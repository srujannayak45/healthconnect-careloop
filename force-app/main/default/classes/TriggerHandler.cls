/**
 * Base class for every CareLoop trigger handler.
 *
 * Pattern: one trigger per object, and the trigger contains one line that calls run().
 * run() looks at which trigger event is executing and calls the matching method, which
 * each handler overrides only for the events it needs. Keeping logic out of triggers
 * makes it testable, keeps the order of operations explicit, and gives one switch
 * (bypass) to turn a handler off deliberately, for example during a data load.
 */
public virtual with sharing class TriggerHandler {

    private static final Set<String> BYPASSED_HANDLERS = new Set<String>();

    /** Turns a handler off for the rest of this transaction. */
    public static void bypass(String handlerName) {
        BYPASSED_HANDLERS.add(handlerName);
    }

    /** Turns a handler back on. */
    public static void clearBypass(String handlerName) {
        BYPASSED_HANDLERS.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return BYPASSED_HANDLERS.contains(handlerName);
    }

    /** Called by the trigger. Does nothing outside a trigger or when bypassed. */
    public void run() {
        if (!Trigger.isExecuting || isBypassed(getHandlerName())) {
            return;
        }
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                beforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                beforeUpdate(Trigger.new, Trigger.oldMap);
            }
            when AFTER_INSERT {
                afterInsert(Trigger.new);
            }
            when AFTER_UPDATE {
                afterUpdate(Trigger.new, Trigger.oldMap);
            }
            when else {
                return;
            }
        }
    }

    /** The concrete class name, e.g. "ContactTriggerHandler". */
    @TestVisible
    protected String getHandlerName() {
        return String.valueOf(this).substringBefore(':');
    }

    protected virtual void beforeInsert(List<SObject> newRecords) {
        return;
    }

    protected virtual void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        return;
    }

    protected virtual void afterInsert(List<SObject> newRecords) {
        return;
    }

    protected virtual void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        return;
    }
}
