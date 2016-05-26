# Enterprise LITE - a micro-framework for APEX

This is a lightweight framework which makes your APEX code more readable and more structured. Currently it is used in unmanaged packages, however it can be implemented in managed packages, too.

## TriggerHandler

Centralizing your trigger fired business logic is a good practice. Use one trigger per object, and forward the delegate the execution to the TriggerHandler.
```
trigger Attendee_Handler on bt_events__Attendee__c (
    before insert, 
    after insert, 
    before delete, 
    after delete, 
    before update, 
    after update) {
	    new TriggerHandler(bt_events__Attendee__c.sObjectType).manage();
}
```

#### Define Events
TriggerHandler.cls is a pre-defined class, which is responsible for calling the logic on trigger events. In its `construct` method you are binding trigger classes to events and objects. For example,

```
    private void construct() {
        bind(bt_events__Attendee__c.sObjectType, evt.beforeinsert, new Attendee_PopulateParent());
        bind(Contact.sObjectType, Evt.afterinsert, new Contact_CopyParentPhone());
    }
```
here we are binding a trigger classes to `bt_events__Attendee__c` object on a `beforeinsert` event, and another class to the `Contact` object on the `afterevent` database event.

#### TriggerHandler.IHandlerInterface

Any class can be bound to a trigger event. The only requirement is to implement a common interface.
````
    public interface IHandlerInterface {
        void handle(Schema.SObjectType sObjectType);  
    } 
````

The `handle()` method is called by the TriggerHandler class every time, when an event is bound to an object.

You can run your trigger logic from the `handle()` method or you can extend the `SObjectTrigger` class.

## SObjectTrigger class
The purpose of this class is to standardize the trigger logic. The class implements the `IHandlerInterface` interface, so you can bind this class' children directly to events in the `TriggerHandler`.

The class has 2 methods to override:
```
	public virtual Boolean getIsToProcess(SObject oldRecord, SObject newRecord) {
		return true;
	}

	public abstract void executeTrigger(SObject[] sObjectList);
```

`executeTrigger` method is called with the list of records to process by the trigger logic, so this is the place to implement business logic for a given object. For example, if the class is bound to `Contact` object, it is called with a list of Contacts.

`getIsToProcess` method is used to filter the list of records to process. For example, if we want to fire a trigger logic ONLY if a Contact Email has been changed, we can implement this logic the following way:

```
	public override Boolean getIsToProcess(SObject oldRecord, SObject newRecord) {
		return oldRecord.get('Email') != newRecord.get('Email');
	}

	public override void executeTrigger(SObject[] sObjectList) {
	}
```

The filtering method has 2 parameters -- `oldRecord` is the old state of the record, `newRecord` is the updated one. Please note that in an `insert` context the `oldRecord` parameter is `null`, while in `delete` context the `newRecord` is `null`.

The `sObjectList` which is passed to the `executeTrigger` is constructed from the `trigger.new` list, but on `delete` event it has records from the `trigger.old` list.

