public with sharing class F1ResultLoader {
    public static void loadResults() {
        try {
            Integer offset = 0;
            Integer pageLimit = 30;
            Boolean moreData = true;

            Map<String, Id> raceMap = new Map<String, Id>();
            for (Race__c r : [SELECT Id, RaceId__c FROM Race__c]) raceMap.put(r.RaceId__c, r.Id);

            Map<String, Id> driverMap = new Map<String, Id>();
            for (Driver__c d : [SELECT Id, DriverId__c FROM Driver__c]) driverMap.put(d.DriverId__c, d.Id);

            Map<String, Id> constructorMap = new Map<String, Id>();
            for (Constructor__c c : [SELECT Id, Constructor_Code__c FROM Constructor__c]) constructorMap.put(c.Constructor_Code__c, c.Id);

            List<Result__c> resultsToUpsert = new List<Result__c>();

            while (moreData) {
                String endpoint = 'f1/2025/results.json?limit=' + pageLimit + '&offset=' + offset;
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

                    List<Object> results = (List<Object>) raceData.get('Results');
                    if (results == null || results.isEmpty()) continue;

                    for (Object resultObj : results) {
                        Map<String, Object> resultData = (Map<String, Object>) resultObj;
                        Map<String, Object> driverData = (Map<String, Object>) resultData.get('Driver');
                        Map<String, Object> constructorData = (Map<String, Object>) resultData.get('Constructor');

                        String driverId = (String) driverData.get('driverId');
                        String constructorId = (String) constructorData.get('constructorId');

                        Result__c resultRecord = new Result__c();
                        resultRecord.ResultId__c = raceKey + '-' + driverId; // External ID
                        resultRecord.Name = (String) raceData.get('raceName') + ' - ' + (String) driverData.get('familyName');
                        resultRecord.Position__c = Integer.valueOf((String) resultData.get('position'));
                        resultRecord.Points__c = Decimal.valueOf((String) resultData.get('points'));
                        resultRecord.Laps__c = Integer.valueOf((String) resultData.get('laps'));
                        resultRecord.Status__c = (String) resultData.get('status');

                        if (raceMap.containsKey(raceKey)) resultRecord.Race__c = raceMap.get(raceKey);
                        if (driverMap.containsKey(driverId)) resultRecord.Driver__c = driverMap.get(driverId);
                        if (constructorMap.containsKey(constructorId)) resultRecord.Constructor__c = constructorMap.get(constructorId);

                        resultsToUpsert.add(resultRecord);
                    }
                }

                System.debug('Resultados procesados en offset ' + offset + ': ' + races.size());
                offset += pageLimit;
            }

            upsert resultsToUpsert ResultId__c;
            System.debug('Total resultados: ' + resultsToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadResults: ' + e.getMessage());
        }
    }
}