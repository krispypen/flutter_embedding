//
//  CommunicationView.swift
//  {{flutterEmbeddingName}}Example
//
//  Created by Kris Pypen on 29/09/2025.
//

import UIKit
import flutter_embedding
import {{moduleName}}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
class ExampleHandoversToHostService: HandoversToHostService.SimpleServiceProtocol {
    
    
    var accessToken: String = ""
    weak var contentViewController: ContentView?
    
    func getHostInfo(
        request: GetHostInfoRequest,
        context: FlutterEmbeddingGRPCCore.ServerContext
    ) async throws -> GetHostInfoResponse {
        var response = GetHostInfoResponse()
        response.framework = "iOS"
        return response
    }
    
    func getAccessToken(
        request: GetAccessTokenRequest,
        context: FlutterEmbeddingGRPCCore.ServerContext
    ) async throws -> GetAccessTokenResponse {
        var response = GetAccessTokenResponse()
        response.accessToken = accessToken
        return response
    }
    
    func exit(
        request: ExitRequest,
        context: FlutterEmbeddingGRPCCore.ServerContext
    ) async throws -> ExitResponse {
        print("Flutter app requested exit: \(request.reason)")
        await MainActor.run {
            contentViewController?.handleFlutterExit()
        }
        
        var response = ExitResponse()
        response.success = true
        return response
    }
}

class CommunicationView: UIViewController {
    
    private var currentThemeMode = "system"
    private var currentLanguage = "en"
    private var currentEnvironment = "MOCK"
    
