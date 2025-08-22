//
//  BookMemoirApp.swift
//  BookMemoir
//
//  Created by Jasmine Ng. on 8/5/25.
//

import SwiftUI
import SwiftData
import PhotosUI

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
    var pageCount: Int?
    var coverImageData: Data?

    init(title: String, author: String, coverURL: String? = nil, pageCount: Int? = nil, status: ReadingStatus = .toRead, coverImageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.status = status
        self.pageCount = pageCount
        self.coverImageData = coverImageData
        
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
    
    init(selectedTab: Binding<Tab>) {
        self._selectedTab = selectedTab
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor(named: "AppTitle") ?? .label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "AppTitle") ?? .label]
        
        UINavigationBar.appearance().standardAppearance = appearance
    }

    var body: some View {
        NavigationView {
            VStack() {
                Picker("Status", selection: $selectedStatus) {
                    ForEach(ReadingStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color(.systemBackground))
                .zIndex(1)

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                            } else if let cover = book.coverURL,
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
                                Text("Start Reading 🤓")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color("ButtonPrimary"))
                                    .foregroundColor(Color("StartBtnText"))
                                    .cornerRadius(8)
                            }
                            .padding(.bottom, 40)
                        }
                        .padding()
                        .background(Color("CardBackground"))
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
                                .font(.subheadline)
                                .foregroundColor(Color("HighlightText"))
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
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
                                .foregroundColor(Color("Finish"))
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
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
            .foregroundColor(Color("BodyText"))

            Section(header: Text("Summary")) {
                TextEditor(text: Binding(
                    get: { book.summary ?? "" },
                    set: { book.summary = $0 }
                ))
                .frame(height: 150)
            }
            .foregroundColor(Color("BodyText"))

            Button("Mark as Finished ✅") {
                book.status = .finished
                book.finishDate = Date()
                try? context.save()
            }
            .foregroundColor(Color("Finish"))
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
    
    @State private var selectedCoverPhoto: PhotosPickerItem?
    @State private var coverUIImage: UIImage?
    
    private var pageCountTextBinding: Binding<String> {
            Binding<String>(
                get: {
                    if let count = pageCount, count > 0 {
                        return String(count)
                    }
                    return ""
                },
                set: { newValue in
                    if let newCount = Int(newValue) {
                        pageCount = newCount
                    } else if newValue.isEmpty {
                        pageCount = nil
                    }
                }
            )
        }

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
                            Button("Search Book Info") {
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
                            TextField("Page Count", text: pageCountTextBinding)
                                                        .keyboardType(.numberPad)
                            PhotosPicker(selection: $selectedCoverPhoto, matching: .images) {
                                Label("Select Cover Image", systemImage: "photo.on.rectangle.angled")
                            }
                            .buttonStyle(.borderless)
                            if let uiImage = coverUIImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(8)
                            } else if let url = fixedURL(from: coverURL), !coverURL.isEmpty {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(8)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            
                            TextField("Cover URL (Optional)", text: $coverURL)
                        }
                        
                        .onChange(of: selectedCoverPhoto) { _, newSelection in
                            Task {
                                if let newSelection = newSelection,
                                   let data = try? await newSelection.loadTransferable(type: Data.self) {
                                    if let uiImage = UIImage(data: data) {
                                        self.coverUIImage = uiImage
                                        self.coverURL = ""
                                    }
                                } else {
                                    self.coverUIImage = nil 
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Add Book")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let newBook = Book(
                                title: title,
                                author: author,
                                coverURL: coverURL,
                                pageCount: pageCount,
                                status: .toRead,
                                coverImageData: coverUIImage?.jpegData(compressionQuality: 0.8)
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
                        Button("Cancel") {
                            dismiss()
                            resetFields()
                            selectedStatus = .toRead
                            selectedTab = .library
                        }
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
        selectedCoverPhoto = nil
        coverUIImage = nil
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
                if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(12)
                    } else if let coverURL = book.coverURL,
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
                
                if let pgCount = book.pageCount {
                    Text("\(pgCount) pages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

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
