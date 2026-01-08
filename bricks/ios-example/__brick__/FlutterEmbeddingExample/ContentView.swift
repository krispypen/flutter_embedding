//
//  ContentView.swift
//  {{flutterEmbeddingName}}Example
//
//  Created by Kris Pypen on 29/09/2025.
//

import UIKit
import flutter_embedding
import {{moduleName}}

class ContentView: UIViewController {
    
    private let communicationView = CommunicationView()
    
    // UI Elements
    private let mainContainer = UIView()
    private let tabSegmentedControl = UISegmentedControl(items: ["Settings", "Flutter"])
    private let settingsScrollView = UIScrollView()
    private let settingsStackView = UIStackView()
    private let titleLabel = UILabel()
    private let startEngineButton = UIButton(type: .system)
    private let stopEngineButton = UIButton(type: .system)
    private let startScreenButton = UIButton(type: .system)
    private let startViewButton = UIButton(type: .system)
    internal let removeViewButton = UIButton(type: .system) // internal so handover responder can check it
    private let flutterContainer = UIView()
    private let flutterPlaceholderLabel = UILabel()
    
    // Layout constraints for responsive layout
    private var sideBySideConstraints: [NSLayoutConstraint] = []
    private var tabbedConstraints: [NSLayoutConstraint] = []
    private var settingsWidthConstraint: NSLayoutConstraint?
    
