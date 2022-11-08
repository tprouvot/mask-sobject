public with sharing class MaskSObjectUtils {

	public static MaskSObjectSettings__mdt options;
	public final static Integer BATCH_SIZE = 2000;

	/**
	 * @description Allow users to run the batch for all or a particular object
	 * @param sobjectName
	 */
	public static void executeBatch(String sobjectName){
		List<MaskSObject__c> settings = MaskSObjectUtils.getMaskSObjectList(0, sobjectName);
		if(!settings.isEmpty()){
			MaskSObject__c setting = settings.get(0);
			Integer batchSize = setting.BatchSize__c != null ? Integer.valueOf(setting.BatchSize__c) : BATCH_SIZE;
			Database.executeBatch(new MaskSObjectBatch(sobjectName), batchSize);
		}
	}

	/**
	 * @description  Returns the list of MaskSObject__c after the sequence parameter
	 * @param sequence : Minimum sequence number to retrieve
	 * @param sobjectName : sobjectName to retrieve, can be '%'
	 * @return  `List<MaskSObject__c>`
	 */
	public static List<MaskSObject__c> getMaskSObjectList(Integer sequence, String sobjectName){
		return [SELECT APIName__c, Sequence__c, WhereClause__c, BatchSize__c
			,(SELECT APIName__c, Action__c, ActionType__c, Value__c, Mode__c FROM MaskSObjectFields__r) FROM MaskSObject__c
			WHERE Sequence__c >:sequence AND APIName__c LIKE :sobjectName ORDER BY Sequence__c];
	}

	/**
	 * @description Returns a random string based on the length char number
	 * @param len
	 * @return  `String`
	 */
	private static String getRandomString(Integer len){
		Blob blobKey = Crypto.generateAesKey(128);
		String key = EncodingUtil.base64encode(blobKey);
		return key.substring(0, len > key.length() ? key.length() : len);
	}

	/**
	 * @description Returns a the val input obfuscated (some char replaced by 'x' and numbers by 0)
	 * @param val
	 * @return  `String`
	 */
	private static String obfuscate(String val){
		List<String> chars = options.ObfuscatedCharacters__c.split(',');
		for(String chr : chars){
			val = val.toLowerCase().replaceAll(chr, chr.isNumeric() ? options.ObfuscateDigitReplacement__c : options.ObfuscateCharacterReplacement__c);
		}
		return val;
	}

	public static void maskField(Map<String, Schema.DisplayType> fieldType, MaskSObjectField__c field, SObject sobj, MaskSObjectDictionaryModel data){
		String val = (String)sobj.get(field.APIName__c);
		options = getOptions();
		if(val != null){
			String retVal;

			if(MaskSObjectConstants.ACTION_ERASE.equals(field.Action__c)){
				retVal = null;
			} else if(MaskSObjectConstants.ACTION_REPLACE.equals(field.Action__c)){
				if(MaskSObjectConstants.ACTION_TYPE_HARDCODED.equals(field.ActionType__c)){
					retVal = field.Value__c;
				} else if(field.ActionType__c.startsWith(MaskSObjectConstants.ACTION_TYPE_DICT)){
					retVal = getDictionaryValue(val, field, data);
				}
			} else {
				String prefix = '';
				String suffix = '';

				switch on fieldType.get(field.APIName__c) {
					when EMAIL{
						//keep the email suffix to create a valid email address
						suffix = '@' + val.substringAfter('@');
						val = val.substringBefore('@');
					}
					when PHONE{
						//keep the prefix to prevent VR errors
						prefix = val.left((Integer)options.NumberOfDigitToPreserveInPhones__c);
						val = val.substringAfter(prefix);
					}
				}

				if(MaskSObjectConstants.ACTION_RANDOMIZE.equals(field.Action__c)){
					val = getRandomString(val.length());
				} else if(MaskSObjectConstants.ACTION_LUHN.equals(field.Action__c)){
					//remove last char to calculate it from calculateLuhnCheckDigit
					val = getRandomIntDigits(val.length()- 1);
					val += calculateLuhnCheckDigit(val);
				} else if(MaskSObjectConstants.ACTION_OBFUSCATE.equals(field.Action__c)){
					val = obfuscate(val);
				}
				retVal = prefix + val + suffix;
			}
			sobj.put(field.APIName__c, retVal);
		}
	}

	public static String getDictionaryValue(String val, MaskSObjectField__c field, MaskSObjectDictionaryModel data){
		String retVal;
		if(MaskSObjectConstants.ACTION_TYPE_DICT_FIRST.equals(field.ActionType__c)){
			retVal = data.firstName;
		} else if(MaskSObjectConstants.ACTION_TYPE_DICT_LAST.equals(field.ActionType__c)){
			retVal = data.lastName;
		} else if(MaskSObjectConstants.ACTION_TYPE_DICT_FULL.equals(field.ActionType__c)){
			retVal = data.fullName;
		} else if(MaskSObjectConstants.ACTION_TYPE_DICT_EMAIL.equals(field.ActionType__c)){
			retVal = data.email;
		} else if(MaskSObjectConstants.ACTION_TYPE_DICT_COMPANY.equals(field.ActionType__c)){
			retVal = data.company;
		} else if(MaskSObjectConstants.ACTION_TYPE_DICT_STREET.equals(field.ActionType__c)){
			retVal = data.street;
		}
		return retVal;
	}

	public static Integer getRandomInt(Integer max){
		return Integer.valueof((Math.random() * max));
	}

	public static String getRandomIntDigits(Integer numberOfDigits){
		//generate a random int between 15 and 19 digits
		String rdm = String.valueOf(Math.random()).substringAfter('.');
		//handle the case when the generated int is not big enough
		rdm += rdm.length() < numberOfDigits ? rdm : '';
		while(rdm.length() > numberOfDigits){
			rdm = rdm.substring(1);
		}
		return rdm;
	}

	public static MaskSObjectSettings__mdt getOptions(){
		return options != null ? options : MaskSObjectSettings__mdt.getInstance('Default');
	}

	public static Boolean isSandbox(){
		return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
	}

	private static Integer accumulateLuhn(String[] digits) {
		// This algorithm goes from the *left*, so we need to know which to double
		Integer checkSize = 0;
		Integer accumulator = 0;
		while(!digits.isEmpty()) {
			Integer nextDigit;
			try{
				nextDigit = Integer.valueOf(digits.remove(0));
				// We should double the value when true
				if((digits.size()&1) == checkSize) {
					nextDigit <<= 1;
					// And "add together" the individual digits when 10+
					if(nextDigit > 9) {
						nextDigit -= 9;
					}
				}
				accumulator += nextDigit;
			} catch(Exception e){
				System.debug(LoggingLevel.ERROR, e.getMessage());
				break;
			}
		}
		return accumulator;
	}

	public static String calculateLuhnCheckDigit(String source) {
		return String.valueOf(Math.mod(accumulateLuhn(source.split('')) * 9, 10));
	}

	public static void saveErrors(List<Database.SaveResult> srList, Id jobId, String sobj){
		if(!options.DisableLogError__c){
			List<MaskSObjectError__c> errs = new List<MaskSObjectError__c>();
			for(Database.SaveResult sr : srList){
				if(!sr.isSuccess()){
					String error = getError(sr.getErrors());
					errs.add(createError(sr.getId(), error, jobId, sobj));
				}
			}
			insert errs;
		}
	}

	public static void saveError(Exception e, Id jobId, String sobj){
		if(!options.DisableLogError__c){
			String error = e.getMessage() + ' ' + e.getStackTraceString();
			insert createError(null, error, jobId, sobj);
		}
	}

	/**
	 * @description Returns formated Database.Error to String
	 * @param errors
	 * @return Database.Error information (statusCode, fields and message)
	 */
	public static String getError(List<Database.Error> errors){
		String error = '';
		for (Database.Error er: errors) {
			error += '[' + er.getStatusCode() + '] ' + er.getFields() + ' ' + er.getMessage();
		}
		return error;
	}

	public static MaskSObjectError__c createError(Id recId, String error, Id jobId, String sobj){
		return new MaskSObjectError__c(RecordId__c = recId, Error__c = error, JobId__c = jobId, SObject__c = sobj);
	}
}