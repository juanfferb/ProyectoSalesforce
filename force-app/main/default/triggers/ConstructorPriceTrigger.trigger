trigger ConstructorPriceTrigger on Constructor__c (before insert) {
    for (Constructor__c c : Trigger.new) {
        if (c.Price__c == null) {
            c.Price__c = FantasyValueService.getRandomConstructorPrice();
        }
    }
}