/**
 * Runs care-schedule generation in the background.
 *
 * Registering a newborn creates up to 12 vaccine doses; a household registered in bulk can mean
 * thousands. Doing that after the save, asynchronously, keeps the health worker's save fast and
 * gives the work its own, larger governor limits. The job appears in Setup > Apex Jobs.
 */
public with sharing class CareScheduleQueueable implements Queueable {

    private final Set<Id> patientIds;

    public CareScheduleQueueable(Set<Id> patientIds) {
        this.patientIds = new Set<Id>(patientIds);
    }

    public void execute(QueueableContext context) {
        try {
            CareScheduleService.generate(patientIds);
        } catch (Exception e) {
            ErrorLogger.log('CareScheduleQueueable', e, null);
        }
    }

    /**
     * Queues generation for these patients. If the code is already running in the background
     * (batch, queueable, future) or this transaction has used its queueable allowance, it runs
     * immediately instead. It never fails the patient's own save.
     */
    public static void schedule(Set<Id> patientIds) {
        if (patientIds == null || patientIds.isEmpty()) {
            return;
        }
        try {
            Boolean runNow = System.isBatch() || System.isQueueable() || System.isFuture()
                || Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs();
            if (runNow) {
                CareScheduleService.generate(patientIds);
            } else {
                System.enqueueJob(new CareScheduleQueueable(patientIds));
            }
        } catch (Exception e) {
            ErrorLogger.log('CareScheduleQueueable.schedule', e, null);
        }
    }
}