    // Track current layout mode
    private var isLargeScreen: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        communicationView.contentViewController = self
        setupUI()
        setupButtons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayoutForScreenSize()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.updateLayoutForScreenSize(width: size.width)
        })
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup Tab Segmented Control
        tabSegmentedControl.selectedSegmentIndex = 0
        tabSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        tabSegmentedControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        view.addSubview(tabSegmentedControl)
        
        // Setup Main Container
        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainer)
        
        // Setup Settings ScrollView
        settingsScrollView.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(settingsScrollView)
        
        // Setup Settings StackView
        settingsStackView.axis = .vertical
        settingsStackView.spacing = 16
        settingsStackView.alignment = .fill
        settingsStackView.distribution = .fill
        settingsStackView.translatesAutoresizingMaskIntoConstraints = false
        settingsScrollView.addSubview(settingsStackView)
        
        // Title
        titleLabel.text = "{{flutterEmbeddingName}} Demo"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        
        // Setup Buttons
        setupButton(startEngineButton, title: "startEngine")
        setupButton(stopEngineButton, title: "stopEngine")
        setupButton(startScreenButton, title: "startScreen")
        setupButton(startViewButton, title: "startFlutterInView")
        setupButton(removeViewButton, title: "removeFlutterView")
        
        // Flutter Container
        flutterContainer.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0) // #f0f0f0
        flutterContainer.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(flutterContainer)
        
        // Flutter Placeholder Label
        flutterPlaceholderLabel.text = "Flutter container area"
        flutterPlaceholderLabel.font = UIFont.systemFont(ofSize: 18)
        flutterPlaceholderLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) // #666666
        flutterPlaceholderLabel.textAlignment = .center
        flutterPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        flutterContainer.addSubview(flutterPlaceholderLabel)
        
        // Add CommunicationView as child
        addChild(communicationView)
        communicationView.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to stack view
        settingsStackView.addArrangedSubview(titleLabel)
        settingsStackView.addArrangedSubview(startEngineButton)
        settingsStackView.addArrangedSubview(stopEngineButton)
        settingsStackView.addArrangedSubview(startScreenButton)
        settingsStackView.addArrangedSubview(startViewButton)
        settingsStackView.addArrangedSubview(removeViewButton)
        settingsStackView.addArrangedSubview(communicationView.view)
        
        communicationView.didMove(toParent: self)
        
        // Base constraints (always active)
        NSLayoutConstraint.activate([
            // Tab segmented control at top
            tabSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            tabSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tabSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Main container below tabs (when visible) or safe area (when tabs hidden)
            mainContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Settings stack view inside scroll view
            settingsStackView.topAnchor.constraint(equalTo: settingsScrollView.topAnchor, constant: 16),
            settingsStackView.leadingAnchor.constraint(equalTo: settingsScrollView.leadingAnchor, constant: 16),
            settingsStackView.trailingAnchor.constraint(equalTo: settingsScrollView.trailingAnchor, constant: -16),
            settingsStackView.bottomAnchor.constraint(equalTo: settingsScrollView.bottomAnchor, constant: -16),
            settingsStackView.widthAnchor.constraint(equalTo: settingsScrollView.widthAnchor, constant: -32),
            
            // Flutter placeholder label centered in container
            flutterPlaceholderLabel.centerXAnchor.constraint(equalTo: flutterContainer.centerXAnchor),
            flutterPlaceholderLabel.centerYAnchor.constraint(equalTo: flutterContainer.centerYAnchor)
        ])
        
        // Side-by-side constraints (for large screens >= 600)
        settingsWidthConstraint = settingsScrollView.widthAnchor.constraint(equalToConstant: 400)
        sideBySideConstraints = [
            mainContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            settingsScrollView.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            settingsScrollView.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            settingsScrollView.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
            settingsWidthConstraint!,
            
            flutterContainer.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            flutterContainer.leadingAnchor.constraint(equalTo: settingsScrollView.trailingAnchor),
            flutterContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            flutterContainer.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor)
        ]
        
        // Tabbed constraints (for small screens < 600)
        tabbedConstraints = [
            mainContainer.topAnchor.constraint(equalTo: tabSegmentedControl.bottomAnchor, constant: 8),
            
            settingsScrollView.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            settingsScrollView.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            settingsScrollView.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            settingsScrollView.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
            
            flutterContainer.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            flutterContainer.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            flutterContainer.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            flutterContainer.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor)
        ]
        
        // Initially hide stop engine and remove view buttons
        stopEngineButton.isHidden = true
        removeViewButton.isHidden = true
        // Initially hide start screen and start view buttons (engine not running yet)
        startScreenButton.isHidden = true
        startViewButton.isHidden = true
    }
    
    private func updateLayoutForScreenSize(width: CGFloat? = nil) {
        let screenWidth = width ?? view.bounds.width
        let newIsLargeScreen = screenWidth >= 600
        
        // Only update if layout mode changed
        guard newIsLargeScreen != isLargeScreen || !sideBySideConstraints[0].isActive && !tabbedConstraints[0].isActive else { return }
        
        isLargeScreen = newIsLargeScreen
        
        // Deactivate all layout-specific constraints
        NSLayoutConstraint.deactivate(sideBySideConstraints)
        NSLayoutConstraint.deactivate(tabbedConstraints)
        
        if isLargeScreen {
            // Large screen (>= 600): side-by-side, hide tabs
            tabSegmentedControl.isHidden = true
            settingsScrollView.isHidden = false
            flutterContainer.isHidden = false
            
            NSLayoutConstraint.activate(sideBySideConstraints)
        } else {
            // Small screen (< 600): show tabs, toggle between views
            tabSegmentedControl.isHidden = false
            
            // Show view based on selected tab
            let selectedTab = tabSegmentedControl.selectedSegmentIndex
            settingsScrollView.isHidden = selectedTab != 0
            flutterContainer.isHidden = selectedTab != 1
            
            NSLayoutConstraint.activate(tabbedConstraints)
        }
    }
    
    @objc private func tabChanged() {
        guard !isLargeScreen else { return }
        
        let selectedTab = tabSegmentedControl.selectedSegmentIndex
        settingsScrollView.isHidden = selectedTab != 0
        flutterContainer.isHidden = selectedTab != 1
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
        startEngineButton.addTarget(self, action: #selector(handleStartEngine), for: .touchUpInside)
        stopEngineButton.addTarget(self, action: #selector(stopEngine), for: .touchUpInside)
        startScreenButton.addTarget(self, action: #selector(startScreen), for: .touchUpInside)
        startViewButton.addTarget(self, action: #selector(startFlutterInView), for: .touchUpInside)
        removeViewButton.addTarget(self, action: #selector(removeFlutterView), for: .touchUpInside)
    }
    
    @objc private func handleStartEngine() {
        communicationView.startEngine { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Hide "Start Flutter Engine" button and show "Stop Flutter Engine" button
                    self?.startEngineButton.isHidden = true
                    self?.stopEngineButton.isHidden = false
                    // Show start screen and start view buttons (engine is now running)
                    self?.startScreenButton.isHidden = false
                    self?.startViewButton.isHidden = false
                    // Show update theme button in communication view
                    self?.communicationView.setEngineRunning(true)
                    
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
            let vc = try {{flutterEmbeddingName}}.shared.getViewController()
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        } catch {
            print("Error when starting screen: \(error)")
            showToast("Error starting Flutter screen: \(error.localizedDescription)")
        }
    }
    
    @objc private func startFlutterInView() {
        do {
            let flutterViewController = try {{flutterEmbeddingName}}.shared.getViewController()
            
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
            
            // Hide placeholder label
            flutterPlaceholderLabel.isHidden = true
            
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
        
        // Show placeholder label
        flutterPlaceholderLabel.isHidden = false
        
        // Show "Open Flutter in View" button and hide "Remove Flutter View" button
        startViewButton.isHidden = false
        removeViewButton.isHidden = true
        
        showToast("Flutter view removed")
        print("Flutter fragment removed from view")
    }
    
    @objc private func stopEngine() {
        {{flutterEmbeddingName}}.shared.stopEngine()
        
        // Show "Start Flutter Engine" button and hide "Stop Flutter Engine" button
        startEngineButton.isHidden = false
        stopEngineButton.isHidden = true
        // Hide start screen and start view buttons (engine is not running)
        startScreenButton.isHidden = true
        startViewButton.isHidden = true
        // Hide update theme button in communication view
        communicationView.setEngineRunning(false)
        
        showToast("Flutter engine stopped")
    }
    
    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func handleFlutterExit() {
        // Check if Flutter is embedded in the view (removeViewButton is visible)
        if !removeViewButton.isHidden {
            // Flutter is embedded, remove it from the container
            removeFlutterView()
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
