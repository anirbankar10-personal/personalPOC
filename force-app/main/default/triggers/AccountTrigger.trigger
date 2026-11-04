/**
 * AccountTrigger
 *
 * Handles Account Source updates and ensures affected Contacts have their Contact Source synced.
 * When an Account's Source is set to 'Website', this trigger synchronizes the Contact Source to 'Website'
 * for all Contacts on that Account where Contact Source is currently blank.
 */
trigger AccountTrigger on Account (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        // Early validation on before update to add validation rules if needed
        for (Account acc : Trigger.new) {
            // Add any future validation logic here
        }
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        // Build map of account contacts
        Map<Id, List<Contact>> accountContactsMap = new Map<Id, List<Contact>>();
        Set<Id> websiteAccountIds = new Set<Id>();
        
        for (Account acc : Trigger.new) {
            if (acc.Source == 'Website') {
                websiteAccountIds.add(acc.Id);
            }
        }
        
        if (!websiteAccountIds.isEmpty()) {
            // Query contacts for affected accounts - only those with blank source will be updated
            List<Contact> contacts = [
                SELECT Id, AccountId, Source 
                FROM Contact 
                WHERE AccountId IN :websiteAccountIds 
                AND (Source = null OR Source = '')
            ];
            
            // Group contacts by account
            for (Contact contact : contacts) {
                if (accountContactsMap.containsKey(contact.AccountId)) {
                    accountContactsMap.get(contact.AccountId).add(contact);
                } else {
                    accountContactsMap.put(contact.AccountId, new List<Contact>{contact});
                }
            }
            
            // Call sync logic
            ContactAccountSourceSync.handleAccountTrigger(
                Trigger.new, 
                Trigger.old, 
                new Map<Id, Account>(), 
                accountContactsMap, 
                false, 
                true
            );
        }
    }
}
