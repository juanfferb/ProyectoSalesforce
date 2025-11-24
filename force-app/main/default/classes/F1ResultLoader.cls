public with sharing class F1ResultLoader {
    public static void loadResults() {
        try {
            String endpoint = 'f1/2025/results.json'; // URL para resultados
            String jsonResponse = ErgastAPI.getF1Data(endpoint);

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            if (!root.containsKey('MRData')) return;

            Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
            Object raceTableObj = mrData.get('RaceTable');
            if (!(raceTableObj instanceof Map<String, Object>)) return;

            Map<String, Object> raceTable = (Map<String, Object>) raceTableObj;
            List<Object> races = (List<Object>) raceTable.get('Races');
            if (races == null || races.isEmpty()) return;

            // Cargar Race, Driver y Constructor en mapas para evitar consultas repetitivas
            Map<String, Id> raceMap = new Map<String, Id>();
            for (Race__c r : [SELECT Id, RaceId__c FROM Race__c]) {
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

            List<Result__c> resultsToUpsert = new List<Result__c>();

            for (Object raceObj : races) {
                Map<String, Object> raceData = (Map<String, Object>) raceObj;
                String season = (String) raceData.get('season');
                String round = (String) raceData.get('round');
                String raceKey = season + '-' + round;

                List<Object> results = (List<Object>) raceData.get('Results');
                if (results == null || results.isEmpty()) continue;

                for (Object resultObj : results) {
                    Map<String, Object> resultData = (Map<String, Object>) resultObj;

                    // Datos del piloto y constructor
                    Map<String, Object> driverData = (Map<String, Object>) resultData.get('Driver');
                    Map<String, Object> constructorData = (Map<String, Object>) resultData.get('Constructor');

                    String driverId = (String) driverData.get('driverId');
                    String constructorId = (String) constructorData.get('constructorId');

                    Result__c resultRecord = new Result__c();
                    resultRecord.Name = raceData.get('raceName') + ' - ' + driverData.get('familyName');
                    resultRecord.ResultId__c = raceKey + '-' + driverId; // External ID

                    // Campos principales
                    resultRecord.Position__c = Integer.valueOf((String) resultData.get('position'));
                    resultRecord.PositionText__c = (String) resultData.get('positionText');
                    resultRecord.Points__c = Decimal.valueOf((String) resultData.get('points'));
                    resultRecord.Grid__c = (String) resultData.get('grid');
                    resultRecord.Laps__c = Integer.valueOf((String) resultData.get('laps'));
                    resultRecord.Status__c = (String) resultData.get('status');
                    resultRecord.Number__c = Integer.valueOf((String) resultData.get('number'));

                    // Tiempo
                    if (resultData.containsKey('Time')) {
                        Map<String, Object> timeData = (Map<String, Object>) resultData.get('Time');
                        if (timeData.containsKey('millis')) {
                            resultRecord.TimeMillis__c = (String) timeData.get('millis');
                        }
                        resultRecord.Time__c = (String) timeData.get('time');
                    }

                    // Vuelta rápida
                    if (resultData.containsKey('FastestLap')) {
                        Map<String, Object> fastestLap = (Map<String, Object>) resultData.get('FastestLap');
                        resultRecord.FastestLapRank__c = (String) fastestLap.get('rank');
                        Map<String, Object> fastestLapTime = (Map<String, Object>) fastestLap.get('Time');
                        resultRecord.FastestLapTime__c = (String) fastestLapTime.get('time');
                    }

                    // Relaciones Lookup
                    if (raceMap.containsKey(raceKey)) {
                        resultRecord.Race__c = raceMap.get(raceKey);
                    }
                    if (driverMap.containsKey(driverId)) {
                        resultRecord.Driver__c = driverMap.get(driverId);
                    }
                    if (constructorMap.containsKey(constructorId)) {
                        resultRecord.Constructor__c = constructorMap.get(constructorId);
                    }

                    resultsToUpsert.add(resultRecord);
                }
            }

            // Upsert usando External ID ResultId__c
            upsert resultsToUpsert ResultId__c;

            System.debug('Resultados procesados: ' + resultsToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadResults: ' + e.getMessage());
        }
    }
}
