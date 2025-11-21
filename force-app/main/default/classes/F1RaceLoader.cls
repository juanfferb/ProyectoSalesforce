public with sharing class F1RaceLoader {
    public static void loadRaces() {
        try {
            String endpoint = 'f1/2025/races.json'; // URL para carreras
            String jsonResponse = ErgastAPI.getF1Data(endpoint);

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            if (!root.containsKey('MRData')) return;

            Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
            Object raceTableObj = mrData.get('RaceTable');
            if (!(raceTableObj instanceof Map<String, Object>)) return;

            Map<String, Object> raceTable = (Map<String, Object>) raceTableObj;
            List<Object> races = (List<Object>) raceTable.get('Races');
            if (races == null || races.isEmpty()) return;

            // Cargar Seasons y Circuits en mapas para evitar consultas repetitivas
            Map<Integer, Id> seasonMap = new Map<Integer, Id>();
            for (Season__c s : [SELECT Id, Season__c FROM Season__c]) {
                seasonMap.put(Integer.valueOf(s.Season__c), s.Id);
            }

            Map<String, Id> circuitMap = new Map<String, Id>();
            for (Circuit__c c : [SELECT Id, CircuitId__c FROM Circuit__c]) {
                circuitMap.put(c.CircuitId__c, c.Id);
            }

            List<Race__c> racesToUpsert = new List<Race__c>();

            for (Object obj : races) {
                Map<String, Object> raceData = (Map<String, Object>) obj;

                Race__c raceRecord = new Race__c();
                raceRecord.Name = (String) raceData.get('raceName');
                raceRecord.RaceId__c = raceData.get('season') + '-' + raceData.get('round'); // External ID
                raceRecord.Round__c = Integer.valueOf((String) raceData.get('round'));
                raceRecord.Date__c = Date.valueOf((String) raceData.get('date'));
                raceRecord.Time__c = (String) raceData.get('time');
                raceRecord.URL__c = (String) raceData.get('url');

                // Relación con Season
                Integer seasonYear = Integer.valueOf((String) raceData.get('season'));
                if (seasonMap.containsKey(seasonYear)) {
                    raceRecord.Season__c = seasonMap.get(seasonYear);
                } else {
                    System.debug('No se encontró la temporada: ' + seasonYear);
                }

                // Relación con Circuit
                Map<String, Object> circuitData = (Map<String, Object>) raceData.get('Circuit');
                String circuitId = (String) circuitData.get('circuitId');
                if (circuitMap.containsKey(circuitId)) {
                    raceRecord.Circuit__c = circuitMap.get(circuitId);
                } else {
                    System.debug('No se encontró el circuito: ' + circuitId);
                }

                // Prácticas y clasificación
                if (raceData.containsKey('FirstPractice')) {
                    Map<String, Object> fp = (Map<String, Object>) raceData.get('FirstPractice');
                    raceRecord.FirstPracticeDate__c = Date.valueOf((String) fp.get('date'));
                    raceRecord.FirstPracticeTime__c = (String) fp.get('time');
                }
                if (raceData.containsKey('SecondPractice')) {
                    Map<String, Object> sp = (Map<String, Object>) raceData.get('SecondPractice');
                    raceRecord.SecondPracticeDate__c = Date.valueOf((String) sp.get('date'));
                    raceRecord.SecondPracticeTime__c = (String) sp.get('time');
                }
                if (raceData.containsKey('ThirdPractice')) {
                    Map<String, Object> tp = (Map<String, Object>) raceData.get('ThirdPractice');
                    raceRecord.ThirdPracticeDate__c = Date.valueOf((String) tp.get('date'));
                    raceRecord.ThirdPracticeTime__c = (String) tp.get('time');
                }
                if (raceData.containsKey('Qualifying')) {
                    Map<String, Object> q = (Map<String, Object>) raceData.get('Qualifying');
                    raceRecord.QualifyingDate__c = Date.valueOf((String) q.get('date'));
                    raceRecord.QualifyingTime__c = (String) q.get('time');
                }
                if (raceData.containsKey('Sprint')) {
                    Map<String, Object> sprint = (Map<String, Object>) raceData.get('Sprint');
                    raceRecord.SprintDate__c = Date.valueOf((String) sprint.get('date'));
                    raceRecord.SprintTime__c = (String) sprint.get('time');
                }
                if (raceData.containsKey('SprintQualifying')) {
                    Map<String, Object> sq = (Map<String, Object>) raceData.get('SprintQualifying');
                    raceRecord.SprintQualifyingDate__c = Date.valueOf((String) sq.get('date'));
                    raceRecord.SprintQualifyingTime__c = (String) sq.get('time');
                }

                racesToUpsert.add(raceRecord);
            }

            // Upsert usando External ID RaceId__c
            upsert racesToUpsert RaceId__c;

            System.debug('Carreras procesadas: ' + racesToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadRaces: ' + e.getMessage());
        }
    }
}