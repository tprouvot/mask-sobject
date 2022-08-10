global with sharing class MaskSObjectSandboxPostCopy implements SandboxPostCopy {

	global void runApexClass(SandboxContext context) {
		List<MaskSObject__c> settings = MaskSObjectUtils.getMaskSObjectList(0);
		if(!settings.isEmpty()){
			Integer batchSize = settings.get(0).BatchSize__c != null ? settings.get(0).BatchSize__c : 200;
			Database.executeBatch(new MaskSObjectBatch(), batchSize);
		}
	}
}
