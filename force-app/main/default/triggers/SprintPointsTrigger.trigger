trigger SprintPointsTrigger on Sprint__c (
    after insert, after update, after delete, after undelete
) {
    Set<Id> driverIds      = new Set<Id>();
    Set<Id> constructorIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Sprint__c s : Trigger.new) {
            if (s.Driver__c != null) {
                driverIds.add(s.Driver__c);
            }
            if (s.Constructor__c != null) {
                constructorIds.add(s.Constructor__c);
            }
        }
    }
    if (Trigger.isDelete) {
        for (Sprint__c s : Trigger.old) {
            if (s.Driver__c != null) {
                driverIds.add(s.Driver__c);
            }
            if (s.Constructor__c != null) {
                constructorIds.add(s.Constructor__c);
            }
        }
    }

    PointsAggregationService.recalculatePointsForDriversAndConstructors(
        driverIds,
        constructorIds
    );
}