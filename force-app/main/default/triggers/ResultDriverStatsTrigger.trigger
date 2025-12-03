trigger ResultDriverStatsTrigger on Result__c (
    after insert, after update, after delete, after undelete
) {
    Set<Id> driverIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Result__c r : Trigger.new) {
            if (r.Driver__c != null) driverIds.add(r.Driver__c);
        }
    }

    if (Trigger.isDelete) {
        for (Result__c r : Trigger.old) {
            if (r.Driver__c != null) driverIds.add(r.Driver__c);
        }
    }

    DriverStatsService.recalcDrivers(driverIds);
}