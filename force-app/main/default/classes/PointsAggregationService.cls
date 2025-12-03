public with sharing class PointsAggregationService {

    /**
     * Recalcula los puntos de Drivers y Constructors
     * usando la suma de Result__c.Points__c + Sprint__c.Points__c
     */
    public static void recalculatePointsForDriversAndConstructors(
        Set<Id> driverIds,
        Set<Id> constructorIds
    ) {
        if ((driverIds == null || driverIds.isEmpty()) &&
            (constructorIds == null || constructorIds.isEmpty())) {
            return;
        }

        if (driverIds != null && !driverIds.isEmpty()) {
            Map<Id, Decimal> driverPointsMap = new Map<Id, Decimal>();

            // Puntos de Result__c
            for (AggregateResult ar : [
                SELECT Driver__c drvId, SUM(Points__c) totalPoints
                FROM Result__c
                WHERE Driver__c IN :driverIds
                GROUP BY Driver__c
            ]) {
                Id drvId = (Id) ar.get('drvId');
                Decimal pts = (Decimal) (ar.get('totalPoints') == null
                    ? 0
                    : ar.get('totalPoints'));
                driverPointsMap.put(drvId, pts);
            }

            // Puntos de Sprint__c
            for (AggregateResult ar : [
                SELECT Driver__c drvId, SUM(Points__c) totalPoints
                FROM Sprint__c
                WHERE Driver__c IN :driverIds
                GROUP BY Driver__c
            ]) {
                Id drvId = (Id) ar.get('drvId');
                Decimal pts = (Decimal) (ar.get('totalPoints') == null
                    ? 0
                    : ar.get('totalPoints'));

                // sumamos a lo que ya teníamos de Result__c
                if (driverPointsMap.containsKey(drvId)) {
                    driverPointsMap.put(drvId, driverPointsMap.get(drvId) + pts);
                } else {
                    driverPointsMap.put(drvId, pts);
                }
            }

            // Actualizar Drivers
            List<Driver__c> driversToUpdate = new List<Driver__c>();
            for (Id drvId : driverIds) {
                Decimal total = driverPointsMap.containsKey(drvId)
                    ? driverPointsMap.get(drvId)
                    : 0;
                driversToUpdate.add(new Driver__c(
                    Id       = drvId,
                    Points__c = total
                ));
            }

            if (!driversToUpdate.isEmpty()) {
                update driversToUpdate;
            }
        }

        if (constructorIds != null && !constructorIds.isEmpty()) {
            Map<Id, Decimal> consPointsMap = new Map<Id, Decimal>();

            // Puntos de Result__c
            for (AggregateResult ar : [
                SELECT Constructor__c consId, SUM(Points__c) totalPoints
                FROM Result__c
                WHERE Constructor__c IN :constructorIds
                GROUP BY Constructor__c
            ]) {
                Id consId = (Id) ar.get('consId');
                Decimal pts = (Decimal) (ar.get('totalPoints') == null
                    ? 0
                    : ar.get('totalPoints'));
                consPointsMap.put(consId, pts);
            }

            // Puntos de Sprint__c
            for (AggregateResult ar : [
                SELECT Constructor__c consId, SUM(Points__c) totalPoints
                FROM Sprint__c
                WHERE Constructor__c IN :constructorIds
                GROUP BY Constructor__c
            ]) {
                Id consId = (Id) ar.get('consId');
                Decimal pts = (Decimal) (ar.get('totalPoints') == null
                    ? 0
                    : ar.get('totalPoints'));

                if (consPointsMap.containsKey(consId)) {
                    consPointsMap.put(consId, consPointsMap.get(consId) + pts);
                } else {
                    consPointsMap.put(consId, pts);
                }
            }

            // Actualizar Constructors
            List<Constructor__c> constructorsToUpdate = new List<Constructor__c>();
            for (Id consId : constructorIds) {
                Decimal total = consPointsMap.containsKey(consId)
                    ? consPointsMap.get(consId)
                    : 0;
                constructorsToUpdate.add(new Constructor__c(
                    Id       = consId,
                    Points__c = total
                ));
            }

            if (!constructorsToUpdate.isEmpty()) {
                update constructorsToUpdate;
            }
        }
    }
}