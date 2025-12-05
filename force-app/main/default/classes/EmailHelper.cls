public class EmailHelper {
    public static void sendFantasyTeamNotification(Id teamId) {
        FantasyTeam__c ft = [SELECT Name, Owner.Name FROM FantasyTeam__c WHERE Id = :teamId LIMIT 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'alancastillosanchez4@gmail.com'});
        mail.setSubject('Nuevo Equipo Fantasy Creado');
        mail.setPlainTextBody('Se ha creado el equipo: ' + ft.Name + ' por el usuario: ' + ft.Owner.Name);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }
}