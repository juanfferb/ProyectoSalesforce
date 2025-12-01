trigger FantasyTeamTrigger on FantasyTeam__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        for (FantasyTeam__c ft : Trigger.new) {
            EmailHelper.sendFantasyTeamNotification(ft.Id);
        }
    }
}