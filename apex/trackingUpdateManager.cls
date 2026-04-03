public class trackingUpdateManager {
	@AuraEnabled
    public static void addTrackingUpdate(Id loadId, String city, String stateCode, String ETA, String status, String comment){
        Tracking_Update__c trackingUpdate = new Tracking_Update__c();
        trackingUpdate.Load__c = loadId;
        trackingUpdate.City__c = city;
        trackingUpdate.State__c = stateCode;
        trackingUpdate.Status__c = status;
        trackingUpdate.ETA__c = ETA;
        trackingUpdate.Comment__c = comment;
        insert trackingUpdate;
    }
    @AuraEnabled(cacheable = true)
    public static List<Tracking_Update__c> getTrackingUpdate(Id loadId){
        List<Tracking_Update__c> trackingLog = [SELECT City__c, State__c, Status__c, ETA__c, Comment__c, Load__c, CreatedDate FROM Tracking_Update__c WHERE Load__c =: loadId ORDER BY CreatedDate];
        return trackingLog;
    }
}