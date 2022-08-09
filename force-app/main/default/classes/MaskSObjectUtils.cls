public with sharing class MaskSObjectUtils {

	/**
	 * @description Returns a random string based on the length char number
	 * @param len
	 * @return  `String`
	 */
	public static String getRandomString(Integer len){
		Blob blobKey = Crypto.generateAesKey(192);
		String key = EncodingUtil.base64encode(blobKey);
		return key.substring(0, len);
	}
}
