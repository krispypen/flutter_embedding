package be.krispypen.plugins.flutter_embedding;

public enum Handover {
    provideAccessToken("provideAccessToken"),
    provideAnonymousAccessToken("provideAnonymousAccessToken"),
    receiveAnalyticsEvent("receiveAnalyticsEvent"),
    receiveDebugLog("receiveDebugLog"),
    receiveError("receiveError"),
    exit("exit"),
    startFaq("startFaq"),
    startOnboarding("startOnboarding"),
    startFundPortfolio("startFundPortfolio"),
    startAddMoney("startAddMoney"),
    startAuthorization("startAuthorization"),
    startTransactionSigning("startTransactionSigning"),
    ;

    private final String eventName;

    Handover(String eventName) {
        this.eventName = eventName;
    }

    public String getEventName() {
        return eventName;
    }
}


