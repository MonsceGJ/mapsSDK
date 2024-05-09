//
//  AppDelegate.swift
//  mapsSdk
//
//  Created by monscerrat gutierrez on 06/05/24.
//


import Foundation

import UIKit
import GoogleMaps // Asegúrate de importar GoogleMaps

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configura tu API key de Google Maps aquí
        GMSServices.provideAPIKey("AIzaSyBig07xCuJIddITbNbY0Lv5fIqVLEN0EX0")
        return true
    }
}
