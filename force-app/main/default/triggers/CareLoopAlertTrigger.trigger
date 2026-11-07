trigger CareLoopAlertTrigger on CareLoop_Alert__e (after insert) {
    CareLoopAlertSubscriber.handle(Trigger.new);
}
