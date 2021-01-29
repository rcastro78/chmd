//
//  SignInWithApple.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 2/10/20.
//  Copyright © 2020 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import SwiftUI
import AuthenticationServices


final class SignInWithApple: UIViewRepresentable {

    @available(iOS 13.0, *)
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {

        if #available(iOS 13.0, *) {
            return ASAuthorizationAppleIDButton()
        } else {
           return ASAuthorizationAppleIDButton()
        }
      
  }

    @available(iOS 13.0, *)
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
  }
}
