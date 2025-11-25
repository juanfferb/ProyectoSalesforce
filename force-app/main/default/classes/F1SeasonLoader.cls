public with sharing class F1SeasonLoader {
    public static void loadSeasons() {
        try {
            Integer offset = 0;
            Integer pageLimit = 30; // Cambiado para evitar conflicto con palabra reservada
            Boolean moreData = true;

            List<Season__c> seasonsToUpsert = new List<Season__c>();

            while (moreData) {
                String endpoint = 'f1/seasons.json?limit=' + pageLimit + '&offset=' + offset;
                String jsonResponse = ErgastAPI.getF1Data(endpoint);

                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                if (!root.containsKey('MRData')) break;

                Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
                Object seasonTableObj = mrData.get('SeasonTable');
                if (!(seasonTableObj instanceof Map<String, Object>)) break;

                Map<String, Object> seasonTable = (Map<String, Object>) seasonTableObj;
                List<Object> seasons = (List<Object>) seasonTable.get('Seasons');

                if (seasons == null || seasons.isEmpty()) {
                    moreData = false;
                    break;
                }

                for (Object obj : seasons) {
                    Map<String, Object> seasonData = (Map<String, Object>) obj;

                    Season__c seasonRecord = new Season__c();
                    seasonRecord.Name = (String) seasonData.get('season');
                    seasonRecord.Season__c = Integer.valueOf((String) seasonData.get('season'));
                    seasonRecord.URL__c = (String) seasonData.get('url');

                    seasonsToUpsert.add(seasonRecord);
                }

                offset += pageLimit; // Avanzar a la siguiente página
            }

            upsert seasonsToUpsert Season__c;
            System.debug('Temporadas procesadas: ' + seasonsToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadSeasons: ' + e.getMessage());
        }
    }
}