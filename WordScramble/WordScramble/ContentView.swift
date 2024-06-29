import SwiftUI
import ConfettiSwiftUI

struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    @State private var score = 0
    @State private var highScore = 0
    @State private var confettiCounter = 0
    @State private var hasExceededHighScore = false

    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Enter your word", text: $newWord)
                        .textInputAutocapitalization(.never)
                        .focused($isTextFieldFocused)
                }
                
                Section {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                    }
                }
            }
            .navigationTitle(rootWord)
            .onSubmit {
                addNewWord()
                isTextFieldFocused = true
            }
            .onAppear(perform: {
                startGame()
                loadHighScore()
            })
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: reset) {
                        Image(systemName: "arrow.counterclockwise").foregroundStyle(.black)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    VStack {
                        Text("Score: \(score)").font(.title2)
                        Text("High Score: \(highScore)").font(.subheadline)
                    }
                }
            }
            .confettiCannon(counter: $confettiCounter, num: 50, colors: [.red, .green, .blue], confettiSize: 10)
        }
    }
    
    func addNewWord() {
        // lowercase and trim the word, to make sure we don't add duplicate words with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // exit if the remaining string is empty
        guard answer.count > 0 else { return }
        
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }

        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            return
        }

        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        
        score += answer.count
        if score > highScore {
            highScore = score
            saveHighScore()
            if !hasExceededHighScore {
                confettiCounter += 1 // Start confetti animation
                hasExceededHighScore = true
            }
        }
        newWord = ""
    }
    
    func startGame() {
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                let allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "silkworm"
                return
            }
        }
        fatalError("Could not load start.txt from bundle.")
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord

        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")

        return misspelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
    
    func reset() {
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                let allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "silkworm"
                usedWords = [String]()
                score = 0
                hasExceededHighScore = false // Reset exceeded high score flag
                return
            }
        }
    }
    
    func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: "HighScore")
    }
    
    func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: "HighScore")
    }
}

#Preview {
    ContentView()
}
