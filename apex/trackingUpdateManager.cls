public class trackingUpdateManager {
	@AuraEnabled
    public static void addTrackingUpdate(Id loadId, String city, String stateCode, String ETA, String status, String comment, String trackingType){
        Tracking_Update__c trackingUpdate = new Tracking_Update__c();
        trackingUpdate.Load__c = loadId;
        trackingUpdate.City__c = city;
        trackingUpdate.State__c = stateCode;
        trackingUpdate.Status__c = status;
        trackingUpdate.ETA__c = ETA;
        trackingUpdate.Comment__c = comment;
        trackingUpdate.Source__c = 'Manually Entered';
        trackingUpdate.Type__c = trackingType;
        insert trackingUpdate;
    }
    @AuraEnabled(cacheable = true)
    public static List<Tracking_Update__c> getTrackingUpdate(Id loadId){
        List<Tracking_Update__c> trackingLog = [SELECT Type__c, Source__c, City__c, State__c, Status__c, ETA__c, Comment__c, Load__c, CreatedDate FROM Tracking_Update__c WHERE Load__c =: loadId ORDER BY CreatedDate];
        return trackingLog;
    }
    
    @AuraEnabled(cacheable = true)
    public static List<String> getTrackingType(){
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Tracking_Update__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            if (pickListVal.isActive()) { // Optional: only active values
                picklistValues.add(pickListVal.getValue());
                System.debug('Value: ' + pickListVal.getValue() + ' Label: ' + pickListVal.getLabel());
            }
        }
        return picklistValues;
    }
}