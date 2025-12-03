public with sharing class DriverStatsService {

    public static void recalcDrivers(Set<Id> driverIds) {
        if (driverIds == null || driverIds.isEmpty()) {
            return;
        }

        // Acumuladores
        Map<Id, Decimal> racePoints = new Map<Id, Decimal>();
        Map<Id, Integer> raceWins   = new Map<Id, Integer>();

        Map<Id, Decimal> sprintPoints = new Map<Id, Decimal>();
        Map<Id, Integer> sprintWins   = new Map<Id, Integer>();

        // 1) Resultados de carrera
        for (Result__c r : [
            SELECT Driver__c, Points__c, Position__c
            FROM Result__c
            WHERE Driver__c IN :driverIds
        ]) {
            if (r.Driver__c == null) continue;

            Id dId = r.Driver__c;
            Decimal pts = (r.Points__c == null) ? 0 : r.Points__c;

            racePoints.put(dId, (racePoints.containsKey(dId) ? racePoints.get(dId) : 0) + pts);

            if (r.Position__c == 1) {
                raceWins.put(dId, (raceWins.containsKey(dId) ? raceWins.get(dId) : 0) + 1);
            }
        }

        // 2) Resultados de sprint
        for (Sprint__c s : [
            SELECT Driver__c, Points__c, Position__c
            FROM Sprint__c
            WHERE Driver__c IN :driverIds
        ]) {
            if (s.Driver__c == null) continue;

            Id dId = s.Driver__c;
            Decimal pts = (s.Points__c == null) ? 0 : s.Points__c;

            sprintPoints.put(dId, (sprintPoints.containsKey(dId) ? sprintPoints.get(dId) : 0) + pts);

            if (s.Position__c == 1) {
                sprintWins.put(dId, (sprintWins.containsKey(dId) ? sprintWins.get(dId) : 0) + 1);
            }
        }

        // 3) Actualizar pilotos
        List<Driver__c> driversToUpdate = new List<Driver__c>();

        for (Id dId : driverIds) {
            Decimal totalPoints = 0;
            Integer totalWins   = 0;

            if (racePoints.containsKey(dId))   totalPoints += racePoints.get(dId);
            if (sprintPoints.containsKey(dId)) totalPoints += sprintPoints.get(dId);

            if (raceWins.containsKey(dId))     totalWins   += raceWins.get(dId);
            if (sprintWins.containsKey(dId))   totalWins   += sprintWins.get(dId);

            driversToUpdate.add(new Driver__c(
                Id       = dId,
                Points__c = totalPoints,
                Wins__c   = totalWins
            ));
        }

        if (!driversToUpdate.isEmpty()) {
            update driversToUpdate;
        }
    }
}