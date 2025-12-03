trigger SprintDriverStatsTrigger on Sprint__c (
    after insert, after update, after delete, after undelete
) {
    Set<Id> driverIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Sprint__c s : Trigger.new) {
            if (s.Driver__c != null) driverIds.add(s.Driver__c);
        }
    }

    if (Trigger.isDelete) {
        for (Sprint__c s : Trigger.old) {
            if (s.Driver__c != null) driverIds.add(s.Driver__c);
        }
    }

    DriverStatsService.recalcDrivers(driverIds);
}