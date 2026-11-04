public with sharing class ExistingContactsBackfill implements Database.Batchable<SObject>, Database.Stateful {
    /**
     * One-time batch job to backfill historical Contacts whose Account Source is
     * 'Website' and whose Contact Source is blank, setting Contact Source = 'Website'.
     *
     * Run once via:
     *   ExistingContactsBackfill bg = new ExistingContactsBackfill();
     *   Database.executeBatch(bg, 200);
     *
     * Or from the Developer Console / Anonymous Apex:
     *   Database.executeBatch(new ExistingContactsBackfill(), 200);
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Contact
            WHERE AccountId IN (
                SELECT Id
                FROM Account
                WHERE Source = 'Website'
            )
            AND (Source IS NULL OR Source = '')
        ]);
    }

    public void execute(Database.BatchableContext context, List<Contact> scope) {
        for (Contact c : scope) {
            c.Source = 'Website';
        }
        update scope;
    }

    public void finish(Database.BatchableContext context) {
        // Optional: fire a Cloud Job / send a notification that the backfill completed.
    }
}
