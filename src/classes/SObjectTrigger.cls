public abstract with sharing class SObjectTrigger implements TriggerHandler.IHandlerInterface, Database.Batchable<SObject> {
	
	public static Boolean disableTrigger = false;
	private Schema.SObjectType sObjectType;
	private Set<String> fieldSet;

	public SObjectTrigger() {}

	public virtual Boolean getIsToProcess(SObject oldRecord, SObject newRecord) {
		return true;
	}

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

	public void handle(Schema.SObjectType sObjectType) {

		if (disableTrigger == true) return;

		SObject[] toProcess = new SObject[]{};

		if (trigger.isInsert) {
			for (SObject record : trigger.new) {
				if (getIsToProcess(sObjectType.newSObject(), record)) {
					toProcess.add(record);
				}
			}
		} else if (trigger.isUpdate) {
			for (SObject record : trigger.new) {
				if (getIsToProcess(trigger.oldMap.get(record.Id), record)) {
					toProcess.add(record);
				}
			}
		} else if (trigger.isDelete) {
			for (SObject record : trigger.old) {
				if (getIsToProcess(record, sObjectType.newSObject())) {
					toProcess.add(record);
				}
			}
		}

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