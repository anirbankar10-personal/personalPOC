@isTest
private class ExistingContactsBackfillTest {
    @isTest
    static void testBatch_FillsBlankSourceOnWebsiteContacts() {
        // Given: a Website Account and two Contacts with blank Source
        Account acc = new Account(Name = 'Test Account', Source = 'Website');
        insert acc;

        Contact cont1 = new Contact(LastName = 'Contact1', AccountId = acc.Id, Source = null);
        Contact cont2 = new Contact(LastName = 'Contact2', AccountId = acc.Id, Source = null);
        insert new List<Contact>{ cont1, cont2 };

        // When: the backfill batch is executed
        Test.startTest();
        ExistingContactsBackfill bg = new ExistingContactsBackfill();
        Database.executeBatch(bg, 200);
        Test.stopTest();

        // Then: all matching Contacts have their Source set to 'Website'
        List<Contact> contacts = [SELECT Source FROM Contact WHERE AccountId = :acc.Id];
        System.assertEquals(2, contacts.size());
        for (Contact c : contacts) {
            System.assertEquals('Website', c.Source);
        }
    }

    @isTest
    static void testBatch_ExcludesNonWebsiteAccounts() {
        // Given: a Website Account and a Partner Referral Account with Contacts
        Account websiteAcc = new Account(Name = 'Website Account', Source = 'Website');
        Account partnerAcc = new Account(Name = 'Partner Account', Source = 'Partner Referral');
        insert new List<Account>{ websiteAcc, partnerAcc };

        Contact websiteContact = new Contact(LastName = 'Website', AccountId = websiteAcc.Id, Source = null);
        Contact partnerContact = new Contact(LastName = 'Partner', AccountId = partnerAcc.Id, Source = null);
        insert new List<Contact>{ websiteContact, partnerContact };

        // When: the backfill batch is executed
        Test.startTest();
        ExistingContactsBackfill bg = new ExistingContactsBackfill();
        Database.executeBatch(bg, 200);
        Test.stopTest();

        // Then: only the Website Account contacts are updated
        List<Contact> websiteContacts = [SELECT Source FROM Contact WHERE AccountId = :websiteAcc.Id];
        List<Contact> partnerContacts = [SELECT Source FROM Contact WHERE AccountId = :partnerAcc.Id];

        System.assertEquals(1, websiteContacts.size());
        System.assertEquals('Website', websiteContacts[0].Source);
        System.assertNull(partnerContacts[0].Source);
    }
}
