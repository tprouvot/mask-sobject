/**
 * @description This class is used to mask the database by performing records updates
 */
public with sharing class MaskSObjectBatch implements Database.Batchable<sObject>{

	private List<MaskSObjectDictionaryModel> dictionary;

	private Integer sequence;
	private Integer lastSequence;
	private Integer batchSize;

	@TestVisible
	private String sobjectName;
	private Boolean allowExecutionOnProd = Test.isRunningTest() ? true : MaskSObjectUtils.getOptions().AllowExecutionOnProd__c;

	private List<MaskSObjectField__c> fields;
	private List<String> queryFields;
	private String whereClause;
	private Map<String, Schema.DisplayType> fieldType;
	public String mode = MaskSObjectConstants.MODE_ONESHOT; //instanciate mode on 'One-Shot'

	/**
	 * @description Instanciate constructor with parameters, is called in the finish method
	 * @param  sequence		Defines the Object Sequence to delete in this instance
	 */
	public MaskSObjectBatch(Integer sequence){
		setParams(sequence, '%');
	}

	/**
	 * @description Instanciate constructor without parameters, is called by the schedulable class
	 */
	public MaskSObjectBatch() {
		setParams(null, '%');
	}

	/**
	 * @description Run the batch in scheduledMode
	 * @param isScheduledMode
	 */
	public MaskSObjectBatch(Boolean isScheduledMode){
		if(isScheduledMode){
			this.mode = MaskSObjectConstants.MODE_SCHEDULED;
		}
		setParams(null, '%');
	}

	/**
	 * @description Run the batch on a particular SObject
	 * @param sObjectName
	 */
	public MaskSObjectBatch(String sObjectName){
		setParams(sequence, sObjectName);
	}

	/**
	 * @description Build the query with the custom setting parameter with the SObject name
	 * @param  BC BatchableContext
	 * @return    QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext BC){
		String query;

		//update job informations
		AsyncApexJob job = getJob(BC.getJobId());
		try {
			upsert new MaskSObject__c(APIName__c = this.sobjectName, LastStart__c = System.now(), LastEnd__c = null,
			LastJobId__c = job.Id, JobItemsProcessed__c = job.JobItemsProcessed, TotalJobItems__c = job.TotalJobItems,
			NumberOfErrors__c = job.NumberOfErrors) APIName__c;

			query = 'SELECT Id, ' + String.join(this.queryFields, ',') + ' FROM ' + String.escapeSingleQuotes(this.sobjectName);

			if(!MaskSObjectUtils.isSandbox() && !allowExecutionOnProd){
				//build a query that returns no rows to prevent batch execution
				query += ' WHERE Id=null';
				System.debug(LoggingLevel.WARN, 'MaskSObjectBatch execution on production is forbidden, query updated to return 0 rows');
			} else if(String.isNotBlank(whereClause)){
				query += ' WHERE ' + whereClause;
			}
			return Database.getQueryLocator(query);
		} catch (Exception e) {
			MaskSObjectUtils.saveError(e, job.Id, this.sobjectName);
			return Database.getQueryLocator(query);
		}
	}

	public void execute(Database.BatchableContext BC, List<SObject> scope){
		AsyncApexJob job;
		try {
			job = getJob(BC.getJobId());

			for(SObject sobj : scope){
				Integer random = dictionary != null ? MaskSObjectUtils.getRandomInt(dictionary.size()) : null;
				MaskSObjectDictionaryModel data = dictionary != null ? dictionary.get(random) : null;
				for(MaskSObjectField__c field : this.fields){
					//check if the batch runs in the field's mode
					if(this.mode.equals(field.Mode__c) || MaskSObjectConstants.MODE_BOTH.equals(field.Mode__c)){
						MaskSObjectUtils.maskField(fieldType, field, sobj, data);
					}
				}
			}

			SObjectType sObjType = ((SObject) Type.forName(this.sobjectName).newInstance()).getSObjectType();
			if (sObjType.getDescribe().isUpdateable()) {
				List<Database.SaveResult> srList = Database.update(scope, false);
				MaskSObjectUtils.saveErrors(srList, job.Id, this.sobjectName);
			}

			upsert new MaskSObject__c(APIName__c = this.sobjectName, TotalJobItems__c = job.TotalJobItems,
				JobItemsProcessed__c = job.JobItemsProcessed + 1, NumberOfErrors__c = job.NumberOfErrors) APIName__c;
		} catch (Exception e) {
			MaskSObjectUtils.saveError(e, job.Id, this.sobjectName);
		}
	}

	/**
	 * @description Call the MaskSObjectBatch to handle the update of the next records Object to parse
	 * @param  BC BatchableContext
	 */
	public void finish(Database.BatchableContext BC){
		upsert new MaskSObject__c(APIName__c = this.sobjectName, LastEnd__c = System.now()) APIName__c;
		//call the batch only if the Object list is not the last one
		if(sequence < lastSequence){
			Database.executeBatch(new MaskSObjectBatch(sequence), this.batchSize);
		}
	}

	/**
	 * @description Instanciate the parameters of the batch :the sobjectName to parse and his sequence
	 * @param  sequence Object order of execution
	 * @param  sobjectName SObject name to run the batch on, can be '%' to run on all objects
	 */
	private void setParams(Integer sequence, String sobjectName){
		//if param is null it means the method was called from the scheduled job
		if(sequence == null){
			sequence = 0;
		}

		//get the next sequences to avoid issue with missing numbers
		List<MaskSObject__c> settings = MaskSObjectUtils.getMaskSObjectList(sequence, sobjectName);

		//store the lastIndex to end the process
		if(lastSequence == null){
			//since the list is sorted by sequence, the last index is the last sequence
			this.lastSequence = Integer.valueOf(settings.get(settings.size() - 1).Sequence__c);
		}

		//use the first item of the list
		MaskSObject__c setting = settings.get(0);
		this.sequence = Integer.valueOf(setting.Sequence__c);

		//batch size for the next execution is in the next list index
		if(settings.size() > 1){
			this.batchSize = settings.get(1)?.BatchSize__c != null ? Integer.valueOf(settings.get(1).BatchSize__c) : MaskSObjectUtils.BATCH_SIZE;
		}

		this.sobjectName = setting.APIName__c;
		this.whereClause = setting.WhereClause__c;

		//store the fields to mask for the query
		this.fields = setting.MaskSObjectFields__r;
		queryFields = new List<String>();

		setDictionaryIfRequied(setting);

		//store describe field result to set it only on new SObject iteration
		setFieldsTypes();
	}

	private void setFieldsTypes(){
		Schema.DescribeSObjectResult descr = Schema.getGlobalDescribe().get(this.sobjectName).getDescribe();
		Map<String, Schema.SObjectField> fields = descr.fields.getMap();

		fieldType = new Map<String, Schema.DisplayType>();
		for(String field : this.queryFields){
			Schema.DescribeFieldResult fr = fields.get(field.toLowerCase()).getDescribe();
			fieldType.put(field, fr.getType());
		}
	}

	private AsyncApexJob getJob(Id jobId){
		return [SELECT JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE Id=:jobId];
	}

	/**
	 * @description Set the dictionary class variable if one of the MaskSObjectField__c requires dictionnary
	 * @param setting MaskSObject__c
	 */
	private void setDictionaryIfRequied(MaskSObject__c setting){
		Boolean requireDictionary = false;
		for(MaskSObjectField__c field : setting.MaskSObjectFields__r){
			this.queryFields.add(field.APIName__c);
			if(!requireDictionary && field.ActionType__c != null && field.ActionType__c.startsWith(MaskSObjectConstants.ACTION_TYPE_DICT)){
				requireDictionary = true;
			}
		}

		if(this.dictionary == null && requireDictionary){
			StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'MaskSObjectDictionary' LIMIT 1];
			this.dictionary = (List<MaskSObjectDictionaryModel>)JSON.deserializeStrict(sr.Body.toString(),
			List<MaskSObjectDictionaryModel>.class);
		}
	}
}