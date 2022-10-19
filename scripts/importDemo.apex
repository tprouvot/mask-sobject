//Assign required pset
String psetName = 'MaskSObjectAdmin';
List<PermissionSet> psets = [SELECT Id FROM PermissionSet WHERE Name =:psetName];
if(!psets.isEmpty()){

	List<MaskSObject__c> sobjMask = new List<MaskSObject__c>{
		new MaskSObject__c(Sequence__c = 1, APIName__c = 'Account'),
		new MaskSObject__c(Sequence__c = 2, APIName__c = 'Contact', WhereClause__c = 'AssistantName != null', BatchSize__c = 1600)
	};
	upsert sobjMask APIName__c;

	List<MaskSObjectField__c> fieldMask = new List<MaskSObjectField__c>{
		new MaskSObjectField__c(MaskSObject__c = sobjMask.get(0).Id, APIName__c = 'Name',
			Action__c = MaskSObjectConstants.ACTION_OBFUSCATE, Mode__c = MaskSObjectConstants.MODE_ONESHOT),
		new MaskSObjectField__c(MaskSObject__c = sobjMask.get(0).Id, APIName__c = 'Phone',
			Action__c = MaskSObjectConstants.ACTION_OBFUSCATE, Mode__c = MaskSObjectConstants.MODE_SCHEDULED),
		new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'LastName',
			Action__c = MaskSObjectConstants.ACTION_REPLACE, ActionType__c = MaskSObjectConstants.ACTION_TYPE_DICT_LAST,
			Mode__c = MaskSObjectConstants.MODE_ONESHOT),
		new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'AssistantName',
			Action__c = MaskSObjectConstants.ACTION_REPLACE, Mode__c = MaskSObjectConstants.MODE_ONESHOT,
			ActionType__c = MaskSObjectConstants.ACTION_TYPE_HARDCODED, Value__c = 'HardcodedValue'),
		new MaskSObjectField__c(MaskSObject__c = sobjMask.get(1).Id, APIName__c = 'Email',
			Action__c = MaskSObjectConstants.ACTION_RANDOMIZE, Mode__c = MaskSObjectConstants.MODE_BOTH)
	};
	upsert fieldMask APIName__c;
} else{
	System.debug(LoggingLevel.ERROR, 'Required ' + psetName + ' permission set not deployed on this org, make sure to deploy the project before executing this script');
}