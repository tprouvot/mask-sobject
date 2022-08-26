//Assign required pset
String psetName = 'MaskSObjectAdmin';
List<PermissionSet> psets = [SELECT Id FROM PermissionSet WHERE Name =:psetName];
if(!psets.isEmpty()){
	List<PermissionSetAssignment> psas = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :psets.get(0).Id
		AND AssigneeId =: UserInfo.getUserId()];
	if(psas.isEmpty()){
		PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = psets.get(0).Id, AssigneeId = UserInfo.getUserId());
		insert psa;
	} else{
		System.debug(LoggingLevel.INFO, 'PermissionSet ' + psetName + ' already assigned to current user.');
	}

} else{
	System.debug(LoggingLevel.ERROR, 'Required ' + psetName + ' permission set not deployed on this org, make sure to deploy the project before executing this script');
}