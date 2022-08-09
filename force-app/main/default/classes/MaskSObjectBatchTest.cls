@isTest
private class MaskSObjectBatchTest {

	private static String NAME = 'Test Mask Data';
	private static String PHONE = '0606060606';
	private static String LASTNAME = 'Doe';
	private static String ASSISTANTNAME = 'Jane DOE';
	private static String EMAIL = 'jdoe@masksobject.com';

	@TestSetup
	static void makeData(){
		List<MaskSObject__c> sobjMask = new List<MaskSObject__c>{
			new MaskSObject__c(Sequence__c = 1, APIName__c = 'Account'),
			new MaskSObject__c(Sequence__c = 2, APIName__c = 'Contact', WhereClause__c = 'AssistantName != null')
		};
		insert sobjMask;

		List<MaskSObjectField__c> fieldMask = new List<MaskSObjectField__c>{
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(0).Id, APIName__c = 'Name', Action__c = MaskSObjectConstants.ACTION_OBFUSCATE),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(0).Id, APIName__c = 'Phone', Action__c = MaskSObjectConstants.ACTION_ERASE),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'LastName', Action__c = MaskSObjectConstants.ACTION_OBFUSCATE),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'AssistantName', Action__c = MaskSObjectConstants.ACTION_ERASE),
			new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'Email', Action__c = MaskSObjectConstants.ACTION_OBFUSCATE)
		};
		insert fieldMask;

		insert new Account(Name = NAME, Phone = PHONE);
		insert new Contact(FirstName = 'John', LastName = LASTNAME, AssistantName = ASSISTANTNAME, Email = EMAIL);
	}

	@isTest
	static void maskSobjectTest(){

		Test.startTest();
		Database.executeBatch(new MaskSObjectBatch());
		Test.stopTest();

		Account acc = [SELECT Id, Name, Phone FROM Account LIMIT 1];
		System.assertNotEquals(NAME, acc.Name, 'The account name should be masked');
		System.assertNotEquals(PHONE, acc.Phone, 'The account phone should be masked');

		Contact cont = [SELECT Id, LastName, AssistantName, Email FROM Contact LIMIT 1];
		System.assertNotEquals(LASTNAME, cont.LastName, 'The contact lastname should be masked');
		System.assertNotEquals(ASSISTANTNAME, cont.AssistantName, 'The contact AssistantName should be masked');
		System.assertNotEquals(EMAIL, cont.Email, 'The contact Email should be masked');
	}
}
