
public with sharing class F1QualifyingLoader {
    public static void loadQualifyingResults() {
        try {
            String endpoint = 'f1/2025/qualifying.json';
            String jsonResponse = ErgastAPI.getF1Data(endpoint);

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            if (!root.containsKey('MRData')) return;

            Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
            Object raceTableObj = mrData.get('RaceTable');
            if (!(raceTableObj instanceof Map<String, Object>)) return;

            Map<String, Object> raceTable = (Map<String, Object>) raceTableObj;
            List<Object> races = (List<Object>) raceTable.get('Races');
            if (races == null || races.isEmpty()) return;

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

            List<Qualifying__c> qualifyingResultsToUpsert = new List<Qualifying__c>();

            for (Object raceObj : races) {
                Map<String, Object> raceData = (Map<String, Object>) raceObj;
                String season = (String) raceData.get('season');
                String round = (String) raceData.get('round');
                String raceKey = season + '-' + round;

                List<Object> qualifyingResults = (List<Object>) raceData.get('QualifyingResults');
                if (qualifyingResults == null || qualifyingResults.isEmpty()) continue;

                for (Object qualObj : qualifyingResults) {
                    Map<String, Object> qualData = (Map<String, Object>) qualObj;
                    Map<String, Object> driverData = (Map<String, Object>) qualData.get('Driver');
                    Map<String, Object> constructorData = (Map<String, Object>) qualData.get('Constructor');

                    String driverId = (String) driverData.get('driverId');
                    String constructorId = (String) constructorData.get('constructorId');

                    Qualifying__c qualRecord = new Qualifying__c();
                    qualRecord.QualifyingId__c = raceKey + '-' + driverId; // External ID
                    qualRecord.Name = 'Qualifying - ' + driverData.get('familyName');

                    qualRecord.Position__c = Integer.valueOf((String) qualData.get('position'));
                    qualRecord.Q1__c = (String) qualData.get('Q1');
                    qualRecord.Q2__c = (String) qualData.get('Q2');
                    qualRecord.Q3__c = (String) qualData.get('Q3');

                    if (raceMap.containsKey(raceKey)) qualRecord.Race__c = raceMap.get(raceKey);
                    if (driverMap.containsKey(driverId)) qualRecord.Driver__c = driverMap.get(driverId);
                    if (constructorMap.containsKey(constructorId)) qualRecord.Constructor__c = constructorMap.get(constructorId);

                    qualifyingResultsToUpsert.add(qualRecord);
                }
            }

            upsert qualifyingResultsToUpsert QualifyingId__c;
            System.debug('Qualifying Results procesados: ' + qualifyingResultsToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadQualifyingResults: ' + e.getMessage());
        }
    }
}
