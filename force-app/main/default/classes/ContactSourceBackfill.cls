/**
 * ContactSourceBackfill
 *
 * One-time data backfill utility to populate Contact Source with 'Website' for
 * existing Contacts where:
 * - The parent Account Source is 'Website'
 * - The Contact Source is currently blank
 *
 * Usage: Execute as anonymous Apex or via a scheduled job
 */
public with sharing class ContactSourceBackfill {
    
    /**
     * Executes the full backfill operation
     * @param scope 'all' for all accounts, or specific account IDs
     * @return Summary of backfill operation
     */
    public static BackfillResult executeBackfill(Set<Id> scopeAccountIds) {
        List<Id> accountIdsToProcess = scopeAccountIds;
        
        // If scope is empty, process all Website accounts
        if (accountIdsToProcess == null || accountIdsToProcess.isEmpty()) {
            List<Account> allWebsiteAccounts = [
                SELECT Id 
                FROM Account 
                WHERE Source = 'Website'
            ];
            accountIdsToProcess = new List<Id>();
            for (Account acc : allWebsiteAccounts) {
                accountIdsToProcess.add(acc.Id);
            }
        }
        
        // Find all contacts with blank source under Website accounts
        List<Contact> contactsToUpdate = [
            SELECT Id, AccountId 
            FROM Contact 
            WHERE AccountId IN :accountIdsToProcess 
            AND (Source = null OR Source = '')
        ];
        
        // Update contacts in batches
        int batchSize = 200;
        int totalUpdated = 0;
        int processedBatches = 0;
        
        for (int i = 0; i < contactsToUpdate.size(); i += batchSize) {
            int endIndex = Math.min(i + batchSize, contactsToUpdate.size());
            List<Contact> batch = contactsToUpdate.subList(i, endIndex);
            
            for (Contact contact : batch) {
                contact.Source = 'Website';
            }
            
            update batch;
            totalUpdated += batch.size();
            processedBatches++;
        }
        
        return new BackfillResult(
            totalUpdated, 
            contactsToUpdate.size(), 
            processedBatches
        );
    }
    
    /**
     * Counts affected records for reporting
     * @param scopeAccountIds Optional set of account IDs to scope the count
     * @return Count of affected contacts
     */
    public static Integer countAffectedRecords(Set<Id> scopeAccountIds) {
        List<Id> accountIdsToProcess = scopeAccountIds;
        
        if (accountIdsToProcess == null || accountIdsToProcess.isEmpty()) {
            List<Account> allWebsiteAccounts = [
                SELECT Id 
                FROM Account 
                WHERE Source = 'Website'
            ];
            accountIdsToProcess = new List<Id>();
            for (Account acc : allWebsiteAccounts) {
                accountIdsToProcess.add(acc.Id);
            }
        }
        
        return [
            SELECT COUNT() 
            FROM Contact 
            WHERE AccountId IN :accountIdsToProcess 
            AND (Source = null OR Source = '')
        ];
    }
    
    /**
     * Result object for backfill operation
     */
    public class BackfillResult {
        public Integer recordsUpdated { get; private set; }
        public Integer recordsAffected { get; private set; }
        public Integer batchesProcessed { get; private set; }
        
        public BackfillResult(Integer recordsUpdated, Integer recordsAffected, Integer batchesProcessed) {
            this.recordsUpdated = recordsUpdated;
            this.recordsAffected = recordsAffected;
            this.batchesProcessed = batchesProcessed;
        }
    }
}
