//
//  ContentView.swift
//  FlutterEmbeddingExample
//
//  Created by Kris Pypen on 29/09/2025.
//

import UIKit
import flutter_embedding

class ExampleHandoverResponder: HandoverResponderProtocol {
    var accessToken: String = ""
    weak var contentViewController: ContentView?
    
    func exit() {
        // Handle exit from Flutter app
        print("Flutter app requested exit")
        DispatchQueue.main.async { [weak self] in
            guard let contentVC = self?.contentViewController else { return }
            
            // Check if Flutter is embedded in the view (removeViewButton is visible)
            if !contentVC.removeViewButton.isHidden {
                // Flutter is embedded, remove it from the container
                contentVC.removeFlutterView()
            } else {
                // Flutter is presented modally, dismiss it
                guard
                  let windowScene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive && $0 is UIWindowScene }) as? UIWindowScene,
                  let window = windowScene.windows.first(where: \.isKeyWindow),
                  let rootViewController = window.rootViewController
                else { return }
                
                rootViewController.dismiss(animated: true)
            }
        }
    }
    
    func invokeHandover(withName name: String, data: Dictionary<String, Any?>, completion: ((_ response: Any?, _ error: FlutterEmbeddingError?) -> ())?) {
        DispatchQueue.main.async { [weak self] in
            guard let contentVC = self!.contentViewController else {
                completion?(nil, FlutterEmbeddingError.genericError(code: "disposed", message: "disposed"))
                return
            }
            
            // Create popup with handover information
            let alert = UIAlertController(
                title: "Handover: \(name)",
                message: "Data: \(data)",
                preferredStyle: .alert
            )
            
            // Add OK action
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // Return success response
                completion?("OK", nil)
            })
            
            // Add Cancel action
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                // Return cancelled response
                completion?("Cancelled", nil)
            })
            
            // Present the popup
            contentVC.present(alert, animated: true)
        }
    }
}

class ContentView: UIViewController {
    
    private var currentThemeMode = "system"
    private var currentLanguage = "en"
    private var currentEnvironment = "DEV"
    
    private let handoverResponder = ExampleHandoverResponder()
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let themeModeLabel = UILabel()
    private let themeModeSpinner = UIPickerView()
    private let startEngineButton = UIButton(type: .system)
    private let stopEngineButton = UIButton(type: .system)
    private let startScreenButton = UIButton(type: .system)
    private let startViewButton = UIButton(type: .system)
    internal let removeViewButton = UIButton(type: .system) // internal so handover responder can check it
    private let updateThemeButton = UIButton(type: .system)
    private let flutterContainer = UIView()
    
    private let themeModes = ["light", "dark", "system"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handoverResponder.contentViewController = self
        setupUI()
        setupButtons()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup StackView
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // Title
        titleLabel.text = "Flutter Embedding Demo"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        
        // Theme Mode Label
        themeModeLabel.text = "Select Theme Mode:"
        themeModeLabel.font = UIFont.systemFont(ofSize: 16)
        
        // Theme Mode Spinner
        themeModeSpinner.delegate = self
        themeModeSpinner.dataSource = self
        themeModeSpinner.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        // Setup Buttons
        setupButton(startEngineButton, title: "Start Flutter Engine")
        setupButton(stopEngineButton, title: "Stop Flutter Engine")
        setupButton(startScreenButton, title: "Open Flutter Screen")
        setupButton(startViewButton, title: "Open Flutter in View")
        setupButton(removeViewButton, title: "Remove Flutter View")
        setupButton(updateThemeButton, title: "Update Theme Mode")
        
        // Flutter Container
        flutterContainer.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0) // #f0f0f0
        flutterContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        
        // Add to stack view
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(themeModeLabel)
        stackView.addArrangedSubview(themeModeSpinner)
        stackView.addArrangedSubview(startEngineButton)
        stackView.addArrangedSubview(stopEngineButton)
        stackView.addArrangedSubview(startScreenButton)
        stackView.addArrangedSubview(startViewButton)
        stackView.addArrangedSubview(removeViewButton)
        stackView.addArrangedSubview(updateThemeButton)
        stackView.addArrangedSubview(flutterContainer)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        // Initially hide stop engine and remove view buttons
        stopEngineButton.isHidden = true
        removeViewButton.isHidden = true
        
