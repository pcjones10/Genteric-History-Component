public class GenericHistoryComponentController {
    
    // External variables
    public SObject myObject {get; set;}
    public Integer recordLimit {get; set;}
    public Integer updatedRecordLimit {get; set;}
    public Integer tableSize {get; set;}
    public static String objectLabel {get;}
    public Id myObjectId {get;set;}
    public Integer rowCount {get;set;}
    // Internal Variables
    public objectHistoryLine[] objectHistory; 

    public static final Map<String, Schema.SObjectType> mySObjectTypeMap = Schema.getGlobalDescribe();
    public static Map<String, Schema.SObjectField> myObjectFieldMap;
    public static List<Schema.PicklistEntry> historyFieldPicklistValues;
    
    public List<objectHistoryLine> getObjectHistory(){
		if(updatedRecordLimit != null){
			recordLimit = updatedRecordLimit;
		}else{
			updatedRecordLimit = recordLimit;
		}
		
	// if no object passed in, return empty list
        if (myObject == null) {
            return new List<objectHistoryLine>();
        }

        myObjectId = String.valueOf(myObject.get('Id'));
        Schema.DescribeSObjectResult objectDescription = myObject.getSObjectType().getDescribe();

        myObjectFieldMap = objectDescription.fields.getMap();
        objectLabel = String.valueOf(objectDescription.getLabel());
        
        //Get the name of the history table
        String objectHistoryTableName = objectDescription.getName();
        
        //ID field name         
		string ObjectIdName;
		
		//if we have a custom object we need to drop the 'c' off the end before adding 'History' to get the history tables name        
		if (objectDescription.isCustom()){            
			objectHistoryTableName = objectHistoryTableName.substring(0, objectHistoryTableName.length()-1);
			ObjectIdName = 'ParentId';        
		}        
		else{
		    ObjectIdName = objectHistoryTableName+ 'Id';
		}
		
	if(objectHistoryTableName == 'Opportunity') {objectHistoryTableName = objectHistoryTableName + 'FieldHistory';}
	else {objectHistoryTableName = objectHistoryTableName + 'History';}
        objectHistoryTableName = objectHistoryTableName.replace('P2Express__','');
        Schema.DescribeFieldResult objectHistoryFieldField = mySObjectTypeMap.get(objectHistoryTableName).getDescribe().fields.getMap().get('Field').getDescribe();
        historyFieldPicklistValues = objectHistoryFieldField.getPickListValues();
                    
        list<objectHistoryLine> objectHistory = new list<objectHistoryLine>();
        
        String prevDate = '';
                
        if (recordLimit== null){
            recordLimit = 100;
        }
                
        list<sObject> historyList = Database.query( 'SELECT CreatedDate,'+
                                                    'CreatedById,'+
                                                    'Field,'+
                                                    'NewValue,'+
                                                    'OldValue ' +
                                                    'FROM ' + objectHistoryTableName + ' ' +
                                                    'WHERE ' + ObjectIdName + ' =\'' + myObjectId + '\' ' +
                                                    'ORDER BY CreatedDate DESC');
        
        
        Integer tempTableSize = historyList.size();
        tableSize = 0;
        rowCount = 0;
        for(Integer i = 0; i < tempTableSize; i++){
            sObject historyLine = historyList.get(i);
            
            Boolean isId = false;
            
            try{
            	SObjectType testIdOld = Id.valueOf(String.valueOf(historyLine.get('oldValue'))).getSObjectType();
            	SObjectType testIdNew = Id.valueOf(String.valueOf(historyLine.get('newValue'))).getSObjectType();
            	isId = true;
            }catch(Exception e){}
            
            if(!isId){
            	if ((historyLine.get('newValue') == null && historyLine.get('oldValue') == null) 
	                    || (historyLine.get('newValue') != null && !(string.valueOf(historyLine.get('newValue')).startsWith('005') || string.valueOf(historyLine.get('newValue')).startsWith('00G')))
	                    || (historyLine.get('oldValue') != null && !(string.valueOf(historyLine.get('oldValue')).startsWith('005') || string.valueOf(historyLine.get('oldValue')).startsWith('00G')))){
            				tableSize++;
	                    }
            }
        }
         
        for(Integer i = 0; i < tempTableSize; i++){
            sObject historyLine = historyList.get(i);
            
            Boolean isId = false;
            
            try{
            	SObjectType testIdOld = Id.valueOf(String.valueOf(historyLine.get('oldValue'))).getSObjectType();
            	SObjectType testIdNew = Id.valueOf(String.valueOf(historyLine.get('newValue'))).getSObjectType();
            	isId = true;
            }catch(Exception e){}
            
            if(!isId && rowCount < recordLimit){
            	
	            if ((historyLine.get('newValue') == null && historyLine.get('oldValue') == null) 
	                    || (historyLine.get('newValue') != null && !(string.valueOf(historyLine.get('newValue')).startsWith('005') || string.valueOf(historyLine.get('newValue')).startsWith('00G')))
	                    || (historyLine.get('oldValue') != null && !(string.valueOf(historyLine.get('oldValue')).startsWith('005') || string.valueOf(historyLine.get('oldValue')).startsWith('00G')))){
	                objectHistoryLine tempHistory = new objectHistoryLine();
	                // Set the Date and who performed the action
	                if (String.valueOf(historyLine.get('CreatedDate')) != prevDate){
	                    tempHistory.theDate = datetime.valueof(historyLine.get('CreatedDate')).format();
	                    tempHistory.userId = String.valueOf(historyLine.get('CreatedById'));
	                    tempHistory.who = String.valueOf(historyLine.get('CreatedById'));
	                }
	                else{
	                    tempHistory.theDate = '';
	                    tempHistory.who = '';
	                    tempHistory.userId = String.valueOf(historyLine.get('CreatedById'));
	                }
	                prevDate = String.valueOf(historyLine.get('CreatedDate'));
	                
	                // Get the field label
	                String fieldLabel = GenericHistoryComponentController.returnFieldLabel(String.valueOf(historyLine.get('Field')));
	                
	                // Set the Action value
	                   if (String.valueOf(historyLine.get('Field')) == 'created') {    // on Creation
	                       tempHistory.action = 'Created.';
	                  }
	                  else if (historyLine.get('oldValue') != null && historyLine.get('newValue') == null){ // when deleting a value from a field
	                      // Format the Date and if there's an error, catch it and re
	                      try {
	                         tempHistory.action = 'Deleted ' + Date.valueOf(historyLine.get('oldValue')).format() + ' in <b>' + fieldLabel + '</b>.';
	                    } catch (Exception e){
	                         tempHistory.action = 'Deleted ' + String.valueOf(historyLine.get('oldValue')) + ' in <b>' + fieldLabel + '</b>.';
	                    }
	                  }
	                  else{  // all other scenarios
	                    String fromText = '';
	                    if (historyLine.get('oldValue') != null) {
	                         try {
	                              fromText = ' from ' + Date.valueOf(historyLine.get('oldValue')).format();
	                         } catch (Exception e) {
	                              fromText = ' from ' + String.valueOf(historyLine.get('oldValue'));
	                         }
	                    }
	                    
	                    SObjectType fromsObjectType;
	                    
	                    String toText = '';
	                    if (historyLine.get('newValue') != null) {
	                        try {
	                             toText = Date.valueOf(historyLine.get('newValue')).format();
	                        } catch (Exception e) {
	                             toText = String.valueOf(historyLine.get('newValue'));
	                        }
	                    }
	                    if (toText != ''){
	                        tempHistory.action = 'Changed <b>' + fieldLabel + '</b>' + fromText + ' to <b>' + toText + '</b>.';
	                    }
	                    else {
	                        tempHistory.action = 'Changed <b>' + fieldLabel;
	                    }
	                   }
	                   rowCount++;
	                   // Add to the list
	                   objectHistory.add(tempHistory);
	            }
	         }
        }
         
         List<Id> userIdList = new List<Id>();
         for (objectHistoryLine myHistory : objectHistory){
             userIdList.add(myHistory.userId);
         }
         Map<Id, User> userIdMap = new Map<ID, User>([SELECT Name FROM User WHERE Id IN : userIdList]);
         
         for (objectHistoryLine myHistory : objectHistory){
             if (userIdMap.containsKey(myHistory.userId) & (myHistory.who != '') ){
                 myHistory.who = userIdMap.get(myHistory.who).Name;
             }
         }
         
         return objectHistory;
    }    
    
    public PageReference refreshObjectHistory(){
    	updatedRecordLimit = updatedRecordLimit + recordLimit;
    	getObjectHistory();
    	return null;
    }
    
    // Function to return Field Label of a object field given a Field API name
    public Static String returnFieldLabel(String fieldName){
		fieldName = fieldName.replace('P2Express__','');
        if (GenericHistoryComponentController.myObjectFieldMap.containsKey(fieldName)){
            return GenericHistoryComponentController.myObjectFieldMap.get(fieldName).getDescribe().getLabel();
        }
        else {
            for(Schema.PicklistEntry pickList : historyFieldPicklistValues){
                if (pickList.getValue() == fieldName){
                    if (pickList.getLabel() != null){
                        return pickList.getLabel();
                    }
                    else {
                        return pickList.getValue();
                    }
                }
            }
        }
        return '';
    }
    
    // Inner Class to store the detail of the object history lines    
    public class objectHistoryLine {

        public String theDate {get; set;}
        public String who {get; set;}
        public Id userId {get; set;} 
        public String action {get; set;}
    }
    
    
	  @isTest static void myTestGenericHistoryComponentController() {
	        
	        //Unit test by: Mike Katulka @ www.itedgecrm.com - mike@itedgecrm.com
	        //Component by: http://boards.developerforce.com/t5/Visualforce-Development/History-related-List-using-Visualforce/t...
	        //83% coverage
	        
	        //***Instructions MUST READ***
	        //We cannot generate History from a unit test, and unable to manually insert records into the History tables from code.  This seems to be a limitation of Salesforce unit testing.
	        //Created for Winter 12 org testing, updated to work with v24 API (SeeAllData=true)
	        //Steps:
	        // 1. Enable History Tracking for Account.
	        // 2. You will need to declaratively make changes to an existing Account.  
	        // 3. Create history in Sandbox and Production.
	        // 4. Then run this test/deploy.
	        // This test will look at the existing history in your org, and operate off of it.  
	        
	        //create controller
			GenericHistoryComponentController controller = new GenericHistoryComponentController();
			//null myObject
			system.assert(controller.getObjectHistory().size() == 0);
	
	        //Account allows for history in related lists in visualforce, this is simply a standard object being used to get code coverage so you can use the component for other custom and standard objects.
	        system.assert([select Accountid from accounthistory where isdeleted=false limit 1].size() == 1); //limit in case of 50,000 record governor limit
	        string accid = [select Accountid from accounthistory where isdeleted=false limit 1].accountid;
	        
			//Set myObject
			controller.myObject = [select id from Account where id=:accid];				
	        system.assert(controller.getObjectHistory().size() > 0);        
	  }
}