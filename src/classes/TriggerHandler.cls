/**
 * @description All triggers are routed to this class. No trigger logic should be done bypassing it (without a very serious reason)
 * See an example of routing at manage() method
 *
 */
public with sharing class TriggerHandler {
	//Stripe_Settings__c settings = Stripe_Settings__c.getOrgDefaults();
	public Schema.sObjectType sObjectType;

	/**
	 * @description If you set this static property to true, NO trigger logic will be fired.
	 */
	public static Boolean disableAll = false;

	/**
	 * @description Creates an instance which immediately runs on a trigger. See example on manage()
	 * @param sObjectType Type of the SObject which trigger is handled
	 */
	public TriggerHandler(Schema.sObjectType sObjectType) {
		this.sObjectType = sObjectType;
		construct();
	}

	/*
	 * Interface for classes which are called in trigger context.
	 * On selected events the handle method is called
	 */
	public interface IHandlerInterface {
		void handle(Schema.SObjectType sObjectType);
	}

	/**
	 *   Enum representing each of before/after CRUD events on Sobjects
	 */
	public enum Evt {
		afterdelete, afterinsert, afterundelete, afterupdate, beforedelete, beforeinsert, beforeupdate
	}

	/*
	 *   Simplistic handler to implement on any of the event. It doesn't require or enforces any pattern except the
	 *   method name to be "handle()".
	 */
	Map<Schema.SObjectType, Map<TriggerHandler.Evt, IHandlerInterface[]>> eventHandlerMapping2 = new map<Schema.SObjectType, Map<TriggerHandler.Evt, IHandlerInterface[]>>();

	/*
	 * Centralized method to bind all the classes to the selected objects/events
	 *
	 */

	/**
	* @description This is the main method to bind your trigger classes to SOQL Object events 
	* See examples at bind() method
	*/
	private void construct() {
		//if (settings.Disable_All_Triggers__c == true || disableAll) {
		//	return;
		//}

		if (this.sObjectType == Account.sObjectType) {
		
		} else if (this.sObjectType == Contact.sObjectType) {

		}
	}


	/**
	 * @description Core API to bind handlers with events. You are using this method in the construct() method.
	 * @param sObjectType Type of the object to bind the class
	 * @param event The event -- see list of available 'Evt' types
	 * @param eh An instance of event handler class. This can be any class which implements the 
	 * IHandlerInterface interface
	 * @example 
	 * bind(Account.sObjectType, evt.beforeinsert, new Account_Validate());
	 * // This binds an instance of Account_Validate class 
	 * // to every 'before insert' event on Account object
	 */
	public void bind(Schema.SObjectType sObjectType, Evt event, IHandlerInterface eh) {
		if (!eventHandlerMapping2.containsKey(sObjectType)) {
			eventHandlerMapping2.put(sObjectType, new Map<TriggerHandler.Evt, IHandlerInterface[]>());
		}
		if (!eventHandlerMapping2.get(sObjectType).containsKey(event)) {
			eventHandlerMapping2.get(sObjectType).put(event, new IHandlerInterface[]{});
		}
		// setting the sObjectType on the trigger instance
		eventHandlerMapping2.get(sObjectType).get(event).add(eh);
	}


	/**
	* @description Invokes correct handlers as per the context of Trigger and available registered handlers.
	* This method should be called on the trigger.
	* @example trigger Trans_Gen on Transaction__c (.....) {
	* new TriggerHandler(Transaction__c.SObjectType).manage();
	* }
	* On your trigger you are creating a new instance of trigger handler (passing the object type), and immediately 
	* starting the manage() method. It will automatically start the bound trigger classes to the given SOQL/event.
	* See: bind() method
	*/
	public void manage() {
		Evt ev = null;
		if (Trigger.isInsert && Trigger.isBefore) {
			ev = Evt.beforeinsert;
		} else if (Trigger.isInsert && Trigger.isAfter) {
			ev = Evt.afterinsert;
		} else if (Trigger.isUpdate && Trigger.isBefore) {
			ev = Evt.beforeupdate;
		} else if (Trigger.isUpdate && Trigger.isAfter) {
			ev = Evt.afterupdate;
		} else if (Trigger.isDelete && Trigger.isBefore) {
			ev = Evt.beforedelete;
		} else if (Trigger.isDelete && Trigger.isAfter) {
			ev = Evt.afterdelete;
		} else if (Trigger.isundelete) {
			ev = Evt.afterundelete;
		}

		if (eventHandlerMapping2.get(sObjectType) != null) {
			IHandlerInterface[] handlers2 = eventHandlerMapping2.get(sObjectType).get(ev);
			if (handlers2 != null && handlers2.size() > 0) {
				for (IHandlerInterface h : handlers2) {
		            system.debug('**** TRIGGERHANDLER RUNNING ON OBJECT: ' + sObjectType + ' *** CLASS: ' + h);
					h.handle(sObjectType);
				}
			}
		}
	}
}
