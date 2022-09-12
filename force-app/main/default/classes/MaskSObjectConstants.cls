public with sharing class MaskSObjectConstants {

	/**
	 * MaskSObjectField__c
	 */

	//Action__c
	public static final String ACTION_ERASE = 'Erase';
	public static final String ACTION_REPLACE = 'Replace';
	public static final String ACTION_OBFUSCATE = 'Obfuscate';
	public static final String ACTION_RANDOMIZE = 'Randomize';
	public static final String ACTION_LUHN = 'Random Luhn number';

	//ActionType__c
	public static final String ACTION_TYPE_HARDCODED = 'Hardcoded';
	public static final String ACTION_TYPE_DICT = 'Dictionary';
	public static final String ACTION_TYPE_DICT_FIRST = ACTION_TYPE_DICT + '.firstname';
	public static final String ACTION_TYPE_DICT_LAST = ACTION_TYPE_DICT + '.lastname';
	public static final String ACTION_TYPE_DICT_FULL = ACTION_TYPE_DICT + '.fullname';
	public static final String ACTION_TYPE_DICT_EMAIL = ACTION_TYPE_DICT + '.email';
	public static final String ACTION_TYPE_DICT_COMPANY = ACTION_TYPE_DICT + '.company';
	public static final String ACTION_TYPE_DICT_STREET = ACTION_TYPE_DICT + '.street';
}
