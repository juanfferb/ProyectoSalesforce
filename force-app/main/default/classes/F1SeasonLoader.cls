public with sharing class F1SeasonLoader {
    public static void loadSeasons() {
        try {
            String endpoint = 'f1/seasons.json'; // URL correcta para temporadas
            String jsonResponse = ErgastAPI.getF1Data(endpoint);

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            if (!root.containsKey('MRData')) return;

            Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
            Object seasonTableObj = mrData.get('SeasonTable');
            if (!(seasonTableObj instanceof Map<String, Object>)) return;

            Map<String, Object> seasonTable = (Map<String, Object>) seasonTableObj;
            List<Object> seasons = (List<Object>) seasonTable.get('Seasons');
            if (seasons == null || seasons.isEmpty()) return;

            List<Season__c> seasonsToUpsert = new List<Season__c>();

            for (Object obj : seasons) {
                Map<String, Object> seasonData = (Map<String, Object>) obj;

                Season__c seasonRecord = new Season__c();
                seasonRecord.Season__c = Integer.valueOf((String) seasonData.get('season')); // Año
                seasonRecord.URL__c = (String) seasonData.get('url');

                seasonsToUpsert.add(seasonRecord);
            }

            // Usamos upsert con Season__c como identificador único
            upsert seasonsToUpsert Season__c;

            System.debug('Temporadas procesadas: ' + seasonsToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadSeasons: ' + e.getMessage());
        }
    }
}