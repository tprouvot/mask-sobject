/**
 * @description This class is used to mask the database by performing records updates
 */
public with sharing class MaskSObjectBatch implements Database.Batchable<sObject>{

	private Integer sequence;
	private Integer lastSequence;

	@TestVisible
	private String sobjectName;
	private static List<MaskSObjectField__c> fields;
	private static List<String> queryFields;

	private String whereClause;

	/**
	 * @description Instanciate constructor with parameters, is called in the finish method
	 * @param  sequence		Defines the Object Sequence to delete in this instance
	 * @param  lastSequence Defines the last Object sequence to execute
	 */
	public MaskSObjectBatch(Integer sequence, Integer lastSequence){
		setParams(sequence);
	}

	/**
	 * @description Instanciate constructor without parameters, is called by the schedulable class
	 */
	public MaskSObjectBatch() {
		setParams(null);
	}

	/**
	 * @description Build the query with the custom setting parameter with the SObject name
	 * @param  BC BatchableContext
	 * @return    QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext BC){
		//TODO Use batch size

		String query = 'SELECT Id, ' + String.join(queryFields, ',') + ' FROM ' + String.escapeSingleQuotes(this.sobjectName);
		if(String.isNotBlank(whereClause)){
			query += ' WHERE ' + whereClause;
		}
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<SObject> scope){

		for(SObject sobj : scope){
			//TODO Check if field is updatable to avoid errors
			for(MaskSObjectField__c field : fields){
				if(MaskSObjectConstants.ACTION_ERASE.equals(field.Action__c)){
					//TODO Handle non string fields types
					sobj.put(field.APIName__c, '');
				} else if(MaskSObjectConstants.ACTION_OBFUSCATE.equals(field.Action__c)){
					//TODO Handle non string fields types
					String val = (String)sobj.get(field.APIName__c);
					sobj.put(field.APIName__c, val.reverse());
				}
			}
		}

		SObjectType sObjType = ((SObject) Type.forName(this.sobjectName).newInstance()).getSObjectType();
		if (sObjType.getDescribe().isUpdateable()) {
			//Database.update(scope, false);
			update(scope);
		}
	}

	/**
	 * @description Call the MaskSObjectBatch to handle the update of the next records Object to parse
	 * @param  BC BatchableContext
	 */
	public void finish(Database.BatchableContext BC){
		//call the batch only if the Object list is not the last one
		if(sequence < lastSequence){
			Database.executeBatch(new MaskSObjectBatch(sequence, lastSequence));
		}
	}

	/**
	 * @description Instanciate the parameters of the batch :the sobjectName to parse and his sequence
	 * @param  sequence Object order of execution
	 */
	public void setParams(Integer sequence){
		//if param is null it means the method was called from the scheduled job
		if(sequence == null){
			sequence = 0;
		}

		//get the next sequences to avoid issue with missing numbers
		List<MaskSObject__c> settings = [SELECT APIName__c, Sequence__c, WhereClause__c
			,(SELECT APIName__c, Action__c FROM MaskSObjectFields__r) FROM MaskSObject__c
			WHERE Sequence__c >:sequence ORDER BY Sequence__c];

		//store the lastIndex to end the process
		if(lastSequence == null){
			//since the list is sorted by sequence, the last index is the last sequence
			this.lastSequence = Integer.valueOf(settings.get(settings.size() - 1).Sequence__c);
		}
		//use the first item of the list
		MaskSObject__c setting = settings.get(0);
		this.sequence = Integer.valueOf(setting.Sequence__c);
		this.sobjectName = setting.APIName__c;
		this.whereClause = setting.WhereClause__c;

		//store the fields to mask for the query
		fields = setting.MaskSObjectFields__r;
		queryFields = new List<String>();
		for(MaskSObjectField__c field : setting.MaskSObjectFields__r){
			queryFields.add(field.APIName__c);
		}
	}
}