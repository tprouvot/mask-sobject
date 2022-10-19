
@isTest
private class MaskSObjectBatchSchedulableTest {

	@isTest
	static void maskSObjectScheduleableTest(){
		Datetime tomorrow = System.today().addDays(1);
		String cron = '0 0 0 ' + tomorrow.day() + ' ' + tomorrow.month() + ' ? ' + tomorrow.year();
		String jobId = System.schedule('TestSchedule', cron , new MaskSObjectBatchSchedulable());

		// Get the information from the CronTrigger API object
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

		// Verify the expressions are the same
		System.assertEquals(cron, ct.CronExpression, 'CronExpression should be equals');

		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered, 'Job should not run');
	}
}