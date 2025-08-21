//
//  BookMemoirApp.swift
//  BookMemoir
//
//  Created by Jasmine Ng. on 8/5/25.
//

import SwiftUI
import SwiftData

@main
struct BookMemoirApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Book.self, isUndoEnabled: true)
    }
}


// Book Model
@Model
class Book {
    var id: UUID
    var title: String
    var author: String
    var coverURL: String?
    var status: ReadingStatus
    var startDate: Date?
    var notes: String?
    var summary: String?
    var finishDate: Date?

    init(title: String, author: String, coverURL: String? = nil, status: ReadingStatus = .toRead) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.status = status
    }
    
    var readingDuration: Int? {
            guard let start = startDate, let finish = finishDate else {
                return nil
            }
            let days = Calendar.current.dateComponents([.day], from: start, to: finish).day
            return days
        }
}

enum ReadingStatus: String, CaseIterable, Identifiable, Codable {
    case toRead = "To-Read"
    case reading = "Reading"
    case finished = "Finished"

    var id: String { rawValue }
}



// Library View
struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query var books: [Book]
    @State private var selectedStatus: ReadingStatus = .toRead
    @Binding var selectedTab: Tab

    var filteredBooks: [Book] {
        books.filter { $0.status == selectedStatus }
    }

    var body: some View {
        NavigationView {
            VStack() {
                // Sticky Picker at top
                Picker("Status", selection: $selectedStatus) {
                    ForEach(ReadingStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color(.systemBackground)) // ensures solid bg under picker
                .zIndex(1) // keep above scrolling content

                // Content Area
                Group {
                    if selectedStatus == .toRead {
                        toReadPageView
                    } else if selectedStatus == .reading {
                        readingListView
                    } else {
                        finishedListView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // occupy remaining space
            }
            .navigationTitle("BookMemoir")
        }
    }
    
    

    // MARK: - To-Read View
    @ViewBuilder
    var toReadPageView: some View {
  
            if filteredBooks.isEmpty {
                Text("No books in To-Read list!")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                TabView {
                    ForEach(filteredBooks) { book in
                        VStack {
                            if let cover = book.coverURL,
                               let url = fixedURL(from: cover) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .overlay(Text("No Cover"))
                            }

                            Text(book.title)
                                .font(.title2)
                                .padding(.top, 8)

                            Text(book.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button(action: {
                                book.status = .reading
                                book.startDate = Date()
                                try? context.save()
                            }) {
                                Text("Start Reading")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: 0x02B2D7))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.bottom, 40)
                        }
                        .padding()
                        .background(Color(hex: 0xcacfd7, opacity: 0.3))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 400)
            }
    }

    // MARK: - Reading View
    var readingListView: some View {
        List {
            ForEach(filteredBooks) { book in
                NavigationLink(destination: ReadingDetailView(book: book)) {
                    VStack(alignment: .leading) {
                        Text(book.title).font(.headline)
                        if let date = book.startDate {
                            Text("Started: \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(Color(hex: 0x0279a8))
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(hex: 0x3d3d9de, opacity: 0.3))
    }

    // MARK: - Finished View
    var finishedListView: some View {
        List {
            ForEach(filteredBooks) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    VStack(alignment: .leading) {
                        Text(book.title)
                            .font(.headline)

                        if let days = book.readingDuration {
                            Text("Finished in \(days) days")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(hex: 0x3d3d9de, opacity: 0.3))
    }
}

// MARK: - Reading Detail View
struct ReadingDetailView: View {
    @Bindable var book: Book
    @Environment(\.modelContext) private var context

    var body: some View {
        SwiftUI.Form {
            Section(header: Text("Notes")) {
                TextEditor(text: Binding(
                    get: { book.notes ?? "" },
                    set: { book.notes = $0 }
                ))
                .frame(height: 100)
            }

            Section(header: Text("Summary")) {
                TextEditor(text: Binding(
                    get: { book.summary ?? "" },
                    set: { book.summary = $0 }
                ))
                .frame(height: 150)
            }

            Button("Mark as Finished") {
                book.status = .finished
                book.finishDate = Date()
                try? context.save()
            }
            .foregroundColor(.green)
        }
        .navigationTitle(book.title)
    }
}

func fixedURL(from coverURL: String) -> URL? {
    guard var urlString = coverURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        return nil
    }
    if urlString.hasPrefix("http://") {
        urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
    }
    return URL(string: urlString)
}


// Add Book View
struct AddBookView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @Binding var selectedTab: Tab
    @Binding var selectedStatus: ReadingStatus
    
    enum InputMode: String, CaseIterable, Identifiable {
        case isbn = "Search by ISBN"
        case manual = "Manual Entry"
        var id: String { rawValue }
    }
    
    @State private var inputMode: InputMode = .isbn
    
    @State private var isbn: String = ""
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var author: String = ""
    @State private var publishedDate: String = ""
    @State private var pageCount: Int?
    @State private var coverURL: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
            NavigationView {
                Form {
                    // Mode Picker
                    Section {
                        Picker("Input Mode", selection: $inputMode) {
                            ForEach(InputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                    }
                    
                    // ISBN Search Mode
                    
                    if inputMode == .isbn {
                        Section(header: Text("Search by ISBN")) {
                            TextField("Enter ISBN", text: $isbn)
                                .keyboardType(.numberPad)
                            
                            Button("Fetch Book Info") {
                                fetchBookInfo()
                            }
                            .disabled(isbn.isEmpty)
                        }
                        
                        if isLoading {
                            ProgressView("Loading...")
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Manual Input Mode
                    if inputMode == .manual || !title.isEmpty {
                        Section(header: Text("Book Details")) {
                            TextField("Title", text: $title)
                            TextField("Subtitle", text: $subtitle)
                            TextField("Author", text: $author)
                            TextField("Published Date", text: $publishedDate)
                            TextField("Page Count", value: $pageCount, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                            TextField("Cover URL", text: $coverURL)
                            
                            if let url = fixedURL(from: coverURL), !coverURL.isEmpty {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Add Book")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newBook = Book(
                                title: title,
                                author: author,
                                coverURL: coverURL,
                                status: .toRead
                            )
                            context.insert(newBook)
                            try? context.save()
                            
                            resetFields()
                            
                            selectedStatus = .toRead
                            selectedTab = .library
                        }
                        .disabled(title.isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    
    private func resetFields() {
        isbn = ""
        title = ""
        subtitle = ""
        author = ""
        publishedDate = ""
        pageCount = nil
        coverURL = ""
    }
    
    private func fetchBookInfo() {
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)") else { return }
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   let volumeInfo = items.first?["volumeInfo"] as? [String: Any] {
                    
                    DispatchQueue.main.async {
                        self.title = volumeInfo["title"] as? String ?? ""
                        self.subtitle = volumeInfo["subtitle"] as? String ?? ""
                        self.author = (volumeInfo["authors"] as? [String])?.joined(separator: ", ") ?? ""
                        self.publishedDate = volumeInfo["publishedDate"] as? String ?? ""
                        self.pageCount = volumeInfo["pageCount"] as? Int
                        
                        if let imageLinks = volumeInfo["imageLinks"] as? [String: Any],
                           let thumbnail = imageLinks["thumbnail"] as? String {
                            self.coverURL = thumbnail
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        errorMessage = "No book found for this ISBN."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to parse response."
                }
            }
        }.resume()
    }
}

// Book Detail View
struct BookDetailView: View {
    let book: Book

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let coverURL = book.coverURL,
                   let url = fixedURL(from: coverURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .cornerRadius(12)
                    } placeholder: {
                        ProgressView()
                    }
                }

                Text(book.title)
                    .font(.title)
                    .bold()

                Text("By \(book.author)")
                    .font(.headline)
                    .foregroundColor(.secondary)

                if let summary = book.summary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                        Text(summary)
                            .font(.body)
                    }
                }

                if let notes = book.notes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                    }
                }

                if let days = book.readingDuration {
                    Text("You finished this book in \(days) days.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Book Details")
    }
}

// Edit Text View
struct EditTextView: View {
    var title: String
    @Binding var text: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $text)
                    .padding()
                    .border(Color.gray, width: 1)

                Button("Save") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle(title)
        }
    }
}

extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}
