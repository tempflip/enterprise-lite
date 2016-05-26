public with sharing class SObjectHelper {
	public SObjectHelper() {}

	public static Map<Id, SObject[]> mapSOQLByField(SObject[] sObjectList, Schema.SObjectField field) {
		Map<Id, SObject[]> sobjectMap = new Map<Id, SObject[]>();
		
		String fieldName = field.getDescribe().getName();
		for (SObject record : sObjectList) {
			if (record.get(fieldName) == null) continue;

			if (!sobjectMap.containsKey((Id) record.get(fieldName))) {
				sobjectMap.put((Id)record.get(fieldName), new SObject[]{});
			}
			sobjectMap.get((Id)record.get(fieldName)).add(record);
		}

		return sobjectMap;
	}

	public static Set<Id> getIdSet(SObject[] sObjectList, Schema.SObjectField field) {
		Set<Id> idSet = new Set<Id>();

		String fieldName = field.getDescribe().getName();
		for (SObject record : sObjectList) {
			if (record.get(fieldName) == null) continue;

			idSet.add((Id) record.get(fieldName));
		}
		return idSet;
	}
}