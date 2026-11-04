public with sharing class AccountTriggerHandler {
    /**
     * Fires after an Account is updated.
     * If an Account's Source changed to 'Website', updates all Contact records on that
     * Account whose Source is blank (NULL) to 'Website'.
     * Does NOT cascade the opposite direction (i.e. it never overwrites an existing
     * Contact Source value).
     */
    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        // Identify accounts whose Source changed to 'Website'
        Set<Id> websiteAccountIds = new Set<Id>();
        for (Account acc : newAccounts) {
            Account original = oldMap.get(acc.Id);
            if (original != null && original.Source != 'Website' && acc.Source == 'Website') {
                websiteAccountIds.add(acc.Id);
            }
        }

        if (websiteAccountIds.isEmpty()) {
            return;
        }

        // Find Contacts on those accounts with a blank Source.
        // IS NULL is the correct SOQL null check for picklist fields.
        List<Contact> contactsToUpdate = [
            SELECT Id
            FROM Contact
            WHERE AccountId IN :websiteAccountIds
            AND (Source IS NULL OR Source = '')
        ];

        for (Contact c : contactsToUpdate) {
            c.Source = 'Website';
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}
