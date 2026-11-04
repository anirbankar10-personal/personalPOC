public with sharing class ContactTriggerHandler {
    /**
     * Fires after a new Contact is inserted.
     * If the related Account has Source = 'Website' and the Contact's Source is blank,
     * sets the Contact's Source to 'Website'.
     */
    public static void handleAfterInsert(List<Contact> newContacts) {
        // Only process contacts that are attached to an account
        Set<Id> websiteAccountIds = new Set<Id>();
        for (Contact c : newContacts) {
            if (c.AccountId != null) {
                websiteAccountIds.add(c.AccountId);
            }
        }

        if (websiteAccountIds.isEmpty()) {
            return;
        }

        // Fetch the Account Source for each relevant account in a single SOQL call
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Source FROM Account WHERE Id IN :websiteAccountIds]
        );

        // Collect contacts that need their Source updated
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : newContacts) {
            Account acc = accountMap.get(c.AccountId);
            if (acc != null && acc.Source == 'Website' && (c.Source == null || c.Source == '')) {
                c.Source = 'Website';
                contactsToUpdate.add(c);
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}
