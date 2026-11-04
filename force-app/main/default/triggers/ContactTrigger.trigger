/**
 * ContactTrigger
 *
 * Synchronizes Account Source to Contact Source on Contact creation or update.
 * When a Contact is created or updated and its parent Account has Source = 'Website',
 * this trigger populates the Contact Source with 'Website' if it is blank.
 */
trigger ContactTrigger on Contact (before insert, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        // Early validation on before insert
        for (Contact contact : Trigger.new) {
            // Add any future validation logic here
        }
    }
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        // Build map of contact to account source
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Set<Id> contactIds = new Set<Id>();
        
        for (Contact contact : Trigger.new) {
            contactIds.add(contact.Id);
            if (contact.AccountId != null) {
                accountMap.put(contact.AccountId, contact.AccountId); // We'll fetch accounts below
            }
        }
        
        // Fetch accounts for the contacts
        for (Account acc : [
            SELECT Id, Source 
            FROM Account 
            WHERE Id IN :accountMap.keySet()
        ]) {
            accountMap.put(acc.Id, acc);
        }
        
        // Build map of contact -> account source
        Map<Id, Account> contactAccountMap = new Map<Id, Account>();
        for (Contact contact : Trigger.new) {
            if (contact.AccountId != null && accountMap.containsKey(contact.AccountId)) {
                contactAccountMap.put(contact.Id, accountMap.get(contact.AccountId));
            }
        }
        
        // Call sync logic
        ContactAccountSourceSync.handleContactTrigger(
            Trigger.new, 
            Trigger.old, 
            contactAccountMap, 
            accountMap, 
            Trigger.isInsert, 
            Trigger.isUpdate
        );
    }
}