        // Set default theme mode selection
        themeModeSpinner.selectRow(2, inComponent: 0, animated: false) // "system"
    }
    
    private func setupButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    private func setupButtons() {
        startEngineButton.addTarget(self, action: #selector(startEngine), for: .touchUpInside)
        stopEngineButton.addTarget(self, action: #selector(stopEngine), for: .touchUpInside)
        startScreenButton.addTarget(self, action: #selector(startScreen), for: .touchUpInside)
        startViewButton.addTarget(self, action: #selector(startFlutterInView), for: .touchUpInside)
        removeViewButton.addTarget(self, action: #selector(removeFlutterView), for: .touchUpInside)
        updateThemeButton.addTarget(self, action: #selector(updateThemeMode), for: .touchUpInside)
    }
    
    @objc private func startEngine() {
        FlutterEmbedding.shared.startEngine(
            forEnv: currentEnvironment,
            forLanguage: currentLanguage,
            forThemeMode: currentThemeMode,
            with: handoverResponder
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                if success != nil {
                    // Hide "Start Flutter Engine" button and show "Stop Flutter Engine" button
                    self?.startEngineButton.isHidden = true
                    self?.stopEngineButton.isHidden = false
                    
                    print("Successfully started engine")
                    self?.showToast("Flutter engine started successfully")
                                } else {
                    print("Error when starting engine: \(error?.localizedDescription ?? "Unknown error")")
                    self?.showToast(error?.localizedDescription ?? "Something went wrong")
                }
            }
        }
    }
    
    @objc private func startScreen() {
        do {
            let vc = try FlutterEmbedding.shared.getViewController()
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        } catch {
            print("Error when starting screen: \(error)")
            showToast("Error starting Flutter screen: \(error.localizedDescription)")
        }
    }
    
    @objc private func startFlutterInView() {
        do {
            let flutterViewController = try FlutterEmbedding.shared.getViewController()
            
            // Add as child view controller
            addChild(flutterViewController)
            flutterContainer.addSubview(flutterViewController.view)
            flutterViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                flutterViewController.view.topAnchor.constraint(equalTo: flutterContainer.topAnchor),
                flutterViewController.view.leadingAnchor.constraint(equalTo: flutterContainer.leadingAnchor),
                flutterViewController.view.trailingAnchor.constraint(equalTo: flutterContainer.trailingAnchor),
                flutterViewController.view.bottomAnchor.constraint(equalTo: flutterContainer.bottomAnchor)
            ])
            flutterViewController.didMove(toParent: self)
            
            // Hide "Open Flutter in View" button and show "Remove Flutter View" button
            startViewButton.isHidden = true
            removeViewButton.isHidden = false
            
            showToast("Flutter app loaded in view")
            print("Flutter fragment added to view")
        } catch {
            print("Error when starting Flutter in view: \(error)")
            showToast("Error starting Flutter in view: \(error.localizedDescription)")
        }
    }
    
    @objc internal func removeFlutterView() {
        // Remove all child view controllers from flutter container
        for child in children {
            if child.view.superview == flutterContainer {
                child.willMove(toParent: nil)
                child.view.removeFromSuperview()
                child.removeFromParent()
            }
        }
        
        // Show "Open Flutter in View" button and hide "Remove Flutter View" button
        startViewButton.isHidden = false
        removeViewButton.isHidden = true
        
        showToast("Flutter view removed")
        print("Flutter fragment removed from view")
    }
    
    @objc private func stopEngine() {
        FlutterEmbedding.shared.stopEngine()
        
        // Show "Start Flutter Engine" button and hide "Stop Flutter Engine" button
        startEngineButton.isHidden = false
        stopEngineButton.isHidden = true
        
        showToast("Flutter engine stopped")
    }
    
    @objc private func updateThemeMode() {
        FlutterEmbedding.shared.changeThemeMode(themeMode: currentThemeMode) { [weak self] success, error in
            DispatchQueue.main.async {
                if success == true {
                    print("Successfully changed theme mode")
                    self?.showToast("Theme mode updated to: \(self?.currentThemeMode ?? "")")
                } else {
                    print("Error when changing theme mode: \(error?.localizedDescription ?? "Unknown error")")
                    self?.showToast(error?.localizedDescription ?? "Something went wrong (when changing theme mode)")
                }
            }
        }
    }
    
    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
extension ContentView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return themeModes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return themeModes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentThemeMode = themeModes[row]
        print("Theme mode changed to: \(currentThemeMode)")
        }
    }

