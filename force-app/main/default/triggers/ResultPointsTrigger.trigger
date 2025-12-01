trigger ResultPointsTrigger on Result__c (
    after insert, after update, after delete, after undelete
) {
    Set<Id> driverIds      = new Set<Id>();
    Set<Id> constructorIds = new Set<Id>();

    // Registros nuevos / actualizados / reinsertados
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

    // Registros eliminados
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

    // Si no hay nada que actualizar, salimos
    if (driverIds.isEmpty() && constructorIds.isEmpty()) {
        return;
    }

    // =======================
    //  DRIVER POINTS
    // =======================
    if (!driverIds.isEmpty()) {
        Map<Id, Decimal> driverPointsMap = new Map<Id, Decimal>();

        AggregateResult[] driverAgg = [
            SELECT Driver__c drvId,
                   SUM(Points__c) totalPoints
            FROM Result__c
            WHERE Driver__c IN :driverIds
            GROUP BY Driver__c
        ];

        for (AggregateResult ar : driverAgg) {
            Id drvId = (Id) ar.get('drvId');
            Decimal pts = (Decimal) (ar.get('totalPoints') == null ? 0 : ar.get('totalPoints'));
            driverPointsMap.put(drvId, pts);
        }

        List<Driver__c> driversToUpdate = new List<Driver__c>();
        for (Id drvId : driverIds) {
            Decimal pts = driverPointsMap.containsKey(drvId) ? driverPointsMap.get(drvId) : 0;
            driversToUpdate.add(new Driver__c(
                Id       = drvId,
                Points__c = pts
            ));
        }

        if (!driversToUpdate.isEmpty()) {
            update driversToUpdate;
        }
    }

    // =======================
    //  CONSTRUCTOR POINTS
    // =======================
    if (!constructorIds.isEmpty()) {
        Map<Id, Decimal> constructorPointsMap = new Map<Id, Decimal>();

        AggregateResult[] consAgg = [
            SELECT Constructor__c consId,
                   SUM(Points__c) totalPoints
            FROM Result__c
            WHERE Constructor__c IN :constructorIds
            GROUP BY Constructor__c
        ];

        for (AggregateResult ar : consAgg) {
            Id consId = (Id) ar.get('consId');
            Decimal pts = (Decimal) (ar.get('totalPoints') == null ? 0 : ar.get('totalPoints'));
            constructorPointsMap.put(consId, pts);
        }

        List<Constructor__c> constructorsToUpdate = new List<Constructor__c>();
        for (Id consId : constructorIds) {
            Decimal pts = constructorPointsMap.containsKey(consId) ? constructorPointsMap.get(consId) : 0;
            constructorsToUpdate.add(new Constructor__c(
                Id       = consId,
                Points__c = pts
            ));
        }

        if (!constructorsToUpdate.isEmpty()) {
            update constructorsToUpdate;
        }
    }
}