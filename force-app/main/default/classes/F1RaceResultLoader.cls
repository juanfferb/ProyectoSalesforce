public with sharing class F1RaceResultLoader {
    @AuraEnabled
    public static String loadRaceResults(String raceId) {
        try {
            // raceId formato: season-round
            List<String> parts = raceId.split('-');
            if (parts.size() != 2) return 'Formato inválido de RaceId';
            String season = parts[0];
            String round = parts[1];

            // Mapas
            Map<String, Id> raceMap = new Map<String, Id>();
            for (Race__c r : [SELECT Id, RaceId__c FROM Race__c WHERE RaceId__c = :raceId]) {
                raceMap.put(r.RaceId__c, r.Id);
            }

            Map<String, Id> driverMap = new Map<String, Id>();
            for (Driver__c d : [SELECT Id, DriverId__c FROM Driver__c]) {
                driverMap.put(d.DriverId__c, d.Id);
            }

            Map<String, Id> constructorMap = new Map<String, Id>();
            for (Constructor__c c : [SELECT Id, Constructor_Code__c FROM Constructor__c]) {
                constructorMap.put(c.Constructor_Code__c, c.Id);
            }

            // Llamada API
            String endpoint = 'f1/' + season + '/' + round + '/results.json';
            String jsonResponse = ErgastAPI.getF1Data(endpoint);

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
            Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
            List<Object> races = (List<Object>) raceTable.get('Races');

            if (races == null || races.isEmpty()) return 'No se encontraron resultados.';

            List<Result__c> resultsToUpsert = new List<Result__c>();

            for (Object raceObj : races) {
                Map<String, Object> raceData = (Map<String, Object>) raceObj;
                List<Object> results = (List<Object>) raceData.get('Results');

                for (Object resultObj : results) {
                    Map<String, Object> resultData = (Map<String, Object>) resultObj;
                    Map<String, Object> driverData = (Map<String, Object>) resultData.get('Driver');
                    Map<String, Object> constructorData = (Map<String, Object>) resultData.get('Constructor');

                    String driverId = (String) driverData.get('driverId');
                    String constructorId = (String) constructorData.get('constructorId');

                    Result__c resultRecord = new Result__c();
                    resultRecord.ResultId__c = raceId + '-' + driverId;
                    resultRecord.Name = (String) raceData.get('raceName') + ' - ' + (String) driverData.get('familyName');
                    resultRecord.Position__c = Integer.valueOf((String) resultData.get('position'));
                    resultRecord.Points__c = Decimal.valueOf((String) resultData.get('points'));
                    resultRecord.Laps__c = Integer.valueOf((String) resultData.get('laps'));
                    resultRecord.Status__c = (String) resultData.get('status');

                    if (raceMap.containsKey(raceId)) resultRecord.Race__c = raceMap.get(raceId);
                    if (driverMap.containsKey(driverId)) resultRecord.Driver__c = driverMap.get(driverId);
                    if (constructorMap.containsKey(constructorId)) resultRecord.Constructor__c = constructorMap.get(constructorId);

                    resultsToUpsert.add(resultRecord);
                }
            }

            upsert resultsToUpsert ResultId__c;
            return 'Resultados cargados: ' + resultsToUpsert.size();
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}