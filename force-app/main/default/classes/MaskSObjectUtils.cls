public with sharing class MaskSObjectUtils {

	/**
	 * @description  Returns the list of MaskSObject__c after the sequence parameter
	 * @param sequence
	 * @return  `List<MaskSObject__c>`
	 */
	public static List<MaskSObject__c> getMaskSObjectList(Integer sequence){
		return [SELECT APIName__c, Sequence__c, WhereClause__c, BatchSize__c
			,(SELECT APIName__c, Action__c FROM MaskSObjectFields__r) FROM MaskSObject__c
			WHERE Sequence__c >:sequence ORDER BY Sequence__c];
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
		Set<String> chars = new Set<String> {'a', 'e', 'i', 'o', '1', '2', '5', '6'};
		for(String chr : chars){
			val = val.toLowerCase().replaceAll(chr, chr.isNumeric() ? '0' : 'x');
		}
		return val;
	}

	public static void maskField(Map<String, Schema.DisplayType> fieldType, MaskSObjectField__c field, SObject sobj){
		String val = (String)sobj.get(field.APIName__c);
		if(val != null){
			String retVal;

			if(MaskSObjectConstants.ACTION_ERASE.equals(field.Action__c)){
				retVal = null;
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
						Integer phonePrefixIndex = 2;
						prefix = val.left(phonePrefixIndex);
						val = val.substringAfter(prefix);
					}
				}

				if(MaskSObjectConstants.ACTION_RANDOMIZE.equals(field.Action__c)){
					val = getRandomString(val.length());
				} else if(MaskSObjectConstants.ACTION_OBFUSCATE.equals(field.Action__c)){
					val = obfuscate(val);
				}
				retVal = prefix + val + suffix;
			}
			sobj.put(field.APIName__c, retVal);
		}
	}
}
