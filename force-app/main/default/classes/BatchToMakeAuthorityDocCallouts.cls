public class BatchToMakeAuthorityDocCallouts implements Database.Batchable<Integer>, Database.AllowsCallouts {
    public List<Integer> authorityDocIds;

    public BatchToMakeAuthorityDocCallouts(List<Integer> adIds) {
        authorityDocIds = adIds;
    }

    public Iterable<Integer> start(Database.BatchableContext BC) {
        System.debug('msg');
        return (Iterable<Integer>) authorityDocIds;
    }
    //System.Iterable<SObject> Database.Batchable<SObject>.start(Database.BatchableContext)
    public void execute(Database.BatchableContext BC, List<Integer> adDocIds) {
        for(Integer adId : adDocIds) {
             try {
                    String ulrParamToGetAdDetails = '/authority-document/'+adId+'/details';
                    HTTPResponse responseADDetails = UCFIntegrationController.ucfCallout('callout:UCF_Sandbox_Library'+ulrParamToGetAdDetails);
                    //https://api2.unifiedcompliance.com/authority-document/9679/details
                    System.debug('Batch job response-'+adId+'==>'+responseADDetails.getBody());
            }
            catch (Exception e) {
                System.debug('Error is :' + e.getMessage() + 'LN:' + e.getLineNumber() );
            }
        }
    }
    public void finish(Database.BatchableContext BC){

     }
}