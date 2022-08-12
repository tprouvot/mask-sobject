@isTest
private class MaskSObjectSandboxPostCopyTest {

	@isTest
	static void postCopyTest(){
		MaskSObjectBatchTest.createTestData();

		Test.startTest();
		Test.testSandboxPostCopyScript(new MaskSObjectSandboxPostCopy(), UserInfo.getOrganizationId(),
			UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
		Test.stopTest();

		Account acc = [SELECT Id, Name, Phone FROM Account LIMIT 1];
		System.assertNotEquals(MaskSObjectBatchTest.NAME, acc.Name, 'The account name should be masked');
	}
}
