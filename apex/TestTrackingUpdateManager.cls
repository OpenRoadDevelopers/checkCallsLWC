@isTest
public class TestTrackingUpdateManager {
	private static Id createAccount() {
        Account acct = new Account(Name='Test Customer', UTC_Offset__c = -6);
        insert acct;
        return acct.Id;
    }
    private static rtms__Load__c createLoad(Id accountId) {
        rtms__Load__c load = new rtms__Load__c(Name='Test Load', rtms__Customer__c=accountId, rtms__Total_Weight__c = 1000);
        insert load;
        return load;
    }
    private static Id createTrackingUpdate(Id loadId, String city, String stateCode, String ETA, String status, String comment, String trackingType){
        Tracking_Update__c trackingUpdate = new Tracking_Update__c();
        trackingUpdate.Load__c = loadId;
        trackingUpdate.City__c = city;
        trackingUpdate.State__c = stateCode;
        trackingUpdate.ETA__c = ETA;
        trackingUpdate.Status__c = status;
        trackingUpdate.Comment__c = comment;
        trackingUpdate.Source__c = 'Manually Entered';
        trackingUpdate.Type__c = trackingType;
        insert trackingUpdate;
        return trackingUpdate.Id;
    }
    @isTest
    static void testAddTrackingUpdate(){
        Id acctId = createAccount();
        rtms__Load__c load = createLoad(acctId);
       
        trackingUpdateManager.addTrackingUpdate(load.Id, 'Beaverton', 'OR', '2 hours away', 'On Time', 'comment', 'Location Update');
        
        Tracking_Update__c trackingUpdate = [
            SELECT Load__c, City__c, State__c, ETA__c, Status__c, Comment__c, Source__c, Type__c
            FROM Tracking_Update__c
            WHERE Load__c = :load.Id
            LIMIT 1
        ];
        
        System.assertEquals(load.Id, trackingUpdate.Load__c, 'Load Id should match');
        System.assertEquals('Beaverton', trackingUpdate.City__c, 'city should match');
        System.assertEquals('OR', trackingUpdate.State__c, 'state code should match');
        System.assertEquals('2 hours away', trackingUpdate.ETA__c, 'ETA should match');
        System.assertEquals('On Time', trackingUpdate.Status__c, 'status should match');
        System.assertEquals('comment', trackingUpdate.Comment__c, 'comment should match');
        System.assertEquals('Manually Entered', trackingUpdate.Source__c, 'source should match');
        System.assertEquals('Location Update', trackingUpdate.Type__c, 'type should match');
    }
    
    @isTest
    static void testGetTrackingUpdate(){
        Id acctId = createAccount();
        rtms__Load__c load = createLoad(acctId);
        Id trackingUpdateId = createTrackingUpdate(load.Id, 'Beaverton', 'OR', '2 hours away', 'On Time', 'comment', 'Location Update');
        Id secondTrackingUpdateId = createTrackingUpdate(load.Id, 'Portland', 'OR', '3 hours away', 'Delayed', 'another comment', 'Location Update');
        List<Tracking_Update__c> trackingUpdates = trackingUpdateManager.getTrackingUpdate(load.Id);
        System.assertEquals(2, trackingUpdates.size(), 'There should be 2 tracking updates');
        System.assertEquals(trackingUpdateId, trackingUpdates[0].Id, 'The first tracking update Id should match');
        System.assertEquals(secondTrackingUpdateId, trackingUpdates[1].Id, 'The second tracking update Id should match');
        System.assertEquals('Location Update', trackingUpdates[0].Type__c, 'The first type should match');
        System.assertEquals('Manually Entered', trackingUpdates[0].Source__c, 'The first source should match');
        System.assertEquals('Beaverton', trackingUpdates[0].City__c, 'The first city should match');
        System.assertEquals('OR', trackingUpdates[0].State__c, 'The first state should match');
        System.assertEquals('On Time', trackingUpdates[0].Status__c, 'The first status should match');
        System.assertEquals('2 hours away', trackingUpdates[0].ETA__c, 'The first ETA should match');
        System.assertEquals('comment', trackingUpdates[0].Comment__c, 'The first comment should match');
    }
	
    @isTest
    static void testNullGetTrackingUpdate(){
        Id acctId = createAccount();
        rtms__Load__c load = createLoad(acctId);
        List<Tracking_Update__c> trackingUpdates = trackingUpdateManager.getTrackingUpdate(load.Id);
        System.assertEquals(0, trackingUpdates.size(), 'There should be no tracking updates');
    }
   
    @isTest
    static void testGetRecentUpdate(){
        Id acctId = createAccount();
        rtms__Load__c load = createLoad(acctId);
        Id trackingUpdateId = createTrackingUpdate(load.Id, 'Beaverton', 'OR', '2 hours away', 'On Time', 'comment', 'Location Update');
        Datetime pastDate = Datetime.now().addDays(-5);
        Test.setCreatedDate(trackingUpdateId, pastDate);
        Id secondTrackingUpdateId = createTrackingUpdate(load.Id, 'Portland', 'OR', '3 hours away', 'Delayed', 'another comment', 'Location Update');
        Datetime pastDate2 = Datetime.now().addDays(-4);
        Test.setCreatedDate(secondTrackingUpdateId, pastDate2);
        Tracking_Update__c trackingUpdates = trackingUpdateManager.getRecentUpdate(load.Id);
        System.assertEquals(secondTrackingUpdateId, trackingUpdates.Id, 'The first tracking update Id should match');
        System.assertEquals('Location Update', trackingUpdates.Type__c, 'The first type should match');
        System.assertEquals('Manually Entered', trackingUpdates.Source__c, 'The first source should match');
        System.assertEquals('Portland', trackingUpdates.City__c, 'The first city should match');
        System.assertEquals('OR', trackingUpdates.State__c, 'The first state should match');
        System.assertEquals('Delayed', trackingUpdates.Status__c, 'The first status should match');
        System.assertEquals('3 hours away', trackingUpdates.ETA__c, 'The first ETA should match');
        System.assertEquals('another comment', trackingUpdates.Comment__c, 'The first comment should match');
    }
    
    @isTest
    static void testNoGetRecentUpdate(){
        Id acctId = createAccount();
        rtms__Load__c load = createLoad(acctId);
        Tracking_Update__c trackingUpdates = trackingUpdateManager.getRecentUpdate(load.Id);
        System.assertEquals(null, trackingUpdates, 'trackingUpdates should be null when there are no tracking updates');
    }
     
    @isTest
    static void testGetTrackingType(){
        Id acctId = createAccount();
        rtms__Load__c load = createLoad(acctId);
        List<String> trackingTypes = trackingUpdateManager.getTrackingType();
        System.assertEquals(3, trackingTypes.size(), 'There should be 3 tracking types');
        System.assertEquals('Location Update', trackingTypes[0], 'The first tracking type should match');
        System.assertEquals('Shipment Event', trackingTypes[1], 'The second tracking type should match');
        System.assertEquals('Issue Event', trackingTypes[2], 'The third tracking type should match');
    }
}