trigger ResultPointsTrigger on Result__c (
    after insert, after update, after delete, after undelete
) {
    Set<Id> driverIds      = new Set<Id>();
    Set<Id> constructorIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Result__c r : Trigger.new) {
            if (r.Driver__c != null) {
                driverIds.add(r.Driver__c);
            }
            if (r.Constructor__c != null) {
                constructorIds.add(r.Constructor__c);
            }
        }
    }
    if (Trigger.isDelete) {
        for (Result__c r : Trigger.old) {
            if (r.Driver__c != null) {
                driverIds.add(r.Driver__c);
            }
            if (r.Constructor__c != null) {
                constructorIds.add(r.Constructor__c);
            }
        }
    }

    PointsAggregationService.recalculatePointsForDriversAndConstructors(
        driverIds,
        constructorIds
    );
}