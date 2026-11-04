@isTest
private class AccountTriggerHandlerTest {
    @isTest
    static void testHandleAfterUpdate_SourceChangedToWebsite_CascadesToContacts() {
        // Given: an Account with a blank Source and two Contacts with blank Source
        Account acc = new Account(Name = 'Test Account', Source = '');
        insert acc;

        Contact cont1 = new Contact(LastName = 'Contact1', AccountId = acc.Id, Source = null);
        Contact cont2 = new Contact(LastName = 'Contact2', AccountId = acc.Id, Source = null);
        insert new List<Contact>{ cont1, cont2 };

        // When: the Account's Source is updated to 'Website'
        Test.startTest();
        acc.Source = 'Website';
        update acc;
        Test.stopTest();

        // Then: all Contacts on the Account have their Source set to 'Website'
        List<Contact> contacts = [SELECT Source FROM Contact WHERE AccountId = :acc.Id];
        System.assertEquals(2, contacts.size());
        for (Contact c : contacts) {
            System.assertEquals('Website', c.Source);
        }
    }

    @isTest
    static void testHandleAfterUpdate_NoChange_Skips() {
        // Given: an Account with Website Source and two Contacts with blank Source
        Account acc = new Account(Name = 'Test Account', Source = 'Website');
        insert acc;

        Contact cont1 = new Contact(LastName = 'Contact1', AccountId = acc.Id, Source = null);
        Contact cont2 = new Contact(LastName = 'Contact2', AccountId = acc.Id, Source = null);
        insert new List<Contact>{ cont1, cont2 };

        // When: the Account's Source is NOT changed
        Test.startTest();
        update acc;
        Test.stopTest();

        // Then: Contacts are unchanged
        List<Contact> contacts = [SELECT Source FROM Contact WHERE AccountId = :acc.Id];
        for (Contact c : contacts) {
            System.assertNull(c.Source);
        }
    }

    @isTest
    static void testHandleAfterUpdate_PreviousWasWebsite_NoDoubleCascade() {
        // Given: an Account already set to Website (so no transition to Website)
        Account acc = new Account(Name = 'Test Account', Source = 'Website');
        insert acc;

        Contact cont1 = new Contact(LastName = 'Contact1', AccountId = acc.Id, Source = null);
        insert cont1;

        // When: the Account's Source is changed away from Website and back to Website
        Test.startTest();
        acc.Source = 'Partner Referral';
        update acc;

        acc.Source = 'Website';
        update acc;
        Test.stopTest();

        // Then: the Contacts are updated (the second cascade fires)
        List<Contact> contacts = [SELECT Source FROM Contact WHERE AccountId = :acc.Id];
        System.assertEquals(1, contacts.size());
        System.assertEquals('Website', contacts[0].Source);
    }
}
