/**
 * ContactAccountSourceSync
 *
 * Synchronizes Account Source to Contact Source when:
 * - A Contact is created or updated
 * - The parent Account's Source is 'Website' and the Contact's Source is blank
 *
 * This ensures marketing attribution accuracy for web-form leads converted to contacts.
 */
public with sharing class ContactAccountSourceSync {
    
    /**
     * Entry point for Contact trigger
     */
    public static void handleContactTrigger(List<Contact> newContacts, List<Contact> oldContacts, Map<Id, Contact> contactTriggerMap, Map<Id, Account> accountMap, boolean isInsert, boolean isUpdate) {
        // Only sync when Account Source is 'Website'
        Set<Id> websiteAccountIds = new Set<Id>();
        for (Contact contact : newContacts) {
            if (contact.AccountId != null) {
                websiteAccountIds.add(contact.AccountId);
            }
        }
        
        // Get accounts that are 'Website' source
        List<Account> accounts = new List<Account>();
        if (!websiteAccountIds.isEmpty()) {
            accounts = [
                SELECT Id, Source 
                FROM Account 
                WHERE Id IN :websiteAccountIds 
                AND Source = 'Website'
            ];
        }
        
        // Build map of website accounts
        Map<Id, Account> websiteAccounts = new Map<Id, Account>();
        for (Account acc : accounts) {
            websiteAccounts.put(acc.Id, acc);
        }
        
        // Update contacts that belong to website accounts and have blank source
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact contact : newContacts) {
            if (contact.AccountId != null && websiteAccounts.containsKey(contact.AccountId)) {
                // Check if contact source is blank
                if (contact.Source == null || contact.Source == '') {
                    contact.Source = 'Website';
                    contactsToUpdate.add(contact);
                }
            }
        }
        
        // Upsert contacts in bulk for efficiency
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
    
    /**
     * Entry point for Account trigger (for backward compatibility and explicit Account updates)
     */
    public static void handleAccountTrigger(List<Account> newAccounts, List<Account> oldAccounts, Map<Id, Account> accountTriggerMap, Map<Id, List<Contact>> accountContactsMap, boolean isInsert, boolean isUpdate) {
        // Build map of account IDs to their contacts
        Map<Id, List<Contact>> accountToContacts = new Map<Id, List<Contact>>();
        if (accountContactsMap != null && !accountContactsMap.isEmpty()) {
            for (Id accountId : accountContactsMap.keySet()) {
                accountToContacts.put(accountId, accountContactsMap.get(accountId));
            }
        }
        
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Account account : newAccounts) {
            // Only process 'Website' accounts
            if (account.Source == 'Website') {
                // Get all contacts for this account that have blank source
                if (accountToContacts.containsKey(account.Id)) {
                    for (Contact contact : accountToContacts.get(account.Id)) {
                        if (contact.Source == null || contact.Source == '') {
                            contact.Source = 'Website';
                            contactsToUpdate.add(contact);
                        }
                    }
                }
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}
