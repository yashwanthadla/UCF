public with sharing class UCFIntegrationController{

	@AuraEnabled(cacheable = true)
	public static String fetchSharedLists(){
		HTTPResponse response = ucfCallout('callout:UCF_Sandbox_Library/my-account');
		//HTTPResponse response = ucfCallout('https://api2.unifiedcompliance.com/my-account','c1e963629f99cfb3bb2712ff0a9bb18d984ca5b5');
		//endpoint is https://api2.unifiedcompliance.com/my-account
		DeserializeAccountResponse resp = DeserializeAccountResponse.parse(response.getBody());

		List<String> authorityDocumentLinks = new List<String>();//list to story ad links
		Map<Integer,String> mapAuthorityDocIdandLink = new Map<Integer,String>();
		for(DeserializeAccountResponse.Ad_lists adList : resp.ad_lists) {
			Map<Integer, String> authorityDocListIdAndName = new Map<Integer, String>();//map for list id and name
			authorityDocListIdAndName = adList.mapAuthorityDocListIdAndName;
			DeserializeAccountResponse.Users authorityDocAndLink = adList.authority_documents;
			authorityDocumentLinks.add(authorityDocAndLink.x_href);
			/*Integer docID = authorityDocListIdAndName.keySet();
			mapAuthorityDocIdandLink.put(docID,authorityDocAndLink.x_href);*/
		}
		List<Integer> authoritydocIdList = fetchAuthorityDocumentsFromSharedLists(authorityDocumentLinks);//2nd Callout -56
		System.debug('authorityDocId list-->'+authoritydocIdList);
		System.debug('authorityDocId list count-->'+authoritydocIdList.size());//197

		// 3 callout:To get Ad details, citations, controls, issuer
		fetchAuthorityDocumentsDetails(1014);//3rd callout

		// BatchToMakeAuthorityDocCallouts test1 = new BatchToMakeAuthorityDocCallouts(authoritydocIdList);
		// Database.executeBatch(test1, 1);
		return null;
	}

	public static List<Integer> fetchAuthorityDocumentsFromSharedLists(List<String> authorityDocLinks){//2nd callout
		List<Integer> authorityDocId = new List<Integer>();//store ad Id
		if(!authorityDocLinks.isEmpty()) {
			System.debug('authorityDocLinks-->'+authorityDocLinks);

			// Map<Integer,List<Integer>> mapSharedIdandAdId = new Map<Integer,List<Integer>>();
			for (String adLink : authorityDocLinks) {
				//https://api2.unifiedcompliance.com/cch-ad-list/9679/authority-documents = adLink Sample
				String urlParam = adLink.substringAfter('.com');//trim to get url parameters
				Integer urlParamID = Integer.valueOf(adLink.substringBetween('list/','/authority'));//trim to get id from url
				//  Integer.valueOf(urlParamID)
				// List<Integer> adID = new List<Integer>();//list to story ad links
				HTTPResponse responseAD = ucfCallout('callout:UCF_Sandbox_Library'+urlParam);
				//HTTPResponse responseAD = ucfCallout(adLink,'c1e963629f99cfb3bb2712ff0a9bb18d984ca5b5');
				List<DeserializeAuthorityDocList> adResponse = DeserializeAuthorityDocList.parse(responseAD.getBody());

				System.debug(adResponse);
				for (DeserializeAuthorityDocList ad : adResponse) {

					authorityDocId.add(ad.id);//List of Authority Doc ID
					// adID.add(ad.id);
				}
				// mapSharedIdandAdId.put(urlParamID, adID); //Map of Shared List Id and Authority Doc Id
			}
			// System.debug(mapSharedIdandAdId);//Display Map of Shared List Id and Authority Doc Id

			// for (Integer adL : mapSharedIdandAdId.keyset()) {//To Display SL id = AD ids
			// 	for(Integer s : mapSharedIdandAdId.get(adL)) {
			// 		System.debug('SL: '+adL+', Ad: '+s);
			// 	}

			// }
		}
		return authorityDocId;
	}

	@future (callout=true)
	public static void fetchAuthorityDocumentsDetails(Integer authorityDocID){//3rd callout
		//for(Integer adId : authorityDocID) {
			//https://api2.unifiedcompliance.com/authority-document/9679/details
			String ulrParamToGetAdDetails = '/authority-document/'+authorityDocID+'/details?ciToCs=false';
			HTTPResponse responseADDetails = UCFIntegrationController.ucfCallout('callout:UCF_Sandbox_Library'+ulrParamToGetAdDetails);

			DeserialiseAuthorityDocResponse adRes = DeserialiseAuthorityDocResponse.parse(responseADDetails.getBody());
			system.debug(adRes);
			// DeserialiseAuthorityDocResponse data = (DeserialiseAuthorityDocResponse)JSON.deserialize(responseADDetails.getBody(),DeserialiseAuthorityDocResponse.class);

			for(DeserialiseAuthorityDocResponse.citations citation : adRes.citations) {
				System.debug('Authority Doc-> '+authorityDocID+' Citation==> '+citation);
				System.debug('getHeapSize--'+Limits.getHeapSize());
				System.debug('getLimitHeapSize--'+Limits.getLimitHeapSize());
			}
			//break;
			//
		//}
		//return authorityDocId;
	}
	public static HTTPResponse ucfCallout(String endPoint){//, String password
		Http httpRequest = new Http();
		HttpRequest request = new HttpRequest();
		request.setEndpoint(endPoint);
		request.setMethod('GET');
		request.setHeader('Authorization', 'Bearer ' + '{!$Credential.Password}');
		//request.setHeader('Authorization', 'Bearer ' + password );
        System.debug('response body-' + request);
		HTTPResponse response = httpRequest.send(request);
        // System.debug('response body-' + response.getBody());
		return response;
	}
}