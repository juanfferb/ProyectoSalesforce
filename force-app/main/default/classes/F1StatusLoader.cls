public with sharing class F1StatusLoader {
    public static void loadStatuses() {
        try {
            Integer offset = 0;
            Integer pageLimit = 30; // Ajusta según la API
            Boolean moreData = true;

            List<Status__c> statusesToUpsert = new List<Status__c>();

            while (moreData) {
                String endpoint = 'f1/status.json?limit=' + pageLimit + '&offset=' + offset;
                String jsonResponse = ErgastAPI.getF1Data(endpoint);

                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
                if (!root.containsKey('MRData')) break;

                Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
                Object statusTableObj = mrData.get('StatusTable');
                if (!(statusTableObj instanceof Map<String, Object>)) break;

                Map<String, Object> statusTable = (Map<String, Object>) statusTableObj;
                List<Object> statusesList = (List<Object>) statusTable.get('Status');

                if (statusesList == null || statusesList.isEmpty()) {
                    moreData = false;
                    break;
                }

                for (Object obj : statusesList) {
                    Map<String, Object> statusMap = (Map<String, Object>) obj;

                    Status__c statusRecord = new Status__c();
                    statusRecord.StatusId__c = (String) statusMap.get('statusId'); // External ID
                    statusRecord.Count__c = (String) statusMap.get('count');
                    statusRecord.Status__c = (String) statusMap.get('status');

                    statusesToUpsert.add(statusRecord);
                }

                offset += pageLimit; // Avanzar a la siguiente página
            }

            upsert statusesToUpsert StatusId__c;
            System.debug('Statuses procesados: ' + statusesToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en loadStatuses: ' + e.getMessage());
        }
    }
}