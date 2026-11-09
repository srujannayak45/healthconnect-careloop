/** Builds the day's Navigator plans for the given workers in the background. */
public with sharing class NavigatorPlanQueueable implements Queueable {

    private final Set<Id> workerIds;
    private final Date planDate;

    public NavigatorPlanQueueable(Set<Id> workerIds, Date planDate) {
        this.workerIds = new Set<Id>(workerIds);
        this.planDate = planDate;
    }

    public void execute(QueueableContext context) {
        for (Id workerId : workerIds) {
            try {
                // One worker per call: a problem with one plan never blocks the others.
                NavigatorService.generate(new Set<Id>{ workerId }, planDate);
            } catch (Exception e) {
                ErrorLogger.log('NavigatorPlanQueueable', e, workerId);
            }
        }
    }
}
