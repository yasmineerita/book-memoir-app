//
//  ContentView.swift
//  BookMemoir
//
//  Created by Jasmine Ng. on 8/5/25.
//

import SwiftUI
import SwiftData

// Main ContentView with Tabs
enum Tab {
    case library
    case addBook
}

struct ContentView: View {
    @State private var selectedTab: Tab = .library
    @State private var selectedStatus: ReadingStatus = .toRead
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(Tab.library)

            AddBookView(selectedTab: $selectedTab, selectedStatus: $selectedStatus)
                .tabItem {
                    Label("Add Book", systemImage: "plus.square")
                }
                .tag(Tab.addBook)
        }
    }
}

// Preview for SwiftUI Canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
