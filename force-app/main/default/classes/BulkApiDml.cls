/**
 * This class exposes a method which allows to perform DML operations throught Bulk API
 */
public with sharing class BulkApiDml {
	public static final String API_VERSION = '56.0';
	public static Id jobId;
	public static String SObjectName;

	/**
	 * @description This method creates a Bulk job, uploads job data and close the job when upload is complete.
	 * @param fields List of fields to update
	 * @param records List of SObject to update
	 * @param operation DML operation ('insert', 'delete', 'hardDelete', 'update', 'upsert')
	 * @return Job ID
	 */
	public static Id importBulkdata(List<String> fields, List<SObject> records, String operation) {
		String sessId = UserInfo.getSessionId();
		SObjectName = records.getSObjectType().getDescribe().getName();

		try {
			if(!records.isEmpty()) {

				//create new job
				HttpResponse respJobId = getHttpResponse('POST', '', 'application/json', sessId, getJobIdBody(operation));

				if(respJobId.getStatusCode() <= 299) {
					Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(respJobId.getBody());
					jobId = (String)respMap.get('id');

					//send records to the server
					HttpResponse resp = getHttpResponse('PUT', '/' + jobId + '/batches', 'text/csv', sessId, getCsvExport(fields, records));

					if(resp.getStatusCode() <= 299) {
						//close job
						getHttpResponse('PATCH', '/' + jobId, 'application/json', sessId, '{ "state" : "UploadComplete" }');
					}
				}
			}
		} catch (Exception e) {
			MaskSObjectUtils.saveError(e, jobId, SObjectName);
		}
		return jobId;
	}

	private static String getCsvExport(List<String> fields, List<SObject> records) {
		String csv = String.join(fields, ',');
		csv += '\n';

		for (SObject record : records) {
			for(String key : fields){
				csv += record.get(key) + ',';
			}
			csv = csv.removeEnd(',');
			csv += '\n';
		}
		return csv;
	}

	private static String getJobIdBody(String operation){
		return '{ "externalIdFieldName": "Id", "lineEnding": "LF", "operation": "' + operation + '",' +
		'"object": "' + SObjectName + '", "contentType": "CSV"}';
	}

	private static void saveError(HttpResponse resp){
		String error = resp.toString() + ' : There was an error. Please contact your admin.';
		MaskSObjectUtils.saveError(error, jobId, SObjectName);
	}

	private static HttpResponse getHttpResponse(String method, String endpoint, String contentType, String token, String body){
		HttpRequest req = new HttpRequest();
		req.setMethod(method);
		req.setEndpoint(URl.getOrgDomainUrl().toExternalForm() + '/services/data/v' + API_VERSION + '/jobs/ingest' + endpoint);
		req.setHeader('content-type', contentType);
		req.setHeader('Authorization', 'Bearer ' + token);

		req.setBody(body);
		HttpResponse resp = new Http().send(req);
		if(resp.getStatusCode() >= 299) {
			saveError(resp);
		}
		return resp;
	}
}
