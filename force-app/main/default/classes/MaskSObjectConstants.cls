public with sharing class MaskSObjectConstants {

	/**
	 * MaskSObjectField__c
	 */

	//Action__c
	public static final String ACTION_ERASE = 'Erase';
	public static final String ACTION_REPLACE = 'Replace';
	public static final String ACTION_OBFUSCATE = 'Obfuscate';
	public static final String ACTION_RANDOMIZE = 'Randomize';

	//ActionType__c
	public static final String ACTION_TYPE_HARDCODED = 'Hardcoded';
	public static final String ACTION_TYPE_DICT = 'Dictionary';
	public static final String ACTION_TYPE_DICT_FIRST = ACTION_TYPE_DICT + '.firstname';
	public static final String ACTION_TYPE_DICT_LAST = ACTION_TYPE_DICT + '.lastname';
	public static final String ACTION_TYPE_DICT_FULL = ACTION_TYPE_DICT + '.fullname';
}
