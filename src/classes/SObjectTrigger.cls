/**
* A trigger framework which used by most trigger in this package.
* It has 2 purposes
* 1, Figure out which records should be processed when a list (or a single) record is passed
* 2, Creates a batch runnable interface, which is mainly when a newly created trigges should be process
* olready existing records
*
* It implements the TriggerHandler.IHandlerInterface interface, so it should be used in together with the
* TriggerHandler class. The children classes of this class are all TriggerHandler runnable (as they inherit the interface)
*
* See for examples getIsToProcess() and executeTrigger() methods.
*/
public abstract with sharing class SObjectTrigger implements TriggerHandler.IHandlerInterface, Database.Batchable<SObject> {
	
	private Schema.SObjectType sObjectType;
	private Set<String> fieldSet;

	/*
	* @description If this switch is set to true, the trigger runs only once per every record in a context.
	* This might be a solution for re-evaluating triggers after an executed workflow rule.
	*/
	public Boolean runOnlyOncePerRecord = false;
	
	/**
	* @description
	* This is a set for the already processed records per trigger class instance, in this execution context.
	*/
	private static Map<System.Type, Set<Id>> processedRecords = new Map<System.Type, Set<Id>>();

	public SObjectTrigger() {}

	/**
	* @description
	* This method validates every record on the list which are processed by the currently running trigger.
	* If it returns 'true', the given record will be processed. Otherwise not.
	* If you want to process EVERY record regardless any other logic, simple return 'true'
	* @param oldRecord The state of the old version of the object. On insert events it is always an empty SObject, on delete context it is the object value before deleting. On update it is before the update value.
	* @param newRecord The state of the new version of the record. On insert events it is the value of the record, on update it is the updated version. On delete events it has no value (empty SObject).
	*/
	
	public virtual Boolean getIsToProcess(SObject oldRecord, SObject newRecord) {
		return true;
	}

	/**
	* @description This method is called automatically by the handle() method which is called by the TriggerHandler class
	* @param sObjectList List of objects in the trigger context, filtered by getIsToProcess() method
	*/
	public abstract void executeTrigger(SObject[] sObjectList);

	public void setSObjectType(Schema.SObjectType sObjectType) {
		this.sObjectType = sObjectType;
	}

	public void setFieldSet(Set<String> fieldSet) {
		this.fieldSet = fieldSet;
	}

	public void runBatch() {
		Database.executeBatch(this);
	}
	/**
	* @description
	* This is the implementation of the handle() method on IHandlerInterface interface
	* If your trigger handler classes are children of SObjectTrigger, you don't need to create this class,
	* as they inherit it.
	*/
	public void handle(Schema.SObjectType sObjectType) {
		Type myTriggerType = Type.forName(String.valueOf(this).split(':')[0]);
		if (!processedRecords.containsKey(myTriggerType)) {
			processedRecords.put(myTriggerType, new Set<Id>());
		}

		SObject[] toProcess = new SObject[]{};

		if (trigger.isInsert) {
			for (SObject record : trigger.new) {
				if (getIsToProcess(sObjectType.newSObject(), record)) {
					if (!processedRecords.get(myTriggerType).contains(record.Id))
						toProcess.add(record);
				}
			}
		} else if (trigger.isUpdate) {
			for (SObject record : trigger.new) {
				if (getIsToProcess(trigger.oldMap.get(record.Id), record)) {
					if (!processedRecords.get(myTriggerType).contains(record.Id))
						toProcess.add(record);	
				}
			}
		} else if (trigger.isDelete) {
			for (SObject record : trigger.old) {
				if (getIsToProcess(record, sObjectType.newSObject())) {
					if (!processedRecords.get(myTriggerType).contains(record.Id))
						toProcess.add(record);
				}
			}
		}

		// recording the record id's if the trigger should run only once		
		if (this.runOnlyOncePerRecord == true) {
			processedRecords.get(myTriggerType).addAll(new Map<Id, SObject>(toProcess).keySet());
		}

		system.debug(this.runOnlyOncePerRecord + ' ### already processed: ' + processedRecords);

		if (!toProcess.isEmpty()) {
			system.debug('---> executing ' + sObjectType + ' on ' + toProcess);
 			this.executeTrigger(toProcess);
 		} else {
 			system.debug('---> empty ' + sObjectType);
 		}
	}

	// Batchable interface methods
	///////////////////////////////

	// this method sets all the fields, which are going to the query
	// for the batchable run
	//
	// all the fields should be included which are used in the trigger 
	// on the sObjectList parameter

	public virtual Database.QueryLocator start(Database.BatchableContext BC) {	
		String q = 'SELECT ' 
			+ String.join(new List<String>(this.fieldSet), ', ')
			+ ' FROM ' + this.sObjectType.getDescribe().getName()
			;
		return Database.getQueryLocator(q);
	}

	public virtual void execute(Database.BatchableContext BC, SObject[] scope) {
		this.executeTrigger(scope);
	}

	public virtual void finish(Database.BatchableContext BC) {

	}


}