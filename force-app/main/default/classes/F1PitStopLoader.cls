public with sharing class F1PitStopLoader {
    public static void loadPitStops() {
        try {
            Integer offset = 0;
            Integer pageLimit = 30;
            Boolean moreData = true;

            // Mapas para relaciones
            Map<String, Id> raceMap = new Map<String, Id>();
            for (Race__c r : [SELECT Id, RaceId__c FROM Race__c]) {
                raceMap.put(r.RaceId__c, r.Id);
            }

            Map<String, Id> driverMap = new Map<String, Id>();
            for (Driver__c d : [SELECT Id, DriverId__c FROM Driver__c]) {
                driverMap.put(d.DriverId__c, d.Id);
            }

            List<PitStop__c> allPitStops = new List<PitStop__c>();

            while (moreData) {
                String endpoint = 'f1/2025/1/pitstops.json?limit=' + pageLimit + '&offset=' + offset;
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

                    List<Object> pitStops = (List<Object>) raceData.get('PitStops');
                    if (pitStops == null || pitStops.isEmpty()) continue;

                    for (Object pitObj : pitStops) {
                        Map<String, Object> pitData = (Map<String, Object>) pitObj;
                        String driverId = (String) pitData.get('driverId');

                        PitStop__c pitRecord = new PitStop__c();
                        pitRecord.PitStopId__c = raceKey + '-' + driverId + '-' + pitData.get('stop'); // External ID
                        pitRecord.Name = 'PitStop - ' + driverId;

                        pitRecord.Lap__c = Integer.valueOf((String) pitData.get('lap'));
                        pitRecord.Stop__c = Integer.valueOf((String) pitData.get('stop'));
                        pitRecord.Time__c = (String) pitData.get('time');
                        pitRecord.Duration__c = (String) pitData.get('duration');

                        if (raceMap.containsKey(raceKey)) pitRecord.Race__c = raceMap.get(raceKey);
                        if (driverMap.containsKey(driverId)) pitRecord.Driver__c = driverMap.get(driverId);

                        allPitStops.add(pitRecord);
                    }
                }

                offset += pageLimit; // Avanzar a la siguiente página
            }

            upsert allPitStops PitStopId__c;
            System.debug('PitStops procesados: ' + allPitStops.size());
        } catch (Exception e) {
            System.debug('Error en loadPitStops: ' + e.getMessage());
        }
    }
}