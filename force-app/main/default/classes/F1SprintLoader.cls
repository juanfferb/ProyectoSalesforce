public with sharing class F1SprintLoader {
    public static void loadSprintResults() {
        try {
            Integer offset = 0;
            Integer pageLimit = 30; // Ajusta según la API
            Boolean moreData = true;

            List<Sprint__c> sprintResultsToUpsert = new List<Sprint__c>();

            // Mapas para relaciones (se cargan una sola vez)
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

            while (moreData) {
                String endpoint = 'f1/2025/sprint.json?limit=' + pageLimit + '&offset=' + offset;
                String jsonResponse = ErgastAPI.getF1Data(endpoint);

                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                if (!root.containsKey('MRData')) break;

                Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
                Object raceTableObj = mrData.get('RaceTable');
                if (!(raceTableObj instanceof Map<String, Object>)) break;

                Map<String, Object> raceTable = (Map<String, Object>) raceTableObj;
                List<Object> races = (List<Object>) raceTable.get('Races');

                if (races == null || races.isEmpty()) {
                    moreData = false;
                    break;
                }

                for (Object raceObj : races) {
                    Map<String, Object> raceData = (Map<String, Object>) raceObj;
                    String season = (String) raceData.get('season');
                    String round = (String) raceData.get('round');
                    String raceKey = season + '-' + round;

                    List<Object> sprintResults = (List<Object>) raceData.get('SprintResults');
                    if (sprintResults == null || sprintResults.isEmpty()) continue;

                    for (Object sprintObj : sprintResults) {
                        Map<String, Object> sprintData = (Map<String, Object>) sprintObj;
                        Map<String, Object> driverData = (Map<String, Object>) sprintData.get('Driver');
                        Map<String, Object> constructorData = (Map<String, Object>) sprintData.get('Constructor');

                        String driverId = (String) driverData.get('driverId');
                        String constructorId = (String) constructorData.get('constructorId');

                        Sprint__c sprintRecord = new Sprint__c();
                        sprintRecord.SprintId__c = raceKey + '-' + driverId; // External ID
                        sprintRecord.Name = 'Sprint - ' + driverData.get('familyName');

                        sprintRecord.Position__c = Integer.valueOf((String) sprintData.get('position'));
                        sprintRecord.PositionText__c = (String) sprintData.get('positionText');
                        sprintRecord.Points__c = Decimal.valueOf((String) sprintData.get('points'));
                        sprintRecord.Grid__c = Integer.valueOf((String) sprintData.get('grid'));
                        sprintRecord.Laps__c = (String) sprintData.get('laps');
                        sprintRecord.Status__c = (String) sprintData.get('status');

                        if (sprintData.containsKey('Time')) {
                            Map<String, Object> timeData = (Map<String, Object>) sprintData.get('Time');
                            if (timeData.containsKey('millis')) {
                                sprintRecord.TimeMillis__c = (String) timeData.get('millis');
                            }
                            sprintRecord.TimeText__c = (String) timeData.get('time');
                        }

                        if (sprintData.containsKey('FastestLap')) {
                            Map<String, Object> fastestLap = (Map<String, Object>) sprintData.get('FastestLap');
                            sprintRecord.FastestLapRank__c = (String) fastestLap.get('rank');
                            Map<String, Object> fastestLapTime = (Map<String, Object>) fastestLap.get('Time');
                            sprintRecord.FastestLapTime__c = (String) fastestLapTime.get('time');
                        }

                        if (raceMap.containsKey(raceKey)) sprintRecord.Race__c = raceMap.get(raceKey);
                        if (driverMap.containsKey(driverId)) sprintRecord.Driver__c = driverMap.get(driverId);
                        if (constructorMap.containsKey(constructorId)) sprintRecord.Constructor__c = constructorMap.get(constructorId);

                        sprintResultsToUpsert.add(sprintRecord);
                    }
                }

                offset += pageLimit; // Avanzar a la siguiente página
            }

            upsert sprintResultsToUpsert SprintId__c;
            System.debug('Sprint Results procesados: ' + sprintResultsToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadSprintResults: ' + e.getMessage());
        }
    }
}