    let handoversToHostService: ExampleHandoversToHostService? = {
        if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
            return ExampleHandoversToHostService()
        }
        return nil
    }()
    
    // UI Elements
    private let stackView = UIStackView()
    private let environmentLabel = UILabel()
    private let environmentMenu = UIButton(type: .system)
    private let themeModeLabel = UILabel()
    private let themeModeMenu = UIButton(type: .system)
    private let updateThemeButton = UIButton(type: .system)
    private let languageLabel = UILabel()
    private let languageMenu = UIButton(type: .system)
    private let updateLanguageButton = UIButton(type: .system)
    
    private let environments = ["MOCK", "TST"]
    private let themeModes = ["light", "dark", "system"]
    private let languages = ["en", "fr", "nl"]
    
    weak var contentViewController: ContentView? {
        didSet {
            if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
                handoversToHostService?.contentViewController = contentViewController
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        setupStackView()
        setupControls()
        setupConstraints()
        updateThemeButton.isHidden = true
        updateLanguageButton.isHidden = true
    }
    
    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
    }
    
    private func setupControls() {
        setupLabelAndMenu(label: environmentLabel, labelText: "Select Environment:", 
                         menu: environmentMenu, options: environments, 
                         currentValue: currentEnvironment,
                         onChange: { [weak self] value in self?.currentEnvironment = value })
        
        setupLabelAndMenu(label: themeModeLabel, labelText: "Select Theme Mode:", 
                         menu: themeModeMenu, options: themeModes, 
                         currentValue: currentThemeMode,
                         onChange: { [weak self] value in self?.currentThemeMode = value })
        setupButton(updateThemeButton, title: "changeThemeMode")
        updateThemeButton.addTarget(self, action: #selector(updateThemeMode), for: .touchUpInside)
        
        setupLabelAndMenu(label: languageLabel, labelText: "Select Language:", 
                         menu: languageMenu, options: languages, 
                         currentValue: currentLanguage,
                         onChange: { [weak self] value in self?.currentLanguage = value })
        setupButton(updateLanguageButton, title: "changeLanguage")
        updateLanguageButton.addTarget(self, action: #selector(updateLanguage), for: .touchUpInside)
        
        [environmentLabel, environmentMenu, themeModeLabel, themeModeMenu, updateThemeButton,
         languageLabel, languageMenu, updateLanguageButton].forEach { stackView.addArrangedSubview($0) }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    private func setupLabelAndMenu(label: UILabel, labelText: String, menu: UIButton, 
                                   options: [String], currentValue: String,
                                   onChange: @escaping (String) -> Void) {
        label.text = labelText
        label.font = UIFont.systemFont(ofSize: 16)
        
        menu.showsMenuAsPrimaryAction = true
        menu.changesSelectionAsPrimaryAction = true
        menu.backgroundColor = .systemGray6
        menu.layer.cornerRadius = 8
        menu.contentHorizontalAlignment = .center
        menu.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        updateMenu(menu, options: options, currentValue: currentValue, onChange: onChange, labelText: labelText)
    }
    
    private func updateMenu(_ menu: UIButton, options: [String], currentValue: String,
                           onChange: @escaping (String) -> Void, labelText: String) {
        let actions = options.map { [weak self] option in
            UIAction(title: option, state: option == currentValue ? .on : .off) { _ in
                onChange(option)
                self?.updateMenu(menu, options: options, currentValue: option, onChange: onChange, labelText: labelText)
                print("\(labelText) changed to: \(option)")
            }
        }
        menu.menu = UIMenu(title: "", children: actions)
        menu.setTitle(currentValue, for: .normal)
        menu.setTitleColor(.label, for: .normal)
    }
    
    // Helper methods to convert string to enums
    private func themeModeFromString(_ mode: String) -> ThemeMode {
        switch mode {
        case "light": return .light
        case "dark": return .dark
        default: return .system
        }
    }
    
    private func languageFromString(_ lang: String) -> Language {
        switch lang {
        case "fr": return .fr
        case "nl": return .nl
        default: return .en
        }
    }
    
    func createStartParams() -> StartParams {
        var startParams = StartParams()
        startParams.environment = currentEnvironment
        startParams.language = languageFromString(currentLanguage)
        startParams.themeMode = themeModeFromString(currentThemeMode)
        return startParams
    }
    
    @objc private func updateThemeMode() {
        var request = ChangeThemeModeRequest()
        request.themeMode = themeModeFromString(currentThemeMode)
        sendRequest(request, 
                   serviceName: "changeThemeMode",
                   serviceCall: { try await {{flutterEmbeddingName}}.shared.handoversToFlutterService().changeThemeMode(request: $0) },
                   successMessage: "Theme mode updated successfully")
    }
    
    @objc private func updateLanguage() {
        var request = ChangeLanguageRequest()
        request.language = languageFromString(currentLanguage)
        sendRequest(request,
                   serviceName: "changeLanguage",
                   serviceCall: { try await {{flutterEmbeddingName}}.shared.handoversToFlutterService().changeLanguage(request: $0) },
                   successMessage: "Language updated successfully")
    }
    
    private func sendRequest<T>(_ message: T, serviceName: String, 
                                serviceCall: @escaping (FlutterEmbeddingGRPCCore.ClientRequest<T>) async throws -> Void,
                                successMessage: String) {
        let clientRequest = FlutterEmbeddingGRPCCore.ClientRequest<T>(message: message)
        print("Client request (\(serviceName)): \(clientRequest)")
        Task {
            do {
                try await serviceCall(clientRequest)
                await MainActor.run { showToast(successMessage) }
            } catch {
                await MainActor.run { showToast("Error updating \(serviceName): \(error.localizedDescription)") }
            }
        }
    }
    
    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func setEngineRunning(_ isRunning: Bool) {
        updateThemeButton.isHidden = !isRunning
        updateLanguageButton.isHidden = !isRunning
    }
    
    func startEngine(completion: @escaping (Bool, Error?) -> Void) {
        if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
            guard let handoversToHostService = handoversToHostService else {
                let error = NSError(domain: "FlutterEmbedding", code: -1, userInfo: [NSLocalizedDescriptionKey: "iOS 18.0 or later is required"])
                completion(false, error)
                return
            }
            let startParams = createStartParams()
            {{flutterEmbeddingName}}.shared.startEngine(
                startParams: startParams,
                handoversToHostService: handoversToHostService
            ) { success, error in
                if success != nil {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        } else {
            let error = NSError(domain: "FlutterEmbedding", code: -1, userInfo: [NSLocalizedDescriptionKey: "iOS 18.0 or later is required"])
            completion(false, error)
        }
    }
}

