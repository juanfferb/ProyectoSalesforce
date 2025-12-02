trigger DriverPriceTrigger on Driver__c (before insert) {
    for (Driver__c d : Trigger.new) {
        if (d.Price__c == null) {
            d.Price__c = FantasyValueService.getRandomDriverPrice();
        }
    }
}