package be.krispypen.plugins.flutter_embedding;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.Map;


/**
 * IMPORTANT: keep this in sync:
 * - with the iOS version: packages/flutter_embedding/ios/Classes/Models/HandoverResponderProtocol.swift
 * - with the React-native version: packages/app_in_app/react_native_module/src/interfaces/HandoverResponderInterface.ts
 **/
public interface HandoverResponderInterface {

    /**
     * This will be used when the exit button is clicked in the app-in-app. The super app is then
     * responsible to navigate away from the app-in-app.
     * <p>
     * This will be triggered by the back button on the home screen.
     */
    void exit();

    /**
     * This will be used to invoke a handover event to the native app.
     *
     * @param name
     * @param data
     * @param completion
     */
    void invokeHandover(@NonNull String name, @NonNull Map<String, Object> data, @Nullable CompletionHandler<Object> completion);

    
}
