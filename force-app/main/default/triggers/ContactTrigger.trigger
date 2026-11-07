/** One trigger per object: all Patient (Contact) logic lives in ContactTriggerHandler. */
trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    new ContactTriggerHandler().run();
}
