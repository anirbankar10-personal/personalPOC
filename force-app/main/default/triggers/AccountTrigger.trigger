trigger AccountTrigger on Account (after update) {
    AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}
