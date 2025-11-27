public with sharing class F1RaceResultLoader {
    @AuraEnabled
    public static String loadRaceResults(String raceId) {
        try {
            // Validar formato del RaceId
            if (String.isBlank(raceId)) return 'RaceId no proporcionado.';
            List<String> parts = raceId.split('-');
            if (parts.size() != 2) return 'Formato inválido de RaceId (esperado: season-round).';

            String season = parts[0];
            String round = parts[1];

            // Mapas para relaciones
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

            // Llamada a la API
            String endpoint = 'f1/' + season + '/' + round + '/results.json';
            String jsonResponse = ErgastAPI.getF1Data(endpoint);
            if (String.isBlank(jsonResponse)) return 'Respuesta vacía de la API.';

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            if (root == null || !root.containsKey('MRData')) return 'Respuesta inválida de la API.';

            Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
            if (mrData == null || !mrData.containsKey('RaceTable')) return 'No se encontró RaceTable en la respuesta.';

            Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
            if (raceTable == null || !raceTable.containsKey('Races')) return 'No se encontraron carreras en la respuesta.';

            List<Object> races = (List<Object>) raceTable.get('Races');
            if (races == null || races.isEmpty()) return 'No se encontraron resultados para esta carrera.';

            List<Result__c> resultsToUpsert = new List<Result__c>();

            for (Object raceObj : races) {
                Map<String, Object> raceData = (Map<String, Object>) raceObj;
                List<Object> results = (List<Object>) raceData.get('Results');
                if (results == null || results.isEmpty()) continue;

                for (Object resultObj : results) {
                    Map<String, Object> resultData = (Map<String, Object>) resultObj;
                    if (resultData == null) continue;

                    Map<String, Object> driverData = (Map<String, Object>) resultData.get('Driver');
                    Map<String, Object> constructorData = (Map<String, Object>) resultData.get('Constructor');

                    String driverId = driverData != null ? (String) driverData.get('driverId') : null;
                    String constructorId = constructorData != null ? (String) constructorData.get('constructorId') : null;

                    Result__c resultRecord = new Result__c();
                    resultRecord.ResultId__c = raceId + '-' + (driverId != null ? driverId : 'unknown');
                    resultRecord.Name = (String) raceData.get('raceName') + ' - ' + (driverData != null ? (String) driverData.get('familyName') : '');

                    String positionStr = (String) resultData.get('position');
                    String pointsStr = (String) resultData.get('points');
                    String lapsStr = (String) resultData.get('laps');

                    if (positionStr != null) resultRecord.Position__c = Integer.valueOf(positionStr);
                    if (pointsStr != null) resultRecord.Points__c = Decimal.valueOf(pointsStr);
                    if (lapsStr != null) resultRecord.Laps__c = Integer.valueOf(lapsStr);

                    resultRecord.Status__c = (String) resultData.get('status');

                    if (raceMap.containsKey(raceId)) resultRecord.Race__c = raceMap.get(raceId);
                    if (driverMap.containsKey(driverId)) resultRecord.Driver__c = driverMap.get(driverId);
                    if (constructorMap.containsKey(constructorId)) resultRecord.Constructor__c = constructorMap.get(constructorId);

                    resultsToUpsert.add(resultRecord);
                }
            }

            if (resultsToUpsert.isEmpty()) return 'No se generaron resultados para insertar.';
            upsert resultsToUpsert ResultId__c;

            return 'Resultados cargados: ' + resultsToUpsert.size();
        } catch (Exception e) {
            return 'Error inesperado: ' + e.getMessage();
        }
    }
}