public with sharing class F1StatusLoader {
    public static void loadStatuses() {
        // Endpoint del API
        String endpoint = 'f1/status.json';
        String jsonResponse = ErgastAPI.getF1Data(endpoint);

        // Parseo del JSON
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        if (!root.containsKey('MRData')) return;

        Map<String, Object> mrData = (Map<String, Object>) root.get('MRData');
        Object statusTableObj = mrData.get('StatusTable');
        if (!(statusTableObj instanceof Map<String, Object>)) return;

        Map<String, Object> statusTable = (Map<String, Object>) statusTableObj;
        List<Object> statusesList = (List<Object>) statusTable.get('Status');
        if (statusesList == null || statusesList.isEmpty()) return;

        // Lista para upsert
        List<Status__c> statusesToUpsert = new List<Status__c>();

        for (Object obj : statusesList) {
            Map<String, Object> statusMap = (Map<String, Object>) obj;

            Status__c statusRecord = new Status__c();
            statusRecord.StatusId__c = (String) statusMap.get('statusId'); // Este será el External ID
            statusRecord.Count__c = (String) statusMap.get('count');
            statusRecord.Status__c = (String) statusMap.get('status');

            statusesToUpsert.add(statusRecord);
        }

        // Upsert usando el External ID
        upsert statusesToUpsert StatusId__c;
    }
}