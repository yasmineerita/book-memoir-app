//
//  ContentView.swift
//  BookMemoir
//
//  Created by Jasmine Ng. on 8/5/25.
//

import SwiftUI
import SwiftData

// Main ContentView with Tabs
struct ContentView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            AddBookView()
                .tabItem {
                    Label("Add Book", systemImage: "plus.square")
                }
        }
    }
}

// Preview for SwiftUI Canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
