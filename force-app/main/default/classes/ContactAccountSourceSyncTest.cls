/**
 * ContactAccountSourceSyncTest
 *
 * Unit tests for ContactAccountSourceSync class
 */
@isTest
private class ContactAccountSourceSyncTest {
    
    @isTest
    static void testContactCreatedWithWebsiteAccount_SourcePopulates() {
        // Arrange
        Account testAccount = new Account(
            Name = 'Test Website Account',
            Source = 'Website'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Source = null // Should be populated
        );
        
        // Act
        Test.startTest();
        insert testContact;
        Test.stopTest();
        
        // Assert
        testContact = [SELECT Source FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Website', testContact.Source, 'Contact Source should be populated with Website');
    }
    
    @isTest
    static void testContactCreatedWithWebsiteAccount_ExistingSourcePreserved() {
        // Arrange
        Account testAccount = new Account(
            Name = 'Test Website Account',
            Source = 'Website'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Source = 'Trade Show' // Should NOT be overwritten
        );
        
        // Act
        Test.startTest();
        insert testContact;
        Test.stopTest();
        
        // Assert
        testContact = [SELECT Source FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Trade Show', testContact.Source, 'Contact Source should NOT be overwritten');
    }
    
    @isTest
    static void testContactCreatedWithNullAccountSource_NoChange() {
        // Arrange
        Account testAccount = new Account(
            Name = 'Test Non-Website Account',
            Source = 'Other'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Source = null // Should remain null
        );
        
        // Act
        Test.startTest();
        insert testContact;
        Test.stopTest();
        
        // Assert
        testContact = [SELECT Source FROM Contact WHERE Id = :testContact.Id];
        System.assertNull(testContact.Source, 'Contact Source should remain null for non-Website account');
    }
    
    @isTest
    static void testContactUpdatedToWebsiteAccount_SourcePopulated() {
        // Arrange
        Account testAccount = new Account(
            Name = 'Test Website Account',
            Source = 'Website'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Source = null
        );
        testContact = insert testContact;
        
        // Change account source to Website (should trigger sync)
        testAccount.Source = 'Website';
        Test.startTest();
        update testAccount;
        Test.stopTest();
        
        // Re-fetch contact
        testContact = [SELECT Source FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Website', testContact.Source, 'Contact Source should be populated after account update');
    }
    
    @isTest
    static void testBackfillClass_UpdatesBlankSources() {
        // Arrange
        Account testAccount = new Account(
            Name = 'Test Backfill Account',
            Source = 'Website'
        );
        insert testAccount;
        
        // Create 5 contacts with blank source
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Test' + i,
                LastName = 'Contact',
                AccountId = testAccount.Id,
                Source = null
            ));
        }
        insert contacts;
        
        // Act
        Test.startTest();
        ContactSourceBackfill.BackfillResult result = ContactSourceBackfill.executeBackfill(new Set<Id>());
        Test.stopTest();
        
        // Assert
        System.assertEquals(5, result.recordsUpdated, 'Should have updated 5 contacts');
        System.assertEquals(5, result.recordsAffected, 'Should have found 5 affected contacts');
        System.assertEquals(1, result.batchesProcessed, 'Should have processed 1 batch');
        
        // Verify all contacts now have source populated
        List<Contact> updatedContacts = [SELECT Source FROM Contact WHERE Id IN :contacts];
        for (Contact c : updatedContacts) {
            System.assertEquals('Website', c.Source, 'All contacts should have source set to Website');
        }
    }
    
    @isTest
    static void testBackfillClass_CountAffectedRecords() {
        // Arrange
        Account testAccount = new Account(
            Name = 'Test Backfill Count Account',
            Source = 'Website'
        );
        insert testAccount;
        
        // Create 10 contacts with blank source
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            contacts.add(new Contact(
                FirstName = 'Test' + i,
                LastName = 'Contact',
                AccountId = testAccount.Id,
                Source = null
            ));
        }
        insert contacts;
        
        // Act
        Integer count = ContactSourceBackfill.countAffectedRecords(new Set<Id>());
        
        // Assert
        System.assertEquals(10, count, 'Should count 10 affected contacts');
    }
}
