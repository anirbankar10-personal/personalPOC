@isTest
private class ContactTriggerHandlerTest {
    @isTest
    static void testHandleAfterInsert_WebsiteAccount_BlankSourceIsSet() {
        // Given: a Website Account and three Contacts (blank, empty, existing)
        Account acc = new Account(Name = 'Test Website Account', Source = 'Website');
        insert acc;

        Contact blankContact = new Contact(LastName = 'Blank', AccountId = acc.Id, Source = null);
        Contact emptyContact = new Contact(LastName = 'Empty', AccountId = acc.Id, Source = '');
        Contact existingContact = new Contact(LastName = 'Existing', AccountId = acc.Id, Source = 'Trade Show');

        // When: the Contacts are inserted
        ContactTriggerHandler.handleAfterInsert(new List<Contact>{ blankContact, emptyContact, existingContact });

        // Then: only the blank/empty contacts are updated
        Contact c1 = [SELECT Source FROM Contact WHERE Id = :blankContact.Id];
        Contact c2 = [SELECT Source FROM Contact WHERE Id = :emptyContact.Id];
        Contact c3 = [SELECT Source FROM Contact WHERE Id = :existingContact.Id];

        System.assert(NotNull(c1.Source));
        System.assertEquals('Website', c1.Source);
        System.assert(NotNull(c2.Source));
        System.assertEquals('Website', c2.Source);
        System.assertEquals('Trade Show', c3.Source, 'Existing value must not be overwritten');
    }

    @isTest
    static void testHandleAfterInsert_NoAccount_Skips() {
        // Given: a Contact with no Account
        Contact c = new Contact(LastName = 'NoAccount', AccountId = null);

        // When
        ContactTriggerHandler.handleAfterInsert(new List<Contact>{ c });

        // Then: nothing changes
        Contact dbContact = [SELECT Source FROM Contact WHERE Id = :c.Id];
        System.assertNull(dbContact.Source);
    }

    @isTest
    static void testHandleAfterInsert_OtherAccount_Skips() {
        // Given: a Website Account and a Contact under a different Account
        Account websiteAcc = new Account(Name = 'Website Account', Source = 'Website');
        Account otherAcc = new Account(Name = 'Other Account', Source = 'Other');
        insert new List<Account>{ websiteAcc, otherAcc };

        Contact websiteContact = new Contact(LastName = 'Website', AccountId = websiteAcc.Id, Source = null);
        Contact otherContact = new Contact(LastName = 'Other', AccountId = otherAcc.Id, Source = null);

        ContactTriggerHandler.handleAfterInsert(new List<Contact>{ websiteContact, otherContact });

        Contact wc = [SELECT Source FROM Contact WHERE Id = :websiteContact.Id];
        Contact oc = [SELECT Source FROM Contact WHERE Id = :otherContact.Id];

        System.assertEquals('Website', wc.Source);
        System.assertNull(oc.Source);
    }

    private static Boolean NotNull(Object v) {
        return v != null;
    }
}
