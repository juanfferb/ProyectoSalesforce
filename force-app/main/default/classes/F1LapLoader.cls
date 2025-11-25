
public with sharing class F1LapLoader {
    public static void loadLaps() {
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

            List<Lap__c> allLaps = new List<Lap__c>();

            while (moreData) {
                String endpoint = 'f1/2025/1/laps.json?limit=' + pageLimit + '&offset=' + offset;
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

                    List<Object> laps = (List<Object>) raceData.get('Laps');
                    if (laps == null || laps.isEmpty()) continue;

                    for (Object lapObj : laps) {
                        Map<String, Object> lapData = (Map<String, Object>) lapObj;
                        String lapNumber = (String) lapData.get('number');

                        List<Object> timings = (List<Object>) lapData.get('Timings');
                        for (Object timingObj : timings) {
                            Map<String, Object> timingData = (Map<String, Object>) timingObj;
                            String driverId = (String) timingData.get('driverId');

                            Lap__c lapRecord = new Lap__c();
                            lapRecord.LapId__c = raceKey + '-' + driverId + '-' + lapNumber; // External ID
                            lapRecord.Name = 'Lap - ' + driverId;

                            lapRecord.LapNumber__c = Integer.valueOf(lapNumber);
                            lapRecord.Position__c = Integer.valueOf((String) timingData.get('position'));
                            lapRecord.Time__c = (String) timingData.get('time');

                            if (raceMap.containsKey(raceKey)) lapRecord.Race__c = raceMap.get(raceKey);
                            if (driverMap.containsKey(driverId)) lapRecord.Driver__c = driverMap.get(driverId);

                            allLaps.add(lapRecord);
                        }
                    }
                }

                offset += pageLimit; // Avanzar a la siguiente página
            }

            upsert allLaps LapId__c;
            System.debug('Laps procesadas: ' + allLaps.size());
        } catch (Exception e) {
            System.debug('Error en loadLaps: ' + e.getMessage());
        }
    }
}